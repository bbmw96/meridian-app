# MERIDIAN

**Global Business Intelligence Operating System**

---

## What is MERIDIAN

MERIDIAN is a professional-grade business intelligence platform for iOS, engineered to give founders, analysts, marketers, and operators a real-time command centre for global market data. It consolidates website traffic analytics, competitive intelligence, currency conversion, creative content generation, and a custom query language into a single, cohesive application that works anywhere in the world.

Where legacy tools force you to juggle four or five separate subscriptions, each with their own interface and data model, MERIDIAN unifies these capabilities into a coherent operating system. Every feature is connected: a domain scan feeds directly into the Opportunity Radar, currency data contextualises market scores, and the Creative Arsenal uses intelligence signals to inform content strategy. The result is an application that thinks in terms of business outcomes rather than isolated data points.

MERIDIAN is built on a polyglot microservices architecture, a custom MQL (MERIDIAN Query Language) compiler written in Rust, real-time WebSocket data delivery via Elixir/Phoenix, and a GraphQL BFF (Backend for Frontend) that aggregates six independent services into a single cohesive API. The iOS client is built entirely in SwiftUI and targets iOS 17 and above, with full localisation coverage across 30 languages.

---

## Why MERIDIAN is Unique

| Capability | SimilarWeb | XE.com | Zeely AI | MERIDIAN |
|---|---|---|---|---|
| Website traffic analytics | Yes | No | No | Yes |
| Competitive intelligence | Yes | No | Partial | Yes |
| Keyword and SEO data | Yes | No | No | Yes |
| Live currency conversion | No | Yes | No | Yes |
| Currency rate alerts | No | Yes | No | Yes |
| AI creative generation | No | No | Yes | Yes |
| Custom query language | No | No | No | Yes |
| Opportunity scoring | No | No | Partial | Yes |
| Offline AI (on-device) | No | No | No | Yes |
| 30-language localisation | No | Partial | No | Yes |
| Native iOS app | No | Yes | Yes | Yes |
| Open architecture | No | No | No | Yes |

MERIDIAN does not merely combine these products. It synthesises their outputs into a unified intelligence layer that produces insights no individual tool can generate alone.

---

## Core Features

**[*] Intelligence Scanner**
Scan any domain and receive a comprehensive breakdown of monthly traffic, top organic keywords, geographic distribution, and direct competitors. Data is sourced from a proprietary aggregation pipeline backed by ClickHouse analytics and enriched by the intelligence microservice.

**[>] Opportunity Radar**
A continuously updating feed of scored market opportunities, ranked by a composite index that weighs traffic trajectory, keyword difficulty, geographic demand, and competitive saturation. Each opportunity card links directly to a pre-populated scanner result.

**[~] Currency Intelligence**
Real-time currency conversion across 170+ pairs with historical charting, rate-change alerts delivered via push notification, and contextual overlays that show how exchange-rate movements affect market opportunity scores in foreign geographies.

**[+] Creative Arsenal**
An AI-powered content generation engine with support for six frameworks (AIDA, PAS, BAB, STAR, 4Cs, FAB), twelve platforms, and any target language. Outputs are structured creative briefs, ad copy, landing page headlines, and email sequences, each calibrated to the brand voice and market context.

**[#] MQL Terminal**
A first-class query interface for MERIDIAN Query Language, a domain-specific language designed for business intelligence queries. MQL supports domain lookups, market filters, currency expressions, and composite scoring functions with a syntax that is readable without prior training.

**[!] Real-Time Data Layer**
All data in MERIDIAN is live. WebSocket connections via the Elixir realtime service push market movements, scan completions, and currency ticks directly to the iOS client without polling. Offline mode falls back gracefully to cached intelligence with clear staleness indicators.

---

## MQL Query Language

MQL (MERIDIAN Query Language) is a declarative query language for business intelligence operations. It is compiled by a Rust-based compiler and executed by the intelligence service.

### Syntax Overview

```mql
-- Find high-traffic domains in a given sector
SCAN DOMAIN "competitor.com"
  RETURN traffic, keywords, geography
  WHERE monthly_traffic > 100000
  FORMAT detailed

-- Score market opportunities by geography
RADAR OPPORTUNITIES
  IN MARKET "saas-productivity"
  WHERE geography IN ("GB", "DE", "FR", "NL")
    AND opportunity_score > 72
  ORDER BY opportunity_score DESC
  LIMIT 20

-- Currency-adjusted market sizing
CURRENCY CONVERT
  FROM "USD" TO "GBP"
  AMOUNT 1500000
  AS OF "2026-05-01"
  ANNOTATE market_context FOR MARKET "uk-fintech"
```

MQL supports:
- `SCAN` - domain and URL analysis
- `RADAR` - opportunity discovery and scoring
- `CURRENCY` - exchange operations with market annotation
- `CREATIVE` - content brief generation with framework selection
- `COMPARE` - side-by-side competitive analysis

Full language specification is available in `docs/mql-spec.md`.

---

## Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| iOS client | SwiftUI, Swift 5.10 | Native performance, full iOS 17 API access, declarative UI |
| MQL compiler | Rust | Memory safety, deterministic performance, WASM portability |
| API gateway | Go 1.22 | Low-latency HTTP routing, efficient concurrency with goroutines |
| Intelligence service | Python 3.12, FastAPI | Rich ML ecosystem, async I/O, Pydantic validation |
| GraphQL BFF | Node.js 22, TypeScript | Schema composition, Apollo Federation, rapid iteration |
| Real-time service | Elixir 1.17, Phoenix | Actor model, fault tolerance, 2M+ concurrent WebSocket connections |
| Primary database | PostgreSQL 16 | ACID compliance, JSONB flexibility, mature ecosystem |
| Analytics store | ClickHouse 24 | Columnar storage, sub-second aggregation over billions of rows |
| Cache and pub/sub | Redis 7 | Microsecond latency, Streams for event sourcing |
| Message bus | Apache Kafka | Durable event log, replay capability, decoupled services |
| Infrastructure | Terraform, AWS EKS | Reproducible infrastructure, auto-scaling Kubernetes |
| CI/CD | GitHub Actions | Native integration, matrix builds, ECR push on tag |

---

## Architecture Diagram

```
+---------------------------+
|      iOS Client            |
|   (SwiftUI / Swift 5.10)   |
+---------------------------+
            |
            | GraphQL / WebSocket
            v
+---------------------------+
|      BFF (Node.js 22)      |
|    Port 4000 / GraphQL     |
+---------------------------+
       |           |
       |           | WebSocket events
       v           v
+----------+  +------------------+
|  Gateway |  |  Realtime        |
|  (Go)    |  |  (Elixir/Phoenix)|
|  :8080   |  |  :4001           |
+----------+  +------------------+
    |    |           |
    |    |     +-----+-----+
    |    |     | Redis     |
    |    |     | :6379     |
    |    |     +-----+-----+
    |    |           |
    |    +------+    | Events
    |           |    v
    v           v  +-------+
+----------+ +--------+  | Kafka |
|Intelligence| |Postgres|  | :9092 |
|(Python)  | |  :5432 |  +-------+
|  :8001   | +--------+
+----------+
    |
    v
+-----------+
| ClickHouse|
|   :8123   |
+-----------+
```

---

## Getting Started

### Prerequisites

- Docker Desktop 4.28 or later
- Docker Compose v3.8 support
- 8 GB RAM allocated to Docker (16 GB recommended)
- Xcode 16.0 or later (for iOS development)
- Rust 1.78 or later (for MQL compiler)
- Go 1.22 or later (for gateway development)

### Clone

```bash
git clone https://github.com/your-org/meridian.git
cd meridian
```

### Environment Setup

Copy the example environment file and fill in the required values:

```bash
cp .env.example .env
```

Required variables:

```
POSTGRES_USER=meridian
POSTGRES_PASSWORD=<your-password>
JWT_SECRET=<your-jwt-secret-min-32-chars>
SECRET_KEY_BASE=<elixir-secret-min-64-chars>
```

### Run with Docker Compose

```bash
docker compose up --build
```

Services will be available at:

| Service | URL |
|---|---|
| GraphQL BFF | http://localhost:4000/graphql |
| GraphQL Playground | http://localhost:4000/graphql |
| Gateway | http://localhost:8080 |
| Intelligence API | http://localhost:8001/docs |
| Realtime WebSocket | ws://localhost:4001/socket |
| ClickHouse HTTP | http://localhost:8123 |

Run database migrations:

```bash
docker compose exec gateway ./gateway migrate
```

---

## iOS Development

### Requirements

- macOS Ventura 13.5 or later
- Xcode 16.0 or later
- iOS 17.0 SDK
- CocoaPods or Swift Package Manager (SPM is used by default)

### Setup

1. Open `ios/MERIDIAN.xcodeproj` in Xcode.
2. Select your development team under **Signing and Capabilities**.
3. Update `ios/MERIDIAN/Config/Config.plist` with local service URLs:

```xml
<key>BFFEndpoint</key>
<string>http://localhost:4000/graphql</string>
<key>RealtimeEndpoint</key>
<string>ws://localhost:4001/socket</string>
```

4. Build and run on a simulator or physical device running iOS 17 or later.

### Running Tests

```bash
xcodebuild test \
  -project ios/MERIDIAN.xcodeproj \
  -scheme MERIDIAN \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## MQL Compiler

The MQL compiler is written in Rust and lives in `compiler/`. It parses MQL source text, produces an AST, runs semantic analysis, and emits an intermediate representation consumed by the intelligence service.

### Build

```bash
cd compiler
cargo build --release
```

The compiled binary is at `compiler/target/release/mqlc`.

### Test

```bash
cargo test
```

### Run a Query

```bash
echo 'SCAN DOMAIN "example.com" RETURN traffic, keywords' | ./target/release/mqlc
```

### WASM Build (for in-app offline evaluation)

```bash
cargo build --target wasm32-unknown-unknown --release
```

The WASM binary is embedded into the iOS app bundle and loaded via WKWebView for offline MQL evaluation.

---

## Backend Services

Each service can be run independently during development.

### Gateway (Go)

```bash
cd services/gateway
go run ./cmd/gateway
```

Environment: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`

### Intelligence Service (Python)

```bash
cd services/intelligence
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

Environment: `DATABASE_URL`, `REDIS_URL`, `OPENAI_API_KEY`

### BFF (Node.js)

```bash
cd services/bff
npm install
npm run dev
```

Environment: `GATEWAY_URL`, `INTELLIGENCE_URL`, `REDIS_URL`

### Realtime Service (Elixir)

```bash
cd services/realtime
mix deps.get
mix phx.server
```

Environment: `REDIS_URL`, `KAFKA_BROKERS`, `SECRET_KEY_BASE`

---

## Environment Variables

### Gateway

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `REDIS_URL` | Yes | Redis connection URL |
| `JWT_SECRET` | Yes | Secret for JWT signing (min. 32 chars) |
| `ENVIRONMENT` | No | `development` or `production` (default: `development`) |
| `LOG_LEVEL` | No | `debug`, `info`, `warn`, `error` (default: `info`) |

### Intelligence Service

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string (asyncpg driver) |
| `REDIS_URL` | Yes | Redis connection URL |
| `OPENAI_API_KEY` | No | OpenAI key for creative generation |
| `ANTHROPIC_API_KEY` | No | Anthropic key for Claude-powered features |
| `ENVIRONMENT` | No | Deployment environment |

### BFF

| Variable | Required | Description |
|---|---|---|
| `GATEWAY_URL` | Yes | Internal URL of the gateway service |
| `INTELLIGENCE_URL` | Yes | Internal URL of the intelligence service |
| `REDIS_URL` | Yes | Redis connection URL for session storage |
| `PORT` | No | HTTP port (default: `4000`) |
| `NODE_ENV` | No | Node environment (default: `development`) |

### Realtime Service

| Variable | Required | Description |
|---|---|---|
| `REDIS_URL` | Yes | Redis connection URL |
| `KAFKA_BROKERS` | Yes | Comma-separated Kafka broker addresses |
| `SECRET_KEY_BASE` | Yes | Phoenix secret key base (min. 64 chars) |
| `PORT` | No | HTTP/WebSocket port (default: `4001`) |

---

## Localisation

MERIDIAN ships with full localisation support across 30 languages, covering over 5 billion native speakers worldwide.

### Supported Languages

Arabic, Chinese (Simplified), Chinese (Traditional), Czech, Danish, Dutch, English, Finnish, French, German, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Korean, Malay, Norwegian, Persian, Polish, Portuguese (Brazil), Romanian, Russian, Spanish, Swedish, Thai, Turkish, Ukrainian, Vietnamese.

RTL (right-to-left) layout is fully supported for Arabic, Hebrew, and Persian, using SwiftUI's native layout mirroring.

### File Structure

Localisation strings are stored in Apple `.strings` format:

```
ios/MERIDIAN/Resources/
  en.lproj/Localizable.strings      (base - English)
  ar.lproj/Localizable.strings      (Arabic, RTL)
  zh-Hans.lproj/Localizable.strings (Simplified Chinese)
  ...
```

### Adding a New Language

1. Create a new directory: `ios/MERIDIAN/Resources/<locale>.lproj/`
2. Copy `en.lproj/Localizable.strings` into the new directory.
3. Translate every value. Do not translate key names.
4. Add the locale to the `CFBundleLocalizations` array in `ios/MERIDIAN/Info.plist`.
5. If the language is RTL, no additional code is required. SwiftUI handles layout mirroring automatically.
6. Run the localisation test suite:

```bash
xcodebuild test \
  -project ios/MERIDIAN.xcodeproj \
  -scheme MERIDIANLocalisationTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The test suite checks that every key in the base English file is present in every translated file, and that no values have been left untranslated.

---

## API Reference

The primary entry point for all API operations is the GraphQL playground, available when the BFF is running:

```
http://localhost:4000/graphql
```

The GraphQL schema is introspectable. All queries, mutations, and subscriptions are documented inline via schema descriptions.

Key GraphQL operations:

- `query scanDomain(domain: String!)` - trigger and retrieve domain intelligence
- `query opportunityRadar(filters: RadarFilters)` - scored opportunity feed
- `mutation convertCurrency(from: String!, to: String!, amount: Float!)` - currency conversion
- `mutation generateCreative(input: CreativeInput!)` - AI creative generation
- `subscription marketUpdates` - real-time market data via WebSocket
- `subscription currencyTick(pair: String!)` - live exchange rate stream

REST endpoints on the gateway (`http://localhost:8080`) are documented via OpenAPI at:

```
http://localhost:8080/docs
```

---

## Licence

MIT Licence

Copyright (c) 2026 MERIDIAN

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicence, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Acknowledgements

MERIDIAN draws methodological inspiration from three category-defining products:

- **SimilarWeb** - pioneered the market for web traffic intelligence and competitive benchmarking at scale. MERIDIAN's Intelligence Scanner is informed by their approach to multi-signal traffic estimation.
- **XE.com** - set the standard for consumer-grade currency intelligence, rate alerting, and historical FX data. MERIDIAN's Currency Intelligence module builds on their model of contextualising exchange-rate data for practical decision-making.
- **Zeely AI** - demonstrated the value of AI-assisted creative generation in a mobile-first context. MERIDIAN's Creative Arsenal extends this with multi-framework, multi-language, and intelligence-contextualised content generation.

MERIDIAN exists to synthesise what these tools do individually into a single, coherent operating system for global business intelligence.
