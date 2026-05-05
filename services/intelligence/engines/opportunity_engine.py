from __future__ import annotations

import hashlib
import os
import uuid
from datetime import datetime
from typing import Any

import httpx
import structlog

from models.schemas import Opportunity, OpportunityFilters

log = structlog.get_logger()

MARKET_DATA: dict[str, dict[str, Any]] = {
    "saas": {
        "growth_rate": 0.18,
        "avg_revenue_gbp": 2_500_000,
        "saturation": 0.6,
        "geographies": ["US", "GB", "DE", "AU", "CA"],
    },
    "ecommerce": {
        "growth_rate": 0.12,
        "avg_revenue_gbp": 800_000,
        "saturation": 0.75,
        "geographies": ["GB", "DE", "FR", "AU", "US"],
    },
    "fintech": {
        "growth_rate": 0.22,
        "avg_revenue_gbp": 5_000_000,
        "saturation": 0.45,
        "geographies": ["GB", "SG", "US", "UAE", "AU"],
    },
    "healthtech": {
        "growth_rate": 0.15,
        "avg_revenue_gbp": 1_200_000,
        "saturation": 0.35,
        "geographies": ["US", "GB", "DE", "AU", "CA"],
    },
    "edtech": {
        "growth_rate": 0.20,
        "avg_revenue_gbp": 600_000,
        "saturation": 0.55,
        "geographies": ["IN", "US", "GB", "AU", "BR"],
    },
    "logistics": {
        "growth_rate": 0.09,
        "avg_revenue_gbp": 3_000_000,
        "saturation": 0.65,
        "geographies": ["GB", "DE", "NL", "US", "SG"],
    },
    "proptech": {
        "growth_rate": 0.14,
        "avg_revenue_gbp": 1_800_000,
        "saturation": 0.40,
        "geographies": ["GB", "US", "AU", "SG", "AE"],
    },
    "cybersecurity": {
        "growth_rate": 0.25,
        "avg_revenue_gbp": 4_000_000,
        "saturation": 0.30,
        "geographies": ["US", "GB", "IL", "AU", "SG"],
    },
}

GEOGRAPHY_FX_STABILITY: dict[str, float] = {
    "US": 0.95,
    "GB": 0.90,
    "DE": 0.88,
    "FR": 0.88,
    "AU": 0.80,
    "CA": 0.82,
    "JP": 0.75,
    "SG": 0.85,
    "AE": 0.83,
    "IN": 0.65,
    "BR": 0.55,
    "NG": 0.40,
    "KE": 0.50,
    "IL": 0.72,
    "NL": 0.88,
    "UAE": 0.83,
}


class OpportunityEngine:
    def __init__(self) -> None:
        self._http = httpx.AsyncClient(timeout=10.0)

    async def initialise(self) -> None:
        log.info("meridian.opportunity_engine.initialised")

    async def discover(self, filters: OpportunityFilters) -> list[Opportunity]:
        opportunities: list[Opportunity] = []

        target_markets = (
            [filters.market.lower()] if filters.market else list(MARKET_DATA.keys())
        )
        target_geos = (
            [filters.geography.upper()] if filters.geography else ["GB", "US", "DE", "AU", "SG"]
        )

        for market in target_markets:
            market_data = MARKET_DATA.get(market)
            if not market_data:
                continue

            for geo in target_geos:
                if geo not in market_data["geographies"]:
                    continue

                signals = await self.get_market_signals(market, geo)
                score = self.score(signals)

                if score < filters.min_score:
                    continue

                opp_id = str(
                    uuid.UUID(
                        int=int(hashlib.md5(f"{market}{geo}".encode()).hexdigest(), 16)
                    )
                )

                traffic_gap = signals.get("traffic_gap", 0.5)
                market_growth = signals.get("market_growth", 0.1)
                estimated_revenue = market_data["avg_revenue_gbp"] * (1 + market_growth)

                if filters.min_market_size_gbp and estimated_revenue < filters.min_market_size_gbp:
                    continue

                opportunities.append(
                    Opportunity(
                        id=opp_id,
                        title=f"{market.title()} Expansion - {geo}",
                        description=(
                            f"High-value opportunity in the {market} sector within {geo}. "
                            f"Market growing at {market_growth * 100:.1f}% annually with "
                            f"relatively low saturation."
                        ),
                        score=round(score, 2),
                        market=market,
                        geography=geo,
                        sector=filters.sector or market,
                        traffic_gap=round(signals["traffic_gap"], 3),
                        fx_stability=round(signals["fx_stability"], 3),
                        competitor_weakness=round(signals["competitor_weakness"], 3),
                        market_growth=round(signals["market_growth"], 3),
                        estimated_revenue_gbp=round(estimated_revenue, 2),
                        confidence=round(0.5 + score / 200, 3),
                    )
                )

                if len(opportunities) >= filters.max_results:
                    break
            if len(opportunities) >= filters.max_results:
                break

        opportunities.sort(key=lambda o: o.score, reverse=True)
        return opportunities[: filters.max_results]

    def _score(
        self,
        traffic_gap: float,
        fx_stability: float,
        competitor_weakness: float,
        market_growth: float,
    ) -> float:
        raw = (
            traffic_gap * 0.30
            + fx_stability * 0.25
            + competitor_weakness * 0.25
            + market_growth * 0.20
        )
        return min(100.0, raw * 100.0)

    def _seed_opportunities(self) -> list[Opportunity]:
        seeds = []
        for market, geo in [("saas", "GB"), ("fintech", "US"), ("edtech", "IN"), ("cybersecurity", "US"), ("proptech", "GB")]:
            import hashlib, uuid
            score = self._score(0.6, 0.85, 0.7, 0.18)
            opp_id = str(uuid.UUID(int=int(hashlib.md5(f"{market}{geo}".encode()).hexdigest(), 16)))
            seeds.append(Opportunity(
                id=opp_id, title=f"{market.title()} - {geo}", description="seed",
                score=score, market=market, geography=geo, sector=market,
                traffic_gap=0.6, fx_stability=0.85, competitor_weakness=0.7,
                market_growth=0.18, estimated_revenue_gbp=100000.0, confidence=0.75,
            ))
        return seeds

    def _apply_filters(self, opps: list[Opportunity], filters: OpportunityFilters) -> list[Opportunity]:
        result = opps
        if filters.market:
            result = [o for o in result if o.market.lower() == filters.market.lower()]
        if filters.min_score:
            result = [o for o in result if o.score >= filters.min_score]
        limit = getattr(filters, "limit", None) or filters.max_results
        return result[:limit]

    def score(self, signals: dict[str, Any]) -> float:
        traffic_gap = float(signals.get("traffic_gap", 0.5))
        fx_stability = float(signals.get("fx_stability", 0.7))
        competitor_weakness = float(signals.get("competitor_weakness", 0.5))
        market_growth = float(signals.get("market_growth", 0.1))

        raw = (
            traffic_gap * 0.30
            + fx_stability * 0.25
            + competitor_weakness * 0.25
            + market_growth * 0.20
        )

        return min(100.0, raw * 100.0)

    async def get_market_signals(self, market: str, geography: str) -> dict[str, Any]:
        market_data = MARKET_DATA.get(market.lower(), {})
        saturation = float(market_data.get("saturation", 0.5))
        growth_rate = float(market_data.get("growth_rate", 0.1))

        digest = int(hashlib.md5(f"{market}{geography}".encode()).hexdigest()[:6], 16)
        noise = (digest % 1000) / 10_000

        traffic_gap = max(0.0, min(1.0, (1.0 - saturation) + noise))
        fx_stability = GEOGRAPHY_FX_STABILITY.get(geography.upper(), 0.6)
        competitor_weakness = max(0.0, min(1.0, (1.0 - saturation) * 0.8 + noise))
        market_growth = min(1.0, growth_rate + noise)

        return {
            "traffic_gap": traffic_gap,
            "fx_stability": fx_stability,
            "competitor_weakness": competitor_weakness,
            "market_growth": market_growth,
            "saturation": saturation,
            "raw_growth_rate": growth_rate,
        }
