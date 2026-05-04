import Foundation

enum CurrencyDirection: String, Codable, CaseIterable {
    case above
    case below

    var label: LocalizedStringKey {
        switch self {
        case .above: return "Above"
        case .below: return "Below"
        }
    }
}

struct CurrencyRate: Identifiable, Codable {
    var id: String
    var rate: Double
    var previousRate: Double
    var timestamp: Date
    var source: String

    var baseCurrency: String { String(id.prefix(3)) }
    var quoteCurrency: String { String(id.suffix(3)) }

    var changePercent: Double {
        guard previousRate != 0 else { return 0 }
        return ((rate - previousRate) / previousRate) * 100
    }

    var isPositive: Bool { rate >= previousRate }

    var formattedRate: String {
        String(format: "%.4f", rate)
    }

    var formattedChange: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }

    static let previewList: [CurrencyRate] = [
        CurrencyRate(id: "GBP/USD", rate: 1.2734, previousRate: 1.2698, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "GBP/EUR", rate: 1.1621, previousRate: 1.1634, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "EUR/USD", rate: 1.0957, previousRate: 1.0912, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "USD/JPY", rate: 149.82, previousRate: 150.21, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "GBP/JPY", rate: 190.87, previousRate: 190.12, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "EUR/JPY", rate: 164.12, previousRate: 163.88, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "USD/CHF", rate: 0.8891, previousRate: 0.8923, timestamp: Date(), source: "ECB"),
        CurrencyRate(id: "AUD/USD", rate: 0.6521, previousRate: 0.6498, timestamp: Date(), source: "ECB")
    ]
}

struct RateAlert: Identifiable, Codable {
    var id: UUID
    var pair: String
    var threshold: Double
    var direction: CurrencyDirection
    var isActive: Bool

    var description: String {
        "\(pair) \(direction == .above ? "above" : "below") \(String(format: "%.4f", threshold))"
    }

    static let preview = RateAlert(
        id: UUID(),
        pair: "GBP/USD",
        threshold: 1.30,
        direction: .above,
        isActive: true
    )
}
