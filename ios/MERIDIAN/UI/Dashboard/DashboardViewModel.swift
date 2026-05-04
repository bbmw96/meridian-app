import Foundation
import Observation

enum FeedItem: Identifiable {
    case opportunity(Opportunity)
    case domain(DomainProfile)
    case rate(CurrencyRate)

    var id: String {
        switch self {
        case .opportunity(let o): return "opp_\(o.id)"
        case .domain(let d): return "domain_\(d.id)"
        case .rate(let r): return "rate_\(r.id)"
        }
    }
}

@Observable
final class DashboardViewModel {
    var currencyTicker: [CurrencyRate] = []
    var feedItems: [FeedItem] = []
    var hasNewData = false

    private(set) var intelligenceEngine: IntelligenceEngine
    private(set) var currencyEngine: CurrencyEngine
    private(set) var opportunityRadar: OpportunityRadar

    private let majorPairs = ["GBP/USD", "GBP/EUR", "EUR/USD", "USD/JPY", "GBP/JPY", "USD/CHF", "AUD/USD", "USD/CAD"]

    init(
        intelligenceEngine: IntelligenceEngine,
        currencyEngine: CurrencyEngine,
        opportunityRadar: OpportunityRadar
    ) {
        self.intelligenceEngine = intelligenceEngine
        self.currencyEngine = currencyEngine
        self.opportunityRadar = opportunityRadar
    }

    func onAppear() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.currencyEngine.startLiveFeed() }
            group.addTask { await self.opportunityRadar.refresh() }
        }
        rebuildFeed()
    }

    func refresh() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.opportunityRadar.refresh() }
            group.addTask { await self.intelligenceEngine.refresh() }
        }
        rebuildFeed()
        withAnimation(.easeInOut(duration: 0.3)) {
            hasNewData = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            hasNewData = false
        }
    }

    private func rebuildFeed() {
        currencyTicker = Array(
            currencyEngine.rates
                .filter { majorPairs.contains($0.id) }
                .prefix(8)
        )

        var items: [FeedItem] = []

        let topOpps = opportunityRadar.visibleOpportunities.prefix(3)
        items.append(contentsOf: topOpps.map { .opportunity($0) })

        let recentDomains = intelligenceEngine.recentScans.prefix(3)
        items.append(contentsOf: recentDomains.map { .domain($0) })

        let moversRates = currencyEngine.rates
            .sorted { abs($0.changePercent) > abs($1.changePercent) }
            .prefix(2)
        items.append(contentsOf: moversRates.map { .rate($0) })

        feedItems = items
    }
}
