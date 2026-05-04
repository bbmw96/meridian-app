from contextlib import asynccontextmanager
from typing import Any

import structlog
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from engines.domain_engine import DomainEngine
from engines.opportunity_engine import OpportunityEngine
from engines.creative_engine import CreativeEngine
from models.schemas import (
    AnalyseRequest,
    AnalyseResult,
    CreativeRequest,
    DomainProfile,
    MQLQuery,
    OpportunityFilters,
    ScanRequest,
)

load_dotenv()

log = structlog.get_logger()

domain_engine: DomainEngine = None
opportunity_engine: OpportunityEngine = None
creative_engine: CreativeEngine = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global domain_engine, opportunity_engine, creative_engine

    log.info("meridian.intelligence.startup", message="Loading ML models and initialising engines")

    domain_engine = DomainEngine()
    await domain_engine.initialise()

    opportunity_engine = OpportunityEngine()
    await opportunity_engine.initialise()

    creative_engine = CreativeEngine()
    await creative_engine.initialise()

    log.info("meridian.intelligence.startup", message="All engines ready")

    yield

    log.info("meridian.intelligence.shutdown", message="Shutting down intelligence service")


app = FastAPI(
    title="MERIDIAN Intelligence Service",
    description="Domain scanning, competitor analysis, opportunity detection, and AI creative generation",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    log.error(
        "meridian.intelligence.unhandled_error",
        path=str(request.url),
        error=str(exc),
        exc_type=type(exc).__name__,
    )
    return JSONResponse(
        status_code=500,
        content={"error": "internal_error", "message": "An unexpected error occurred"},
    )


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "service": "meridian-intelligence",
        "engines": {
            "domain": domain_engine is not None,
            "opportunity": opportunity_engine is not None,
            "creative": creative_engine is not None,
        },
    }


@app.post("/scan", response_model=DomainProfile)
async def scan_domain(req: ScanRequest) -> DomainProfile:
    if not domain_engine:
        raise HTTPException(status_code=503, detail="Domain engine not initialised")
    try:
        return await domain_engine.scan(req.domain)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/competitors")
async def get_competitors(domain: str, limit: int = 10) -> dict[str, Any]:
    if not domain_engine:
        raise HTTPException(status_code=503, detail="Domain engine not initialised")
    if not domain:
        raise HTTPException(status_code=400, detail="domain parameter is required")
    limit = min(max(1, limit), 50)
    competitors = await domain_engine.get_competitors(domain, limit)
    return {"domain": domain, "competitors": [c.model_dump() for c in competitors], "count": len(competitors)}


@app.post("/opportunities")
async def discover_opportunities(filters: OpportunityFilters) -> dict[str, Any]:
    if not opportunity_engine:
        raise HTTPException(status_code=503, detail="Opportunity engine not initialised")
    opportunities = await opportunity_engine.discover(filters)
    return {
        "opportunities": [o.model_dump() for o in opportunities],
        "count": len(opportunities),
        "filters_applied": filters.model_dump(exclude_none=True),
    }


@app.post("/generate-creative")
async def generate_creative(req: CreativeRequest) -> dict[str, Any]:
    if not creative_engine:
        raise HTTPException(status_code=503, detail="Creative engine not initialised")
    try:
        creative = await creative_engine.generate(req)
        return creative.model_dump()
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/analyse", response_model=AnalyseResult)
async def analyse(req: AnalyseRequest) -> AnalyseResult:
    if not domain_engine or not opportunity_engine:
        raise HTTPException(status_code=503, detail="Engines not initialised")

    query_lower = req.query.lower()

    if "scan" in query_lower or "domain" in query_lower:
        words = req.query.split()
        domain = next(
            (w for w in words if "." in w and not w.startswith("-")),
            "example.com",
        )
        profile = await domain_engine.scan(domain)
        return AnalyseResult(
            query=req.query,
            result_type="scan_result",
            data=profile.model_dump(),
            message=f"Scan completed for {domain}",
        )

    if "opportunit" in query_lower:
        filters = OpportunityFilters()
        opportunities = await opportunity_engine.discover(filters)
        return AnalyseResult(
            query=req.query,
            result_type="opportunity_list",
            data={"opportunities": [o.model_dump() for o in opportunities]},
            message=f"Found {len(opportunities)} opportunities",
        )

    return AnalyseResult(
        query=req.query,
        result_type="message_result",
        data={},
        message=f"Query received: {req.query}",
    )


@app.post("/alerts")
async def create_alert(payload: dict[str, Any]) -> dict[str, Any]:
    log.info("meridian.intelligence.alert_created", payload=payload)
    return {
        "id": "alert_" + str(abs(hash(str(payload))))[:12],
        "status": "created",
        "config": payload,
    }
