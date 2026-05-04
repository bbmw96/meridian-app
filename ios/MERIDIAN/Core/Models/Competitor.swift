import Foundation

struct Competitor: Identifiable, Codable {
    var id: UUID
    var domain: String
    var trafficShare: Double
    var delta: Double
    var currencyAdjustedRevenue: Double
    var targetCurrency: String
    var opportunityScore: Double
    var geographies: [String]

    var deltaFormatted: String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta))%"
    }

    var isGrowing: Bool { delta > 0 }

    var formattedRevenue: String {
        let symbols: [String: String] = [
            "GBP": "£", "USD": "$", "EUR": "€", "JPY": "¥",
            "CHF": "Fr", "AUD": "A$", "CAD": "C$"
        ]
        let symbol = symbols[targetCurrency] ?? targetCurrency + " "
        if currencyAdjustedRevenue >= 1_000_000_000 {
            return "\(symbol)\(String(format: "%.1f", currencyAdjustedRevenue / 1_000_000_000))B"
        } else if currencyAdjustedRevenue >= 1_000_000 {
            return "\(symbol)\(String(format: "%.1f", currencyAdjustedRevenue / 1_000_000))M"
        }
        return "\(symbol)\(String(format: "%.0f", currencyAdjustedRevenue))K"
    }

    static let previewList: [Competitor] = [
        Competitor(
            id: UUID(),
            domain: "etsy.com",
            trafficShare: 0.18,
            delta: 3.4,
            currencyAdjustedRevenue: 890_000_000,
            targetCurrency: "GBP",
            opportunityScore: 72.5,
            geographies: ["US", "UK", "DE", "CA"]
        ),
        Competitor(
            id: UUID(),
            domain: "squarespace.com",
            trafficShare: 0.11,
            delta: -1.2,
            currencyAdjustedRevenue: 410_000_000,
            targetCurrency: "GBP",
            opportunityScore: 58.3,
            geographies: ["US", "AU", "UK"]
        ),
        Competitor(
            id: UUID(),
            domain: "wix.com",
            trafficShare: 0.22,
            delta: 0.8,
            currencyAdjustedRevenue: 1_120_000_000,
            targetCurrency: "GBP",
            opportunityScore: 81.0,
            geographies: ["US", "IL", "UK", "DE", "FR"]
        )
    ]
}
