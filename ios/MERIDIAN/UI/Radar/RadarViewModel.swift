import SwiftUI
import MapKit

@Observable
final class RadarViewModel {

    var opportunities: [Opportunity] = []
    var pinnedOpportunities: [Opportunity] = []
    var selectedOpportunity: Opportunity?
    var isLoading: Bool = false
    var marketFilter: String = ""
    var minScoreFilter: Double = 0
    var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 160)
    )

    private let radar: OpportunityRadar

    init(radar: OpportunityRadar) {
        self.radar = radar
    }

    func onAppear() async {
        isLoading = true
        await radar.refresh()
        opportunities = radar.opportunities
        pinnedOpportunities = radar.pinnedOpportunities
        isLoading = false
    }

    var filteredOpportunities: [Opportunity] {
        opportunities.filter { opp in
            let marketMatch = marketFilter.isEmpty || opp.market.localizedCaseInsensitiveContains(marketFilter)
            let scoreMatch = opp.opportunityScore >= minScoreFilter
            return marketMatch && scoreMatch
        }
        .sorted { $0.opportunityScore > $1.opportunityScore }
    }

    func select(_ opportunity: Opportunity) {
        selectedOpportunity = opportunity
    }

    func dismiss(_ opportunity: Opportunity) {
        radar.dismiss(id: opportunity.id)
        opportunities = radar.opportunities
    }

    func pin(_ opportunity: Opportunity) {
        radar.pin(id: opportunity.id)
        pinnedOpportunities = radar.pinnedOpportunities
    }

    func scoreColour(for score: Double) -> String {
        switch score {
        case 80...100: return "meridianGreen"
        case 60..<80:  return "meridianGold"
        default:       return "meridianRed"
        }
    }
}
