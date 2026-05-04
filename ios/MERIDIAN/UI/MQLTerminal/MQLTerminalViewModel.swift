import SwiftUI

@Observable
final class MQLTerminalViewModel {

    var currentQuery: String = ""
    var isRunning: Bool = false
    var showExamples: Bool = false

    private let mqlRuntime: MQLRuntime

    init(mqlRuntime: MQLRuntime) {
        self.mqlRuntime = mqlRuntime
    }

    var history: [MQLEntry] {
        mqlRuntime.history.reversed()
    }

    func run() async {
        let query = currentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isRunning = true
        await mqlRuntime.execute(query: query)
        isRunning = false
    }

    func loadExample(_ example: MQLExample) {
        currentQuery = example.query
        showExamples = false
    }

    func rerun(_ entry: MQLEntry) {
        currentQuery = entry.query
    }

    func clear() {
        currentQuery = ""
    }

    var examples: [MQLExample] {
        [
            MQLExample(
                title: "Scan a domain",
                query: "SCAN domain \"shopify.com\""
            ),
            MQLExample(
                title: "Competitor analysis with FX",
                query: """
                SCAN domain "etsy.com"
                  COMPARE competitors TOP 5
                  WHERE geography IN ["GB", "DE"]
                  CONVERT revenue TO "GBP"
                  RANK BY opportunity_score DESC
                """
            ),
            MQLExample(
                title: "Find market opportunities",
                query: """
                FIND opportunities
                  WHERE market = "saas"
                  AND currency.stability > 0.9
                  RANK BY opportunity_score DESC
                  LIMIT 10
                """
            ),
            MQLExample(
                title: "Generate an ad",
                query: """
                GENERATE ad
                  FOR domain "competitor.com"
                  STYLE "static"
                  LANGUAGE "en-GB"
                  CURRENCY "GBP"
                  PLATFORM "instagram"
                  FRAMEWORK "AIDA"
                """
            ),
            MQLExample(
                title: "Set a rate alert",
                query: """
                ALERT WHEN
                  currency "USD/GBP" rate.change > 3%
                  NOTIFY via "push"
                  WITH message "GBP rate movement detected"
                """
            ),
        ]
    }
}

struct MQLExample: Identifiable {
    let id = UUID()
    let title: String
    let query: String
}
