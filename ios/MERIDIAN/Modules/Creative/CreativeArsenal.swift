import Foundation
import Observation

@Observable
final class CreativeArsenal {
    var generatedCreatives: [Creative] = []
    var isGenerating = false
    var lastError: String?

    private let apiClient = APIClient.shared
    private let scanner = DomainScanner()

    func generate(
        fromURL url: String,
        platform: CreativePlatform,
        format: CreativeFormat,
        language: String,
        framework: CreativeFramework,
        currency: String
    ) async throws -> Creative {
        let domain = scanner.normalise(input: url)

        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        let request = CreativeRequest(
            url: domain,
            platform: platform.rawValue,
            format: format.rawValue,
            language: language,
            currency: currency,
            framework: framework.rawValue
        )

        do {
            let creative: Creative = try await apiClient.fetch(.generateCreative(request))
            generatedCreatives.insert(creative, at: 0)
            if generatedCreatives.count > 50 {
                generatedCreatives = Array(generatedCreatives.prefix(50))
            }
            return creative
        } catch {
            lastError = error.localizedDescription
            let mock = buildMockCreative(
                url: domain,
                platform: platform,
                format: format,
                language: language,
                framework: framework,
                currency: currency
            )
            generatedCreatives.insert(mock, at: 0)
            return mock
        }
    }

    func remove(id: UUID) {
        generatedCreatives.removeAll { $0.id == id }
    }

    private func buildMockCreative(
        url: String,
        platform: CreativePlatform,
        format: CreativeFormat,
        language: String,
        framework: CreativeFramework,
        currency: String
    ) -> Creative {
        let domainName = scanner.extractDomainName(from: url)
        let currencySymbol = currencySymbol(for: currency)

        let body: String
        switch framework {
        case .aida:
            body = "Attention: \(domainName) is growing 34% faster than its category average.\n\nInterest: MERIDIAN's intelligence layer identified 12 untapped keyword clusters across 6 markets — all with less than 3 competitors.\n\nDesire: Brands using these gaps report \(currencySymbol)2.4M in incremental revenue within 90 days.\n\nAction: Start your free MERIDIAN scan today."
        case .pas:
            body = "Problem: You're watching competitors take market share — but you don't know which markets, which keywords, or which ad channels to target.\n\nAgitation: Every day without intelligence is revenue left on the table. Your competitors already have this data.\n\nSolution: MERIDIAN scans any domain in seconds and surfaces every exploitable gap — traffic, keywords, geography, ad spend. All in one place."
        case .beforeAfterBridge:
            body = "Before: Guessing which markets to enter. Spending ad budget on keywords you think work. Watching competitors grow and not knowing why.\n\nAfter: Real intelligence. Confirmed traffic gaps. Currency-adjusted revenue forecasts. Competitor ad spend signals.\n\nBridge: MERIDIAN — the business intelligence OS for global brands."
        }

        return Creative(
            id: UUID(),
            title: "Intelligence-Led Growth for \(domainName)",
            body: body,
            platform: platform,
            format: format,
            language: language,
            currency: currency,
            framework: framework,
            generatedAt: Date(),
            imageURL: nil
        )
    }

    private func currencySymbol(for code: String) -> String {
        let symbols: [String: String] = [
            "GBP": "£", "USD": "$", "EUR": "€", "JPY": "¥",
            "CHF": "Fr", "AUD": "A$", "CAD": "C$"
        ]
        return symbols[code] ?? code + " "
    }
}
