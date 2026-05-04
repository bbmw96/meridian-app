-- MERIDIAN ClickHouse Analytics Schema
-- ClickHouse 24.x
-- Run against ClickHouse: clickhouse-client --query "$(cat 002_clickhouse.sql)"

-- Intelligence signals table (append-only, high-throughput reads)
CREATE TABLE IF NOT EXISTS intelligence_signals
(
    domain           LowCardinality(String),
    traffic_monthly  UInt64,
    traffic_trend    Enum8('rising' = 1, 'stable' = 2, 'declining' = 3),
    geography        LowCardinality(FixedString(2)),
    market           LowCardinality(String),
    opportunity_score Float32,
    technology_stack Array(LowCardinality(String)),
    ad_spend_signal  Enum8('none' = 0, 'low' = 1, 'medium' = 2, 'high' = 3),
    scanned_at       DateTime DEFAULT now()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(scanned_at)
ORDER BY (domain, scanned_at)
SETTINGS index_granularity = 8192;

-- Currency rate history (time-series, 30-second granularity)
CREATE TABLE IF NOT EXISTS currency_rates
(
    pair        LowCardinality(FixedString(7)),
    rate        Float64,
    source      LowCardinality(String),
    recorded_at DateTime DEFAULT now()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(recorded_at)
ORDER BY (pair, recorded_at)
TTL recorded_at + INTERVAL 2 YEAR
SETTINGS index_granularity = 8192;

-- Opportunity scoring history
CREATE TABLE IF NOT EXISTS opportunity_scores
(
    opportunity_id  UUID,
    market          LowCardinality(String),
    geography       LowCardinality(FixedString(2)),
    opportunity_score Float32,
    currency_stability Float32,
    traffic_gap     Float32,
    scored_at       DateTime DEFAULT now()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(scored_at)
ORDER BY (market, geography, scored_at)
SETTINGS index_granularity = 8192;

-- MQL query analytics (aggregate query patterns, no PII)
CREATE TABLE IF NOT EXISTS mql_analytics
(
    query_hash      FixedString(64),
    statement_type  LowCardinality(String),
    execution_ms    UInt32,
    success         UInt8,
    executed_at     DateTime DEFAULT now()
)
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(executed_at)
ORDER BY (statement_type, executed_at)
TTL executed_at + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- Materialised view: hourly opportunity score aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS opportunity_scores_hourly
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (market, geography, hour)
AS SELECT
    market,
    geography,
    toStartOfHour(scored_at) AS hour,
    avg(opportunity_score) AS avg_score,
    max(opportunity_score) AS max_score,
    count() AS signal_count
FROM opportunity_scores
GROUP BY market, geography, hour;

-- Materialised view: daily currency rate summary
CREATE MATERIALIZED VIEW IF NOT EXISTS currency_rates_daily
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(day)
ORDER BY (pair, day)
AS SELECT
    pair,
    toStartOfDay(recorded_at) AS day,
    avgState(rate) AS avg_rate,
    minState(rate) AS min_rate,
    maxState(rate) AS max_rate
FROM currency_rates
GROUP BY pair, day;
