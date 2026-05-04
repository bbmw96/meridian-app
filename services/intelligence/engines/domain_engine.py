from __future__ import annotations

import hashlib
import json
import math
import os
import re
import socket
from datetime import datetime, timedelta
from typing import Any, Optional

import httpx
import redis.asyncio as aioredis
import structlog

from models.ml_models import SimpleTrafficEstimator
from models.schemas import Competitor, DomainProfile, TrafficEstimate

log = structlog.get_logger()

CACHE_TTL_SECONDS = 3600

COMMON_CRAWL_INDEX_URL = "https://index.commoncrawl.org/CC-MAIN-2024-10-index"

SAMPLE_TECHNOLOGIES = [
    "nginx", "cloudflare", "react", "next.js", "shopify",
    "wordpress", "woocommerce", "gtag", "hubspot", "intercom",
]

KNOWN_COMPETITORS: dict[str, list[str]] = {
    "shopify": ["bigcommerce.com", "woocommerce.com", "squarespace.com", "wix.com", "prestashop.com"],
    "stripe": ["paypal.com", "square.com", "braintree.com", "adyen.com", "checkout.com"],
    "salesforce": ["hubspot.com", "pipedrive.com", "zoho.com", "monday.com", "dynamics.microsoft.com"],
    "slack": ["teams.microsoft.com", "discord.com", "zoom.us", "webex.com", "workplace.com"],
}


class DomainEngine:
    def __init__(self) -> None:
        self._redis: Optional[aioredis.Redis] = None
        self._traffic_estimator = SimpleTrafficEstimator()
        self._http = httpx.AsyncClient(
            timeout=10.0,
            headers={"User-Agent": "MeridianIntelligence/2.0 (+https://meridian.io/bot)"},
            follow_redirects=True,
        )

    async def initialise(self) -> None:
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        try:
            self._redis = aioredis.from_url(redis_url, decode_responses=True)
            await self._redis.ping()
            log.info("meridian.domain_engine.redis_connected", url=redis_url)
        except Exception as exc:
            log.warning("meridian.domain_engine.redis_unavailable", error=str(exc))
            self._redis = None

        self._traffic_estimator.load_or_train()
        log.info("meridian.domain_engine.initialised")

    async def scan(self, domain: str) -> DomainProfile:
        cache_key = f"meridian:domain:{domain}"

        if self._redis:
            cached = await self._redis.get(cache_key)
            if cached:
                data = json.loads(cached)
                data["cached"] = True
                return DomainProfile(**data)

        profile = await self._fetch_domain_profile(domain)

        if self._redis:
            try:
                await self._redis.setex(
                    cache_key,
                    CACHE_TTL_SECONDS,
                    profile.model_dump_json(by_alias=False),
                )
            except Exception as exc:
                log.warning("meridian.domain_engine.cache_write_failed", error=str(exc))

        return profile

    async def _fetch_domain_profile(self, domain: str) -> DomainProfile:
        title, description, technologies = await self._fetch_homepage_signals(domain)
        backlink_count = await self._estimate_backlinks(domain)
        crawl_frequency = await self._get_crawl_frequency(domain)
        domain_age_days = await self._estimate_domain_age(domain)

        traffic_estimate_val, confidence = self._traffic_estimator.predict_for_domain(
            domain,
            estimated_backlinks=backlink_count,
            crawl_frequency=crawl_frequency,
        )
        monthly_traffic = int(traffic_estimate_val)
        lower_bound = int(traffic_estimate_val * 0.7)
        upper_bound = int(traffic_estimate_val * 1.4)

        tld = _extract_tld(domain)
        geography = _infer_geography(tld)

        estimated_revenue_gbp: Optional[float] = None
        if monthly_traffic > 0:
            estimated_revenue_gbp = round(monthly_traffic * 0.012, 2)

        return DomainProfile(
            domain=domain,
            title=title,
            description=description,
            monthlyTraffic=monthly_traffic,
            estimatedRevenueGBP=estimated_revenue_gbp,
            keywords=_extract_keywords(domain, title or ""),
            geography=geography,
            backlink_count=backlink_count,
            domain_age_days=domain_age_days,
            tld=tld,
            traffic_estimate=TrafficEstimate(
                monthly_visits=monthly_traffic,
                confidence=round(confidence, 3),
                lower_bound=lower_bound,
                upper_bound=upper_bound,
            ),
            technologies=technologies,
            social_signals={},
            cached=False,
        )

    async def _fetch_homepage_signals(
        self, domain: str
    ) -> tuple[Optional[str], Optional[str], list[str]]:
        try:
            resp = await self._http.get(f"https://{domain}", timeout=8.0)
            html = resp.text[:50_000]

            title_match = re.search(r"<title[^>]*>([^<]+)</title>", html, re.IGNORECASE)
            title = title_match.group(1).strip() if title_match else None

            desc_match = re.search(
                r'<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']+)',
                html,
                re.IGNORECASE,
            )
            if not desc_match:
                desc_match = re.search(
                    r'<meta[^>]+content=["\']([^"\']+)[^>]+name=["\']description["\']',
                    html,
                    re.IGNORECASE,
                )
            description = desc_match.group(1).strip() if desc_match else None

            technologies: list[str] = []
            tech_signals = {
                "react": "react",
                "next.js": "next",
                "vue": "vue",
                "angular": "angular",
                "jquery": "jquery",
                "wordpress": "wp-content",
                "shopify": "shopify",
                "cloudflare": "cloudflare",
                "gtag": "gtag",
                "hubspot": "hubspot",
            }
            for tech, signal in tech_signals.items():
                if signal.lower() in html.lower():
                    technologies.append(tech)

            return title, description, technologies[:6]
        except Exception as exc:
            log.debug("meridian.domain_engine.homepage_fetch_failed", domain=domain, error=str(exc))
            return None, None, []

    async def _estimate_backlinks(self, domain: str) -> int:
        digest = int(hashlib.md5(domain.encode()).hexdigest()[:8], 16)
        return (digest % 50_000) + 100

    async def _get_crawl_frequency(self, domain: str) -> float:
        try:
            url = f"{COMMON_CRAWL_INDEX_URL}?url={domain}/*&output=json&limit=1"
            resp = await self._http.get(url, timeout=5.0)
            if resp.status_code == 200 and resp.text.strip():
                return 0.8
            return 0.3
        except Exception:
            return 0.5

    async def _estimate_domain_age(self, domain: str) -> int:
        digest = int(hashlib.md5(domain.encode()).hexdigest()[:6], 16)
        return (digest % 5000) + 180

    async def get_competitors(self, domain: str, limit: int = 10) -> list[Competitor]:
        domain_name = domain.split(".")[0].lower()
        base_competitors = KNOWN_COMPETITORS.get(domain_name, [])

        competitors: list[Competitor] = []

        for comp_domain in base_competitors[:limit]:
            comp_backlinks = await self._estimate_backlinks(comp_domain)
            comp_traffic, _ = self._traffic_estimator.predict_for_domain(
                comp_domain, estimated_backlinks=comp_backlinks
            )
            own_backlinks = await self._estimate_backlinks(domain)
            own_traffic, _ = self._traffic_estimator.predict_for_domain(
                domain, estimated_backlinks=own_backlinks
            )

            traffic_delta = (
                ((comp_traffic - own_traffic) / (own_traffic + 1)) * 100
                if own_traffic > 0
                else 0.0
            )

            digest = int(hashlib.md5(f"{domain}{comp_domain}".encode()).hexdigest()[:6], 16)
            similarity = round(0.4 + (digest % 500) / 1000, 3)

            competitors.append(
                Competitor(
                    domain=comp_domain,
                    similarity_score=min(0.99, similarity),
                    monthly_traffic=int(comp_traffic),
                    shared_keywords=_extract_keywords(comp_domain, ""),
                    traffic_delta_percent=round(traffic_delta, 2),
                    estimated_revenue_gbp=round(comp_traffic * 0.012, 2),
                )
            )

        while len(competitors) < min(limit, 5):
            suffix_idx = len(competitors)
            synthetic_domain = f"{domain_name}-competitor-{suffix_idx + 1}.com"
            digest = int(hashlib.md5(synthetic_domain.encode()).hexdigest()[:6], 16)
            traffic = float((digest % 200_000) + 1_000)
            competitors.append(
                Competitor(
                    domain=synthetic_domain,
                    similarity_score=round(0.3 + (digest % 400) / 1000, 3),
                    monthly_traffic=int(traffic),
                    shared_keywords=_extract_keywords(domain, ""),
                    traffic_delta_percent=round((traffic - 50_000) / 500, 2),
                    estimated_revenue_gbp=round(traffic * 0.012, 2),
                )
            )

        return competitors[:limit]

    def _normalise(self, raw: str) -> str:
        """Strip scheme, www prefix, path and trailing slash; lowercase."""
        s = raw.strip().lower()
        stripped = False
        for prefix in ("https://www.", "http://www.", "https://", "http://"):
            if s.startswith(prefix):
                s = s[len(prefix):]
                stripped = True
                break
        if not stripped and s.startswith("www."):
            s = s[4:]
        s = s.split("/")[0].split("?")[0].split("#")[0]
        return s

    def _is_valid(self, domain: str) -> bool:
        """Return True only for plausible domain names (not IPs or bare words)."""
        if not domain or "." not in domain:
            return False
        if domain == "localhost":
            return False
        parts = domain.split(".")
        try:
            socket.inet_aton(domain)
            return False  # it's an IPv4 address
        except socket.error:
            pass
        return all(p and re.match(r"^[a-z0-9\-]+$", p) for p in parts)

    async def estimate_traffic(self, domain: str) -> TrafficEstimate:
        backlinks = await self._estimate_backlinks(domain)
        crawl_freq = await self._get_crawl_frequency(domain)
        estimate, confidence = self._traffic_estimator.predict_for_domain(
            domain, estimated_backlinks=backlinks, crawl_frequency=crawl_freq
        )
        return TrafficEstimate(
            monthly_visits=int(estimate),
            confidence=round(confidence, 3),
            lower_bound=int(estimate * 0.7),
            upper_bound=int(estimate * 1.4),
        )


def _extract_tld(domain: str) -> str:
    parts = domain.split(".")
    if len(parts) >= 3 and len(parts[-2]) <= 3:
        return ".".join(parts[-2:])
    return parts[-1] if parts else ""


def _infer_geography(tld: str) -> dict[str, Any]:
    tld_country_map = {
        "uk": {"primary": "GB", "region": "Europe"},
        "co.uk": {"primary": "GB", "region": "Europe"},
        "de": {"primary": "DE", "region": "Europe"},
        "fr": {"primary": "FR", "region": "Europe"},
        "es": {"primary": "ES", "region": "Europe"},
        "it": {"primary": "IT", "region": "Europe"},
        "nl": {"primary": "NL", "region": "Europe"},
        "au": {"primary": "AU", "region": "Asia-Pacific"},
        "co.au": {"primary": "AU", "region": "Asia-Pacific"},
        "ca": {"primary": "CA", "region": "North America"},
        "jp": {"primary": "JP", "region": "Asia-Pacific"},
        "cn": {"primary": "CN", "region": "Asia"},
        "in": {"primary": "IN", "region": "Asia"},
        "com": {"primary": "US", "region": "Global"},
        "io": {"primary": "Global", "region": "Global"},
    }
    return tld_country_map.get(tld, {"primary": "Unknown", "region": "Unknown"})


def _extract_keywords(domain: str, title: str) -> list[str]:
    words: list[str] = []
    name_part = domain.split(".")[0]
    words.extend(re.findall(r"[a-zA-Z]+", name_part))
    if title:
        words.extend(re.findall(r"[a-zA-Z]{3,}", title)[:5])
    return list(dict.fromkeys(w.lower() for w in words if len(w) >= 3))[:10]
