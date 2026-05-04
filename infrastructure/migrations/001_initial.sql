-- MERIDIAN Initial Schema Migration
-- PostgreSQL 16

BEGIN;

-- Intelligence: domain scan cache
CREATE TABLE IF NOT EXISTS domain_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain TEXT NOT NULL,
    monthly_traffic BIGINT,
    traffic_trend TEXT CHECK (traffic_trend IN ('rising', 'stable', 'declining')),
    top_keywords TEXT[],
    geography_breakdown JSONB,
    estimated_revenue_gbp NUMERIC(18, 2),
    technology_stack TEXT[],
    ad_spend_signal TEXT CHECK (ad_spend_signal IN ('none', 'low', 'medium', 'high')),
    raw_response JSONB,
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '1 hour',
    UNIQUE (domain)
);

CREATE INDEX idx_domain_scans_domain ON domain_scans (domain);
CREATE INDEX idx_domain_scans_expires ON domain_scans (expires_at);

-- Competitors
CREATE TABLE IF NOT EXISTS competitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_domain TEXT NOT NULL,
    competitor_domain TEXT NOT NULL,
    traffic_share NUMERIC(5, 4),
    delta NUMERIC(5, 4),
    currency_adjusted_revenue NUMERIC(18, 2),
    target_currency CHAR(3),
    opportunity_score NUMERIC(5, 2) CHECK (opportunity_score BETWEEN 0 AND 100),
    geographies TEXT[],
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_competitors_source ON competitors (source_domain);
CREATE INDEX idx_competitors_score ON competitors (opportunity_score DESC);

-- Opportunities
CREATE TABLE IF NOT EXISTS opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    market TEXT,
    geography TEXT,
    opportunity_score NUMERIC(5, 2) CHECK (opportunity_score BETWEEN 0 AND 100),
    currency_stability NUMERIC(5, 4),
    traffic_gap NUMERIC(12, 2),
    estimated_revenue_gbp NUMERIC(18, 2),
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
    is_featured BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_opportunities_score ON opportunities (opportunity_score DESC);
CREATE INDEX idx_opportunities_market ON opportunities (market);
CREATE INDEX idx_opportunities_geography ON opportunities (geography);
CREATE INDEX idx_opportunities_expires ON opportunities (expires_at);

-- Rate alerts (server-side storage for push notification triggering)
CREATE TABLE IF NOT EXISTS rate_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_token TEXT NOT NULL,
    currency_pair TEXT NOT NULL,
    threshold NUMERIC(10, 6) NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('above', 'below')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_user ON rate_alerts (user_token);
CREATE INDEX idx_alerts_active ON rate_alerts (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_alerts_pair ON rate_alerts (currency_pair);

-- Creative generation history
CREATE TABLE IF NOT EXISTS creatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_token TEXT,
    source_domain TEXT,
    platform TEXT NOT NULL,
    format TEXT NOT NULL,
    framework TEXT,
    language CHAR(10) NOT NULL DEFAULT 'en-GB',
    currency CHAR(3),
    title TEXT,
    body TEXT,
    image_url TEXT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_creatives_user ON creatives (user_token);
CREATE INDEX idx_creatives_domain ON creatives (source_domain);

-- MQL query history (anonymised, for analytics)
CREATE TABLE IF NOT EXISTS mql_queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_hash TEXT NOT NULL,
    statement_type TEXT NOT NULL,
    execution_ms INTEGER,
    success BOOLEAN NOT NULL,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mql_hash ON mql_queries (query_hash);
CREATE INDEX idx_mql_type ON mql_queries (statement_type);

COMMIT;
