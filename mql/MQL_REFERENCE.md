# MQL: MERIDIAN Query Language
## Language Reference v1.0

MQL is a domain-specific query language for unified global business intelligence.
It compiles to REST API calls, SQL queries, and ML inference tasks simultaneously.

---

## Statements

MQL has five statement types, each corresponding to a major intelligence operation.

### SCAN

Analyses a domain and optionally discovers competitors, converts revenue, or generates a creative.

```mql
SCAN domain "example.com"

SCAN domain "shopify.com"
  COMPARE competitors TOP 10
  WHERE geography IN ["GB", "DE", "JP"]
  AND traffic.monthly > 500000
  CONVERT revenue TO "GBP"
  RANK BY opportunity_score DESC
  LIMIT 5
```

Clauses (all optional after the domain):
- `COMPARE competitors TOP <n>` — discover the top n competitor domains
- `WHERE <expr>` — filter competitors by field conditions
- `CONVERT revenue TO "<currency>"` — show revenue estimates in target currency
- `GENERATE ad ...` — produce an AI creative for the domain's audience
- `RANK BY <field> ASC|DESC` — sort results
- `LIMIT <n>` — restrict result count

---

### FIND

Discovers market opportunities matching a set of conditions.

```mql
FIND opportunities
  WHERE market = "saas"
  AND currency.stability > 0.9
  AND competitor.traffic.trend = "declining"
  RANK BY opportunity_score DESC
  LIMIT 20
  GENERATE ad STYLE "ugc-video" LANGUAGE "fr" FRAMEWORK "PAS"
```

The optional `GENERATE` clause produces an AI creative targeting the discovered opportunities.

---

### GENERATE

Produces an AI creative directly, without an intelligence query.

```mql
GENERATE ad
  FOR domain "competitor.com"
  STYLE "ugc-video"
  LANGUAGE "en-GB"
  CURRENCY "GBP"
  PLATFORM "instagram"
  FRAMEWORK "AIDA"
```

Style values: `"static"`, `"ugc-video"`, `"carousel"`, `"story"`
Platform values: `"instagram"`, `"tiktok"`, `"google"`, `"linkedin"`, `"snapchat"`, `"pinterest"`
Framework values: `"AIDA"`, `"PAS"`, `"BAB"`

---

### ALERT

Creates a monitoring alert that triggers a push notification when a condition is met.

```mql
ALERT WHEN
  currency "USD/GBP" rate.change > 3%
  NOTIFY via "push"
  WITH message "GBP rate has moved by more than 3 percent"

ALERT WHEN
  domain "competitor.com" traffic.change > 20%
  NOTIFY via "push"
  WITH message "Competitor traffic spike detected"
```

---

### ANALYSE

Performs a deep multi-dimensional analysis of a domain.

```mql
ANALYSE domain "netflix.com"
  DIMENSIONS [traffic, keywords, geography, technology, ads]
  TIMEFRAME "90d"
  BENCHMARK AGAINST "disney.com"
  EXPORT FORMAT "report"
```

Dimension values: `traffic`, `keywords`, `geography`, `technology`, `ads`
Timeframe values: `"7d"`, `"30d"`, `"90d"`, `"1y"`

---

## Field Reference

| Field | Type | Description |
|---|---|---|
| `traffic.monthly` | Number | Estimated monthly visits |
| `traffic.trend` | Enum | `"rising"`, `"stable"`, `"declining"` |
| `traffic.change` | Percentage | Month-over-month change (e.g. `20%`) |
| `revenue` | Number | Estimated annual revenue |
| `geography` | Text | ISO 3166-1 alpha-2 country code |
| `market` | Text | Industry vertical (e.g. `"saas"`, `"e-commerce"`) |
| `currency.stability` | Number (0-1) | FX volatility score; 1.0 = most stable |
| `rate.change` | Percentage | FX rate change over period |
| `rate.blended` | Keyword | Use MERIDIAN's blended mid-market rate |
| `opportunity_score` | Number (0-100) | AI-computed opportunity quality score |
| `competitor.traffic.trend` | Enum | Trend for competitor's traffic |
| `technology` | Text | Technology stack identifier |

---

## Operators

| Operator | Meaning |
|---|---|
| `>` | Greater than |
| `<` | Less than |
| `>=` | Greater than or equal |
| `<=` | Less than or equal |
| `=` | Equal |
| `!=` | Not equal |
| `IN [...]` | Value is in list |
| `%` | Percentage literal suffix |

---

## Boolean Logic

```mql
WHERE traffic.monthly > 100000
AND geography IN ["GB", "US"]
AND NOT market = "gambling"
OR opportunity_score > 90
```

Precedence (highest to lowest): `NOT`, `AND`, `OR`. Use natural left-to-right evaluation for `AND`/`OR` chains.

---

## Literal Types

| Type | Example |
|---|---|
| String | `"en-GB"`, `"competitor.com"` |
| Integer | `100000`, `10` |
| Float | `0.85`, `3.2` |
| Percentage | `3%`, `20%` (syntactic sugar for float / 100) |
| List | `["GB", "DE", "JP"]` |
| Boolean | `true`, `false` |

---

## Comments

```mql
-- Single-line comment
SCAN domain "example.com" -- inline comment
```

---

## Error Messages

MQL provides typed errors:

- `LexError`: Invalid character or unterminated string literal
- `ParseError`: Unexpected token; includes position and expected token
- `TypeError`: Unknown field path, invalid currency code, or invalid style value
- `RuntimeError`: Network failure or backend timeout during execution

---

## Compiler Architecture

```
Source text
    |
    v
Lexer (Rust)         -- tokenises into Token stream
    |
    v
Parser (Rust)        -- recursive-descent, produces AST
    |
    v
Type Checker (Rust)  -- validates field paths, currency codes, style values
    |
    v
Code Generator
    |-- API Codegen   -> REST API call sequence (JSON)
    |-- SQL Codegen   -> ClickHouse SQL query
    |-- ML Codegen    -> Model inference task descriptor
    |
    v
Runtime              -- executes all three in parallel, merges results
    |
    v
Typed Result         -- ScanResult | OpportunityList | Creative | Alert | Message
```

The compiled output (`ExecutionPlan`) is a JSON-serialisable tree of `ExecutionStep` nodes.
The iOS app embeds the compiler as a WASM module via Swift's C FFI bridge.

---

## Example: Full Pipeline Query

This single MQL query triggers competitive intelligence, currency conversion, and creative generation simultaneously:

```mql
SCAN domain "etsy.com"
  COMPARE competitors TOP 5
  WHERE geography IN ["GB", "AU", "CA"]
  AND traffic.monthly > 1000000
  CONVERT revenue TO "GBP" USING rate.blended
  GENERATE ad
    STYLE "static"
    LANGUAGE "en-GB"
    PLATFORM "instagram"
    FRAMEWORK "AIDA"
  RANK BY opportunity_score DESC
  LIMIT 5
```

This compiles to:
1. `GET /api/v1/intelligence/scan?domain=etsy.com`
2. `GET /api/v1/intelligence/competitors?domain=etsy.com&limit=5`
3. `SELECT * FROM intelligence_signals WHERE geography IN ('GB','AU','CA') AND traffic_monthly > 1000000 ORDER BY opportunity_score DESC LIMIT 5`
4. `GET /api/v1/currency/rates?pairs=GBP/USD,GBP/AUD,GBP/CAD`
5. `POST /api/v1/creative/generate` with AIDA-framed prompt

Steps 1, 2, 4, and 5 execute in parallel. Step 3 executes against ClickHouse concurrently.
Results merge into a single `ScanResult` response.
