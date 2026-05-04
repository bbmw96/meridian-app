import Foundation
import Observation

@Observable
final class OpportunityRadar {
    var opportunities: [Opportunity] = []
    var isLoading = false
    var lastRefreshed: Date?

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private var dismissedIDs: Set<UUID> = []
    private var pinnedIDs: Set<UUID> = []

    var topOpportunity: Opportunity? {
        opportunities
            .filter { !dismissedIDs.contains($0.id) }
            .max(by: { $0.opportunityScore < $1.opportunityScore })
    }

    var pinnedOpportunities: [Opportunity] {
        opportunities.filter { pinnedIDs.contains($0.id) }
    }

    var visibleOpportunities: [Opportunity] {
        opportunities
            .filter { !dismissedIDs.contains($0.id) }
            .sorted { $0.opportunityScore > $1.opportunityScore }
    }

    func refresh() async {
        if let cached = await cache.retrieveOpportunities(), !opportunities.isEmpty {
            opportunities = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched: [Opportunity] = try await apiClient.fetch(.getOpportunities)
            opportunities = fetched
            await cache.cacheOpportunities(fetched)
            lastRefreshed = Date()
        } catch {
            if opportunities.isEmpty {
                opportunities = Opportunity.previewList
                lastRefreshed = Date()
            }
        }
    }

    func dismiss(id: UUID) {
        dismissedIDs.insert(id)
    }

    func pin(id: UUID) {
        if pinnedIDs.contains(id) {
            pinnedIDs.remove(id)
        } else {
            pinnedIDs.insert(id)
        }

        if let index = opportunities.firstIndex(where: { $0.id == id }) {
            opportunities[index].isPinned = pinnedIDs.contains(id)
        }

        if let opp = opportunities.first(where: { $0.id == id }) {
            PersistenceController.shared.saveOpportunity(opp)
        }
    }

    func isPinned(_ id: UUID) -> Bool {
        pinnedIDs.contains(id)
    }

    func isDismissed(_ id: UUID) -> Bool {
        dismissedIDs.contains(id)
    }

    func filtered(market: String? = nil, minimumScore: Double = 0, currency: String? = nil) -> [Opportunity] {
        visibleOpportunities.filter { opp in
            if let market, !market.isEmpty, opp.market != market { return false }
            if opp.opportunityScore < minimumScore { return false }
            return true
        }
    }
}
