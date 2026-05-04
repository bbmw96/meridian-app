from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field, field_validator


class ScanRequest(BaseModel):
    domain: str = Field(..., min_length=3, max_length=253)

    @field_validator("domain")
    @classmethod
    def normalise_domain(cls, v: str) -> str:
        v = v.strip().lower()
        v = v.removeprefix("https://").removeprefix("http://").removeprefix("www.")
        if "/" in v:
            v = v.split("/")[0]
        return v


class MQLQuery(BaseModel):
    query: str = Field(..., min_length=1, max_length=10_000)


class TrafficEstimate(BaseModel):
    monthly_visits: int = Field(..., ge=0)
    confidence: float = Field(..., ge=0.0, le=1.0)
    lower_bound: int = Field(..., ge=0)
    upper_bound: int = Field(..., ge=0)
    methodology: str = "ml_random_forest"


class DomainProfile(BaseModel):
    domain: str
    title: Optional[str] = None
    description: Optional[str] = None
    monthly_traffic: int = Field(default=0, alias="monthlyTraffic")
    estimated_revenue_gbp: Optional[float] = Field(default=None, alias="estimatedRevenueGBP")
    keywords: list[str] = Field(default_factory=list)
    geography: dict[str, Any] = Field(default_factory=dict)
    backlink_count: int = 0
    domain_age_days: int = 0
    tld: str = ""
    traffic_estimate: Optional[TrafficEstimate] = None
    technologies: list[str] = Field(default_factory=list)
    social_signals: dict[str, int] = Field(default_factory=dict)
    cached: bool = False
    scanned_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = {"populate_by_name": True}


class Competitor(BaseModel):
    domain: str
    similarity_score: float = Field(..., ge=0.0, le=1.0)
    monthly_traffic: int = 0
    shared_keywords: list[str] = Field(default_factory=list)
    traffic_delta_percent: float = 0.0
    estimated_revenue_gbp: Optional[float] = None


class OpportunityFilters(BaseModel):
    market: Optional[str] = None
    geography: Optional[str] = None
    min_score: float = Field(default=50.0, ge=0.0, le=100.0)
    max_results: int = Field(default=20, ge=1, le=100)
    sector: Optional[str] = None
    min_market_size_gbp: Optional[float] = None


class Opportunity(BaseModel):
    id: str
    title: str
    description: str
    score: float = Field(..., ge=0.0, le=100.0)
    market: str
    geography: str
    sector: Optional[str] = None
    traffic_gap: float = 0.0
    fx_stability: float = 0.0
    competitor_weakness: float = 0.0
    market_growth: float = 0.0
    estimated_revenue_gbp: Optional[float] = None
    confidence: float = Field(default=0.7, ge=0.0, le=1.0)
    discovered_at: datetime = Field(default_factory=datetime.utcnow)


class CreativeRequest(BaseModel):
    format: str = Field(..., pattern="^(static|video|text|email|social)$")
    platform: str
    industry: str
    brand_name: str
    tone: str = "professional"
    keywords: list[str] = Field(default_factory=list)
    template: Optional[str] = Field(default=None, pattern="^(aida|pas|bab)?$")
    constraints: dict[str, str] = Field(default_factory=dict)


class CreativeDimensions(BaseModel):
    width: int
    height: int
    unit: str = "px"


class Creative(BaseModel):
    id: str
    format: str
    platform: str
    title: str
    body: str
    headline: Optional[str] = None
    call_to_action: Optional[str] = None
    dimensions: Optional[CreativeDimensions] = None
    template_used: str
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    provider: str = "anthropic"
    model: str = "claude-sonnet-4-6"


class AnalyseRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=10_000)


class AnalyseResult(BaseModel):
    query: str
    result_type: str
    data: dict[str, Any]
    message: str
    analysed_at: datetime = Field(default_factory=datetime.utcnow)
