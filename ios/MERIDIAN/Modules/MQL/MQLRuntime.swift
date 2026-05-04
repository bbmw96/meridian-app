import Foundation
import Observation

struct MQLEntry: Identifiable {
    var id: UUID
    var query: String
    var result: MQLResult?
    var error: String?
    var timestamp: Date
    var isRunning: Bool = false
}

enum MQLResult {
    case scanResult(DomainScanResult)
    case opportunities([Opportunity])
    case creative(Creative)
    case alert(RateAlert)
    case message(String)

    var summary: String {
        switch self {
        case .scanResult(let r): return "Scan: \(r.profile.name) — \(r.profile.formattedTraffic)/mo"
        case .opportunities(let list): return "\(list.count) opportunities found"
        case .creative(let c): return "Creative: \(c.title)"
        case .alert(let a): return "Alert set: \(a.description)"
        case .message(let m): return m
        }
    }
}

@Observable
final class MQLRuntime {
    var history: [MQLEntry] = []
    var isRunning = false

    private let apiClient = APIClient.shared
    private let intelligenceEngine: IntelligenceEngine
    private let opportunityRadar: OpportunityRadar

    init(intelligenceEngine: IntelligenceEngine, opportunityRadar: OpportunityRadar) {
        self.intelligenceEngine = intelligenceEngine
        self.opportunityRadar = opportunityRadar
        loadSampleHistory()
    }

    func execute(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var entry = MQLEntry(id: UUID(), query: trimmed, timestamp: Date(), isRunning: true)
        history.insert(entry, at: 0)

        isRunning = true
        defer { isRunning = false }

        do {
            let result = try await parseAndExecute(trimmed)
            entry.result = result
            entry.isRunning = false
            updateHistory(entry)
        } catch {
            entry.error = error.localizedDescription
            entry.isRunning = false
            updateHistory(entry)
        }
    }

    private func parseAndExecute(_ query: String) async throws -> MQLResult {
        let upper = query.uppercased()

        if upper.hasPrefix("SCAN ") {
            let domain = String(query.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            await intelligenceEngine.scan(domain: domain)
            if let result = intelligenceEngine.currentScan {
                return .scanResult(result)
            }
            throw MQLError.executionFailed("Scan returned no result.")
        }

        if upper.hasPrefix("OPPORTUNITIES") || upper.hasPrefix("SHOW OPPORTUNITIES") {
            await opportunityRadar.refresh()
            return .opportunities(opportunityRadar.opportunities)
        }

        if upper.hasPrefix("ALERT ") {
            let parts = query.components(separatedBy: " ")
            guard parts.count >= 5 else { throw MQLError.syntaxError("Usage: ALERT <PAIR> <above|below> <threshold>") }
            let pair = parts[1].uppercased()
            let directionStr = parts[2].lowercased()
            guard let threshold = Double(parts[3]) else { throw MQLError.syntaxError("Invalid threshold value.") }
            let direction: CurrencyDirection = directionStr == "above" ? .above : .below
            let alert = RateAlert(id: UUID(), pair: pair, threshold: threshold, direction: direction, isActive: true)
            return .alert(alert)
        }

        if upper.hasPrefix("HELP") || upper == "?" {
            return .message(MQLRuntime.helpText)
        }

        let response: MQLAPIResponse = try await apiClient.fetch(.executeMQL(query))
        return .message(response.message ?? "Query executed successfully.")
    }

    private func updateHistory(_ entry: MQLEntry) {
        if let index = history.firstIndex(where: { $0.id == entry.id }) {
            history[index] = entry
        }
    }

    func clearHistory() {
        history.removeAll()
    }

    private func loadSampleHistory() {
        history = [
            MQLEntry(
                id: UUID(),
                query: "SCAN shopify.com",
                result: .scanResult(DomainScanResult.preview),
                timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
            ),
            MQLEntry(
                id: UUID(),
                query: "SHOW OPPORTUNITIES WHERE score > 80",
                result: .opportunities(Opportunity.previewList.filter { $0.opportunityScore > 80 }),
                timestamp: Calendar.current.date(byAdding: .minute, value: -12, to: Date())!
            )
        ]
    }

    static let helpText = """
    MERIDIAN Query Language (MQL) v1.0

    Commands:
      SCAN <domain>                     — Scan a domain for intelligence
      OPPORTUNITIES                     — List all current opportunities
      SHOW OPPORTUNITIES WHERE ...      — Filter opportunities
      ALERT <pair> <above|below> <val>  — Set a currency alert
      HELP                              — Show this help

    Examples:
      SCAN amazon.co.uk
      SHOW OPPORTUNITIES WHERE score > 75
      ALERT GBP/USD above 1.30
    """

    static let sampleQueries = [
        "SCAN amazon.co.uk",
        "SHOW OPPORTUNITIES WHERE score > 80",
        "ALERT GBP/USD above 1.30",
        "OPPORTUNITIES"
    ]
}

enum MQLError: LocalizedError {
    case syntaxError(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .syntaxError(let msg): return "Syntax error: \(msg)"
        case .executionFailed(let msg): return "Execution failed: \(msg)"
        }
    }
}

struct MQLAPIResponse: Decodable {
    var message: String?
    var status: String?
}
