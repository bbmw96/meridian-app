# MERIDIAN - Global Business Intelligence Operating System
## Design Specification v1.0 | 2026-05-04

---

## 1. Overview

MERIDIAN is a universal mobile-native business intelligence operating system. It unifies three data
domains that have never existed together in a single application on any platform:

1. **Competitive intelligence** (traffic, keywords, firmographic signals - inspired by SimilarWeb)
2. **Currency-aware market analysis** (real-time FX rates, purchasing power parity, rate alerts - inspired by XE.com)
3. **AI creative generation** (multi-model ad and content production - inspired by Zeely AI)

A custom query language, **MQL (MERIDIAN Query Language)**, ties all three engines together with a
unified, composable syntax that any user can write in plain English.

**Platform**: iOS (iPhone-first, designed to iPad scale)
**Target**: Universal - no persona restriction; any person or business querying global markets
**Languages supported**: 100+ (full localisation, RTL support)
**App Store status**: No equivalent exists on App Store, Google Play, or Microsoft Store

---

## 2. Problem Statement

| Gap | Detail |
|---|---|
| Intelligence tools are desktop-only | SimilarWeb, Semrush, Ahrefs have no mobile-native intelligence experience |
| Creative tools have no market context | Zeely, Canva produce creatives with no awareness of competitor traffic or market FX |
| Currency tools are isolated | XE, Wise show FX data but have no connection to competitive or creative intelligence |
| No universal query interface | No app lets a user write one query that returns competitor data + FX-adjusted revenue + an AI creative in the same result |

MERIDIAN solves all four gaps simultaneously.

---

## 3. Core Modules

### 3.1 Competitive Intelligence Engine
- Domain scan: traffic estimate, keywords, geography breakdown, technology stack, ad spend signals
- Competitor map: discover top 10 competitors, rank by traffic delta
- IP intelligence overlay: identify company-level visitor signals (B2B layer)
- Historical trend: 90-day rolling comparison
- Data sources: aggregated public web signals, scraping, ML estimation models

### 3.2 Currency Intelligence Engine
- 220+ currencies via live rate feed (XE API-compatible protocol)
- Currency-adjusted competitor revenue estimates (unique: no other tool does this)
- Rate alerts with configurable thresholds, push notifications
- Purchasing power parity calculations for market sizing
- 28-year historical rate data

### 3.3 AI Creative Arsenal
- URL-to-creative pipeline: paste a competitor URL, receive an ad
- Multi-model orchestration: routes to best available model (Claude, GPT-4V, Gemini, Stable Diffusion, Kling)
- Localised output: generate creative in any of 100+ languages with currency symbol correction
- Frameworks: AIDA, PAS, Before-After-Bridge built into script generation
- Platforms: Meta, TikTok, Google Ads, LinkedIn, Snapchat, Pinterest formats

### 3.4 MQL - MERIDIAN Query Language
A purpose-built DSL for unified business intelligence queries. Compiles to REST API calls, SQL,
and ML inference tasks. Runs natively on-device via a Swift-bridged Rust WASM module.

Syntax example:
```mql
SCAN domain "competitor.com"
  COMPARE competitors TOP 10
  WHERE traffic.monthly > 100000
  AND geography IN ["GB", "DE", "JP"]
  CONVERT revenue TO "GBP"
  GENERATE ad STYLE "static" LANGUAGE "en-GB" PLATFORM "instagram"
  RANK BY opportunity_score DESC
```

Grammar: 22 keywords, 8 operators, 4 literal types, full type inference.
Implementation: Rust (lexer, recursive-descent parser, AST, type checker, multi-target codegen).
Bridge: Swift Package via C FFI, compiled to WASM for portability.

### 3.5 Global Opportunity Radar
- AI-powered signal correlation across all three engines
- Detects: competitor traffic gaps, FX stability windows, underserved markets
- Opportunity score (0-100) computed by Python ML service
- Push alerts when score crosses user-defined threshold
- Map visualisation of global opportunities

### 3.6 Globalisation Engine
- 100+ language localisations via `.lproj` bundles
- Dynamic content translation via on-device Core ML model (100MB, no network required)
- RTL layout support (Arabic, Hebrew, Urdu, Persian, Syriac)
- Currency symbol and number formatting per locale
- Date/time formatting per locale and calendar system

---

## 4. Architecture

### 4.1 iOS App (Swift 6 + SwiftUI)
```
MERIDIANApp.swift           - app entry, scene lifecycle
AppState.swift              - global observable state
Modules/
  Intelligence/             - competitive intelligence engine
  Currency/                 - FX engine
  Creative/                 - AI creative arsenal
  MQL/                      - query language runtime bridge
  Radar/                    - opportunity detection
  Globalisation/            - i18n engine
Core/
  Network/                  - API + GraphQL + WebSocket clients
  Storage/                  - Core Data + CloudKit persistence
  Models/                   - shared data models
  Extensions/               - SwiftUI extensions
UI/
  Dashboard/                - home feed
  Scanner/                  - domain intelligence view
  Currency/                 - FX view
  Creative/                 - ad generator view
  MQLTerminal/              - query language REPL
  Radar/                    - opportunity map view
  Settings/                 - preferences
  Components/               - shared UI primitives
Resources/
  Localisation/             - 100+ .lproj bundles
```

### 4.2 Custom Language: MQL (Rust)
```
lexer.rs      - tokenises MQL source text
token.rs      - token enum definitions
parser.rs     - recursive-descent parser, produces AST
ast.rs        - abstract syntax tree node types
typechecker.rs - type inference and semantic validation
codegen/
  api_codegen.rs  - emits REST API call sequences
  sql_codegen.rs  - emits SQL for analytics backend
  ml_codegen.rs   - emits ML inference task descriptors
runtime.rs    - executes compiled instruction streams
```

### 4.3 Backend Services
| Service | Language | Role |
|---|---|---|
| gateway | Go 1.22 | High-concurrency API gateway, rate limiting, auth |
| intelligence | Python 3.12 | ML models, data processing, competitor analysis |
| bff | TypeScript / Node 22 | GraphQL BFF, schema stitching, iOS client interface |
| realtime | Elixir 1.17 / Phoenix 1.8 | WebSocket push, rate alert delivery, live signals |

### 4.4 Data Infrastructure
- PostgreSQL 16: structured business intelligence data
- ClickHouse: high-speed analytics queries
- Redis 7: rate caching, session state
- Pinecone: vector embeddings for semantic competitor matching
- Kafka: event streaming between services

### 4.5 Infrastructure
- Docker Compose for local development
- Kubernetes (production)
- Terraform for cloud provisioning

---

## 5. Technology Languages Used

| Language | Role |
|---|---|
| Swift 6 | iOS app, UI, module orchestration |
| Rust | MQL compiler, WASM module, data transformation |
| Python 3.12 | ML models, intelligence processing, NLP |
| Go 1.22 | API gateway, high-concurrency routing |
| TypeScript | GraphQL BFF, type-safe API layer |
| Elixir | Real-time push, Phoenix Channels |
| WebAssembly | Cross-platform MQL runtime embedded in iOS |
| C (FFI) | Swift-to-Rust bridge layer |
| SQL | Analytics queries (ClickHouse dialect) |
| HCL (Terraform) | Infrastructure as code |
| MQL | Custom query language (MERIDIAN Query Language) |

---

## 6. MQL Language Specification

### Keywords (22)
`SCAN` `COMPARE` `WHERE` `AND` `OR` `NOT` `IN` `GENERATE` `FIND` `ALERT` `ANALYSE`
`CONVERT` `USING` `FOR` `FROM` `RANK` `LIMIT` `BY` `NOTIFY` `WITH` `AS` `TOP`

### Operators (8)
`>` `<` `>=` `<=` `=` `!=` `%` `.`

### Literal Types (4)
- String: `"en-GB"`, `"competitor.com"`
- Integer: `100000`, `10`
- Float: `0.8`, `5.2`
- List: `["GB", "DE", "JP"]`

### Sort Directions
`ASC` `DESC`

### Reserved Identifiers
`traffic.monthly` `traffic.trend` `traffic.change` `revenue` `geography` `currency`
`rate.blended` `opportunity_score` `competitor` `domain` `market` `technology`

### Example Queries
```mql
-- Basic domain scan
SCAN domain "apple.com"

-- Competitive analysis with currency adjustment
SCAN domain "shopify.com"
  COMPARE competitors TOP 5
  WHERE geography IN ["GB", "DE"]
  CONVERT revenue TO "GBP"

-- Full pipeline: intelligence + creative
FIND opportunities
  WHERE market = "saas"
  AND currency.stability > 0.9
  RANK BY opportunity_score DESC
  LIMIT 10
  GENERATE ad STYLE "ugc-video" LANGUAGE "en-GB" FRAMEWORK "PAS"

-- Rate alert
ALERT WHEN
  currency "USD/GBP" rate.change > 3%
  NOTIFY via "push"
  WITH message "GBP rate movement detected"
```

---

## 7. Unique Value Proposition (App Store Differentiation)

No app on any platform currently:
1. Combines web competitive intelligence + AI creative generation + currency-adjusted market analysis
2. Provides a query language (MQL) for unified business intelligence on a mobile device
3. Shows competitor estimated revenue converted to the user's local currency in real time
4. Generates AI ad creatives targeting a specific competitor's audience with market-aware copy
5. Delivers global opportunity detection by correlating traffic gaps, FX windows, and competitor signals

MERIDIAN is the first and only Global Business Intelligence Operating System for mobile.

---

## 8. Security Considerations
- All API keys stored in iOS Keychain (never in UserDefaults or plist)
- Network calls over TLS 1.3 only
- MQL input sanitised before execution (no arbitrary code paths)
- GDPR-compliant: no personal data stored; all intelligence is aggregate/estimated
- OWASP Mobile Top-10 reviewed against all modules

---

## 9. Design Approved
User confirmed: universal target, build immediately, no persona restriction, full complexity.
Date: 2026-05-04
