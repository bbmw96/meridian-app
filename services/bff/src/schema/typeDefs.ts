export const typeDefs = /* GraphQL */ `
  scalar JSON
  scalar DateTime

  type DomainProfile {
    domain: String!
    title: String
    description: String
    monthlyTraffic: Int!
    estimatedRevenueGBP: Float
    keywords: [String!]!
    geography: JSON!
    backlink_count: Int!
    domain_age_days: Int!
    tld: String!
    technologies: [String!]!
    social_signals: JSON!
    traffic_estimate: TrafficEstimate
    cached: Boolean!
    scanned_at: DateTime!
  }

  type TrafficEstimate {
    monthly_visits: Int!
    confidence: Float!
    lower_bound: Int!
    upper_bound: Int!
    methodology: String!
  }

  type Competitor {
    domain: String!
    similarity_score: Float!
    monthly_traffic: Int!
    shared_keywords: [String!]!
    traffic_delta_percent: Float!
    estimated_revenue_gbp: Float
  }

  type CurrencyRate {
    pair: String!
    base_currency: String!
    quote_currency: String!
    rate: Float!
    change_percent: Float
    timestamp: DateTime!
  }

  type RateAlert {
    id: ID!
    user_id: String!
    pair: String!
    threshold_rate: Float!
    direction: AlertDirection!
    is_active: Boolean!
    created_at: DateTime!
    triggered_at: DateTime
  }

  enum AlertDirection {
    ABOVE
    BELOW
  }

  type Creative {
    id: ID!
    format: String!
    platform: String!
    title: String!
    body: String!
    headline: String
    call_to_action: String
    dimensions: CreativeDimensions
    template_used: String!
    generated_at: DateTime!
    provider: String!
    model: String!
  }

  type CreativeDimensions {
    width: Int!
    height: Int!
    unit: String!
  }

  type Opportunity {
    id: ID!
    title: String!
    description: String!
    score: Float!
    market: String!
    geography: String!
    sector: String
    traffic_gap: Float!
    fx_stability: Float!
    competitor_weakness: Float!
    market_growth: Float!
    estimated_revenue_gbp: Float
    confidence: Float!
    discovered_at: DateTime!
  }

  type ScanResult {
    domain: String!
    profile: DomainProfile!
  }

  type OpportunityListResult {
    opportunities: [Opportunity!]!
    count: Int!
  }

  type CreativeResult {
    creative: Creative!
  }

  type AlertResult {
    alert: RateAlert!
    message: String!
  }

  type MessageResult {
    message: String!
    data: JSON
  }

  union MQLResult = ScanResult | OpportunityListResult | CreativeResult | AlertResult | MessageResult

  type Query {
    scanDomain(domain: String!): DomainProfile!
    getCompetitors(domain: String!, limit: Int): [Competitor!]!
    getRates(pairs: [String!]): [CurrencyRate!]!
    getOpportunities(
      market: String
      geography: String
      minScore: Float
      maxResults: Int
    ): [Opportunity!]!
  }

  type Mutation {
    generateCreative(input: CreativeInput!): Creative!
    executeMQL(query: String!): MQLResult!
    createAlert(input: AlertInput!): RateAlert!
    deleteAlert(id: ID!): Boolean!
  }

  input CreativeInput {
    format: String!
    platform: String!
    industry: String!
    brand_name: String!
    tone: String
    keywords: [String!]
    template: String
    constraints: JSON
  }

  input AlertInput {
    pair: String!
    threshold_rate: Float!
    direction: AlertDirection!
  }
`;
