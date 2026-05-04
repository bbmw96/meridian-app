# MERIDIAN API Contract
## Internal Service Interface Specification v1.0

All services communicate via the Go gateway. The iOS app talks exclusively to the BFF (GraphQL) and the Elixir real-time WebSocket.

---

## Authentication

All requests include:
```
Authorization: Bearer <JWT>
```

JWT payload:
```json
{
  "sub": "user-token-uuid",
  "iat": 1746345600,
  "exp": 1746432000
}
```

The gateway validates the JWT and injects `X-User-Token` into upstream requests.

---

## Intelligence Service (Python, port 8001)

### POST /scan
Analyse a domain.

Request:
```json
{ "domain": "example.com" }
```

Response:
```json
{
  "domain": "example.com",
  "monthly_traffic": 4200000,
  "traffic_trend": "rising",
  "top_keywords": ["ecommerce", "shopify", "online store"],
  "geography_breakdown": { "US": 0.42, "GB": 0.18, "CA": 0.09 },
  "estimated_revenue_gbp": 12400000.00,
  "technology_stack": ["Shopify", "Cloudflare", "React"],
  "ad_spend_signal": "high",
  "confidence": 0.78,
  "scanned_at": "2026-05-04T10:00:00Z"
}
```

### GET /competitors?domain=example.com&limit=10
Discover competitors.

Response:
```json
{
  "competitors": [
    {
      "domain": "competitor.com",
      "traffic_share": 0.032,
      "delta": 0.008,
      "opportunity_score": 76.4,
      "geographies": ["GB", "DE"]
    }
  ]
}
```

### POST /opportunities
Find market opportunities.

Request:
```json
{
  "market": "saas",
  "min_score": 70.0,
  "geography": "GB",
  "currency_stability_min": 0.85,
  "limit": 20
}
```

Response:
```json
{
  "opportunities": [
    {
      "id": "uuid",
      "title": "SaaS gap in German B2B market",
      "description": "Declining competitor traffic combined with GBP/EUR stability creates a 12-week entry window.",
      "market": "saas",
      "geography": "DE",
      "opportunity_score": 84.2,
      "currency_stability": 0.91,
      "traffic_gap": 230000,
      "estimated_revenue_gbp": 3400000,
      "discovered_at": "2026-05-04T09:30:00Z"
    }
  ]
}
```

### POST /generate-creative
Generate an AI creative.

Request:
```json
{
  "source_domain": "competitor.com",
  "style": "static",
  "language": "en-GB",
  "currency": "GBP",
  "platform": "instagram",
  "framework": "AIDA",
  "dimensions": { "width": 1080, "height": 1080 }
}
```

Response:
```json
{
  "id": "uuid",
  "title": "Stop paying agency fees",
  "body": "MERIDIAN users save an average of 60% on market research costs. Real intelligence. Real results. Try free today.",
  "platform": "instagram",
  "format": "static",
  "language": "en-GB",
  "currency": "GBP",
  "framework": "AIDA",
  "image_url": "https://cdn.meridian.io/creatives/uuid.png",
  "generated_at": "2026-05-04T10:05:00Z"
}
```

### POST /mql
Execute an MQL query (compiled form).

Request:
```json
{
  "execution_plan": {
    "steps": [
      { "type": "api_call", "method": "GET", "endpoint": "/scan", "params": { "domain": "example.com" } }
    ]
  },
  "raw_query": "SCAN domain \"example.com\""
}
```

Response: typed result matching the statement type.

---

## BFF GraphQL (TypeScript, port 4000)

Playground available at: `http://localhost:4000/graphql`

Key queries:
```graphql
query ScanDomain($domain: String!) {
  scanDomain(domain: $domain) {
    domain
    monthlyTraffic
    trafficTrend
    topKeywords
    estimatedRevenueGBP
    technologyStack
    adSpendSignal
  }
}

query GetOpportunities($market: String, $geography: String, $minScore: Float) {
  getOpportunities(market: $market, geography: $geography, minScore: $minScore) {
    id
    title
    description
    opportunityScore
    currencyStability
    estimatedRevenueGBP
    geography
    market
  }
}

mutation ExecuteMQL($query: String!) {
  executeMQL(query: $query) {
    ... on ScanResult {
      domain { domain monthlyTraffic }
      competitors { domain opportunityScore }
    }
    ... on OpportunityListResult {
      opportunities { id title opportunityScore }
    }
    ... on CreativeResult {
      creative { title body platform }
    }
  }
}
```

---

## Realtime WebSocket (Elixir Phoenix, port 4001)

Connect: `ws://localhost:4001/socket/websocket?token=<JWT>`

### Channel: rates:lobby

Join:
```json
{ "topic": "rates:lobby", "event": "phx_join", "payload": {}, "ref": "1" }
```

Incoming events:
```json
{
  "topic": "rates:lobby",
  "event": "rate_update",
  "payload": {
    "rates": [
      { "pair": "GBP/USD", "rate": 1.2701, "change_percent": 0.12, "timestamp": "2026-05-04T10:00:30Z" }
    ]
  }
}
```

### Channel: alerts:{user_token}

Subscribe to alert monitoring:
```json
{
  "topic": "alerts:user-token-uuid",
  "event": "subscribe_alert",
  "payload": {
    "id": "alert-uuid",
    "pair": "GBP/USD",
    "threshold": 1.30,
    "direction": "above"
  }
}
```

Alert trigger event (pushed to client when condition met):
```json
{
  "topic": "alerts:user-token-uuid",
  "event": "alert_triggered",
  "payload": {
    "alert_id": "alert-uuid",
    "pair": "GBP/USD",
    "current_rate": 1.3012,
    "threshold": 1.30,
    "direction": "above",
    "message": "GBP/USD has crossed 1.30",
    "triggered_at": "2026-05-04T11:42:00Z"
  }
}
```
