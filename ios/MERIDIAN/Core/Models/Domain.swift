import Foundation

enum TrafficTrend: String, Codable, CaseIterable {
    case rising
    case stable
    case declining

    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .stable: return "minus"
        case .declining: return "arrow.down.right"
        }
    }
}

enum AdSpendLevel: String, Codable, CaseIterable {
    case none
    case low
    case medium
    case high

    var displayLabel: LocalizedStringKey {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

struct DomainProfile: Identifiable, Codable {
    var id: UUID
    var url: String
    var name: String
    var monthlyTraffic: Int
    var trafficTrend: TrafficTrend
    var topKeywords: [String]
    var geographyBreakdown: [String: Double]
    var estimatedRevenuePounds: Double
    var technologyStack: [String]
    var adSpendSignal: AdSpendLevel
    var lastScanned: Date

    var formattedTraffic: String {
        if monthlyTraffic >= 1_000_000 {
            return String(format: "%.1fM", Double(monthlyTraffic) / 1_000_000)
        } else if monthlyTraffic >= 1_000 {
            return String(format: "%.0fK", Double(monthlyTraffic) / 1_000)
        }
        return "\(monthlyTraffic)"
    }

    static let preview = DomainProfile(
        id: UUID(),
        url: "shopify.com",
        name: "Shopify",
        monthlyTraffic: 142_000_000,
        trafficTrend: .rising,
        topKeywords: ["ecommerce", "online store", "shopify", "dropshipping", "sell online"],
        geographyBreakdown: ["US": 0.42, "UK": 0.12, "CA": 0.09, "AU": 0.07, "DE": 0.06],
        estimatedRevenuePounds: 4_800_000_000,
        technologyStack: ["Ruby on Rails", "React", "MySQL", "Redis", "Cloudflare"],
        adSpendSignal: .high,
        lastScanned: Date()
    )
}

struct DomainScanResult: Codable {
    var profile: DomainProfile
    var competitors: [DomainProfile]

    static let preview = DomainScanResult(
        profile: DomainProfile.preview,
        competitors: [
            DomainProfile(
                id: UUID(),
                url: "woocommerce.com",
                name: "WooCommerce",
                monthlyTraffic: 28_000_000,
                trafficTrend: .stable,
                topKeywords: ["woocommerce", "wordpress ecommerce", "woo"],
                geographyBreakdown: ["US": 0.35, "UK": 0.15, "IN": 0.10],
                estimatedRevenuePounds: 320_000_000,
                technologyStack: ["WordPress", "PHP", "MySQL"],
                adSpendSignal: .medium,
                lastScanned: Date()
            ),
            DomainProfile(
                id: UUID(),
                url: "bigcommerce.com",
                name: "BigCommerce",
                monthlyTraffic: 11_000_000,
                trafficTrend: .declining,
                topKeywords: ["bigcommerce", "b2b ecommerce", "enterprise store"],
                geographyBreakdown: ["US": 0.55, "AU": 0.12, "UK": 0.10],
                estimatedRevenuePounds: 240_000_000,
                technologyStack: ["Node.js", "React", "PostgreSQL"],
                adSpendSignal: .medium,
                lastScanned: Date()
            )
        ]
    )
}
