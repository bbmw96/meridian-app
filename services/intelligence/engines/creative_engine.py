from __future__ import annotations

import hashlib
import os
import uuid
from typing import Any

import anthropic
import structlog

from models.schemas import Creative, CreativeDimensions, CreativeRequest

log = structlog.get_logger()

PLATFORM_DIMENSIONS: dict[str, dict[str, CreativeDimensions]] = {
    "instagram": {
        "static": CreativeDimensions(width=1080, height=1080),
        "story": CreativeDimensions(width=1080, height=1920),
        "reel": CreativeDimensions(width=1080, height=1920),
    },
    "facebook": {
        "static": CreativeDimensions(width=1200, height=630),
        "video": CreativeDimensions(width=1280, height=720),
    },
    "linkedin": {
        "static": CreativeDimensions(width=1200, height=627),
        "video": CreativeDimensions(width=1920, height=1080),
    },
    "twitter": {
        "static": CreativeDimensions(width=1200, height=675),
    },
    "tiktok": {
        "video": CreativeDimensions(width=1080, height=1920),
    },
    "google": {
        "static": CreativeDimensions(width=300, height=250),
        "leaderboard": CreativeDimensions(width=728, height=90),
        "skyscraper": CreativeDimensions(width=160, height=600),
    },
    "email": {
        "email": CreativeDimensions(width=600, height=800),
    },
}


class CreativeEngine:
    AIDA_TEMPLATE = (
        "You are an expert advertising copywriter specialising in the AIDA framework "
        "(Attention, Interest, Desire, Action). Write compelling ad copy for {brand_name} "
        "in the {industry} industry, targeting the {platform} platform. "
        "Tone: {tone}. "
        "Keywords to incorporate naturally: {keywords}. "
        "\n\nDeliver the response in this exact JSON structure:\n"
        '{{"headline": "...", "body": "...", "call_to_action": "..."}}\n\n'
        "ATTENTION: Open with a bold, surprising statement or question that stops the scroll.\n"
        "INTEREST: Build curiosity with relevant facts or pain points.\n"
        "DESIRE: Create emotional resonance and show transformation.\n"
        "ACTION: Clear, urgent call to action.\n"
        "Keep body under 150 words. Headline under 10 words. CTA under 6 words."
    )

    PAS_TEMPLATE = (
        "You are a direct-response copywriter using the PAS framework "
        "(Problem, Agitation, Solution). Write copy for {brand_name} "
        "in the {industry} industry, for the {platform} platform. "
        "Tone: {tone}. "
        "Keywords: {keywords}. "
        "\n\nDeliver the response in this exact JSON structure:\n"
        '{{"headline": "...", "body": "...", "call_to_action": "..."}}\n\n'
        "PROBLEM: Identify the core pain point your audience faces.\n"
        "AGITATION: Intensify the pain - make them feel the urgency.\n"
        "SOLUTION: Present {brand_name} as the clear, credible resolution.\n"
        "Keep body under 150 words. Headline under 10 words. CTA under 6 words."
    )

    BAB_TEMPLATE = (
        "You are a transformation-focused copywriter using the BAB framework "
        "(Before, After, Bridge). Write copy for {brand_name} "
        "in the {industry} industry, for the {platform} platform. "
        "Tone: {tone}. "
        "Keywords: {keywords}. "
        "\n\nDeliver the response in this exact JSON structure:\n"
        '{{"headline": "...", "body": "...", "call_to_action": "..."}}\n\n'
        "BEFORE: Paint a vivid picture of the audience's current painful situation.\n"
        "AFTER: Describe the aspirational state they desire.\n"
        "BRIDGE: Show exactly how {brand_name} takes them from before to after.\n"
        "Keep body under 150 words. Headline under 10 words. CTA under 6 words."
    )

    TEMPLATE_MAP = {
        "aida": AIDA_TEMPLATE,
        "pas": PAS_TEMPLATE,
        "bab": BAB_TEMPLATE,
    }

    def __init__(self) -> None:
        self._anthropic: anthropic.AsyncAnthropic | None = None

    async def initialise(self) -> None:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if api_key:
            self._anthropic = anthropic.AsyncAnthropic(api_key=api_key)
            log.info("meridian.creative_engine.anthropic_ready")
        else:
            log.warning("meridian.creative_engine.no_anthropic_key", message="Creative generation will use fallback copy")

    async def generate(self, request: CreativeRequest) -> Creative:
        if request.format in ("video",):
            return await self._generate_video_brief(request)

        if request.format == "static":
            return await self._generate_static_brief(request)

        return await self._generate_text_creative(request)

    async def _generate_text_creative(self, request: CreativeRequest) -> Creative:
        template_key = request.template or self._select_template(request)
        template = self.TEMPLATE_MAP.get(template_key, self.AIDA_TEMPLATE)

        keywords_str = ", ".join(request.keywords) if request.keywords else request.industry

        prompt = template.format(
            brand_name=request.brand_name,
            industry=request.industry,
            platform=request.platform,
            tone=request.tone,
            keywords=keywords_str,
        )

        headline = f"Transform Your {request.industry.title()} Results with {request.brand_name}"
        body = (
            f"Discover how {request.brand_name} is helping {request.industry} businesses "
            f"achieve extraordinary results. Join thousands of successful clients who have "
            f"already made the switch. Your competitors are already using it."
        )
        cta = "Start Free Today"

        if self._anthropic:
            try:
                import json

                message = await self._anthropic.messages.create(
                    model="claude-sonnet-4-6",
                    max_tokens=512,
                    messages=[{"role": "user", "content": prompt}],
                )
                raw = message.content[0].text.strip()
                start = raw.find("{")
                end = raw.rfind("}") + 1
                if start >= 0 and end > start:
                    parsed = json.loads(raw[start:end])
                    headline = parsed.get("headline", headline)
                    body = parsed.get("body", body)
                    cta = parsed.get("call_to_action", cta)
            except Exception as exc:
                log.warning("meridian.creative_engine.llm_failed", error=str(exc))

        dimensions = self._get_dimensions(request.platform, request.format)

        creative_id = str(
            uuid.UUID(
                int=int(
                    hashlib.md5(
                        f"{request.brand_name}{request.platform}{request.format}".encode()
                    ).hexdigest(),
                    16,
                )
            )
        )

        return Creative(
            id=creative_id,
            format=request.format,
            platform=request.platform,
            title=headline,
            body=body,
            headline=headline,
            call_to_action=cta,
            dimensions=dimensions,
            template_used=template_key,
            provider="anthropic" if self._anthropic else "fallback",
            model="claude-sonnet-4-6" if self._anthropic else "rule-based",
        )

    async def _generate_static_brief(self, request: CreativeRequest) -> Creative:
        dimensions = self._get_dimensions(request.platform, "static")

        headline = f"{request.brand_name} - {request.industry.title()} Redefined"
        body = (
            f"Visual creative brief for {request.brand_name}.\n"
            f"Platform: {request.platform}\n"
            f"Dimensions: {dimensions.width}x{dimensions.height}px\n"
            f"Tone: {request.tone}\n"
            f"Key message: Drive {request.industry} growth with proven tools.\n"
            f"Keywords: {', '.join(request.keywords[:5]) if request.keywords else request.industry}"
        )

        creative_id = str(
            uuid.UUID(
                int=int(hashlib.md5(f"{request.brand_name}{request.platform}static".encode()).hexdigest(), 16)
            )
        )

        return Creative(
            id=creative_id,
            format="static",
            platform=request.platform,
            title=headline,
            body=body,
            headline=headline,
            call_to_action="Learn More",
            dimensions=dimensions,
            template_used="visual_brief",
            provider="internal",
            model="rule-based",
        )

    async def _generate_video_brief(self, request: CreativeRequest) -> Creative:
        dimensions = self._get_dimensions(request.platform, "video")

        headline = f"{request.brand_name} Video Ad - {request.platform.title()}"
        body = (
            f"Video creative brief:\n"
            f"Brand: {request.brand_name}\n"
            f"Industry: {request.industry}\n"
            f"Platform: {request.platform}\n"
            f"Dimensions: {dimensions.width if dimensions else 1920}x{dimensions.height if dimensions else 1080}px\n"
            f"Duration: 15-30 seconds\n"
            f"Tone: {request.tone}\n"
            f"Opening (0-3s): Bold visual hook - show the problem.\n"
            f"Middle (3-20s): Product demonstration with key benefit.\n"
            f"Close (20-30s): {request.brand_name} branding + CTA overlay.\n"
            f"Keywords: {', '.join(request.keywords[:5]) if request.keywords else request.industry}"
        )

        creative_id = str(
            uuid.UUID(
                int=int(hashlib.md5(f"{request.brand_name}{request.platform}video".encode()).hexdigest(), 16)
            )
        )

        return Creative(
            id=creative_id,
            format="video",
            platform=request.platform,
            title=headline,
            body=body,
            headline=headline,
            call_to_action="Watch Now",
            dimensions=dimensions,
            template_used="video_brief",
            provider="internal",
            model="rule-based",
        )

    def _select_template(self, request: CreativeRequest) -> str:
        industry_lower = request.industry.lower()
        if any(w in industry_lower for w in ("finance", "insurance", "legal", "health")):
            return "pas"
        if any(w in industry_lower for w in ("coaching", "fitness", "lifestyle", "beauty")):
            return "bab"
        return "aida"

    def _get_dimensions(
        self, platform: str, fmt: str
    ) -> CreativeDimensions | None:
        platform_lower = platform.lower()
        platform_dims = PLATFORM_DIMENSIONS.get(platform_lower, {})
        return platform_dims.get(fmt) or platform_dims.get(list(platform_dims.keys())[0] if platform_dims else "static")
