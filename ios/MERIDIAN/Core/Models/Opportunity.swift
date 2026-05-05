import Foundation

struct Opportunity: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var market: String
    var geography: String
    var opportunityScore: Double
    var currencyStability: Double
    var trafficGap: Double
    var estimatedRevenueGBP: Double
    var discoveredAt: Date
    var isNew: Bool
    var isPinned: Bool = false

    var scoreColour: String {
        switch opportunityScore {
        case 80...: return "meridianGreen"
        case 60..<80: return "meridianGold"
        default: return "meridianRed"
        }
    }

    var formattedRevenue: String {
        if estimatedRevenueGBP >= 1_000_000 {
            return "£\(String(format: "%.1f", estimatedRevenueGBP / 1_000_000))M"
        } else if estimatedRevenueGBP >= 1_000 {
            return "£\(String(format: "%.0f", estimatedRevenueGBP / 1_000))K"
        }
        return "£\(String(format: "%.0f", estimatedRevenueGBP))"
    }

    static let previewList: [Opportunity] = [
        Opportunity(
            id: UUID(),
            title: "DACH E-Commerce Gap",
            description: "German-speaking markets show 34% unmet demand for English-first DTC brands. Currency stability is high and CPC costs are 40% below UK benchmark.",
            market: "E-Commerce",
            geography: "DE",
            opportunityScore: 91.2,
            currencyStability: 0.94,
            trafficGap: 0.34,
            estimatedRevenueGBP: 4_200_000,
            discoveredAt: Date(),
            isNew: true
        ),
        Opportunity(
            id: UUID(),
            title: "FinTech SEO Arbitrage - SE Asia",
            description: "Singapore and Malaysia show rising search intent for UK-regulated fintech with virtually no local competition on English-language terms.",
            market: "FinTech",
            geography: "SG",
            opportunityScore: 84.7,
            currencyStability: 0.88,
            trafficGap: 0.51,
            estimatedRevenueGBP: 1_800_000,
            discoveredAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            isNew: true
        ),
        Opportunity(
            id: UUID(),
            title: "SaaS Expansion - Nordics",
            description: "Nordic B2B SaaS buyers are actively searching for alternatives to US-domiciled tools due to data residency concerns. GBP/SEK is stable.",
            market: "SaaS",
            geography: "SE",
            opportunityScore: 77.3,
            currencyStability: 0.79,
            trafficGap: 0.28,
            estimatedRevenueGBP: 920_000,
            discoveredAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
            isNew: false
        ),
        Opportunity(
            id: UUID(),
            title: "DTC Health - UAE",
            description: "UAE consumers show 6x YoY growth in health product searches. Low local competition, strong USD peg provides currency certainty.",
            market: "Health",
            geography: "AE",
            opportunityScore: 68.9,
            currencyStability: 0.96,
            trafficGap: 0.44,
            estimatedRevenueGBP: 640_000,
            discoveredAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            isNew: false
        )
    ]
}
