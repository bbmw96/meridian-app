import SwiftUI
import MapKit

struct RadarView: View {
    @State private var radar = OpportunityRadar()
    @State private var selectedOpportunity: Opportunity?
    @State private var selectedMarket: String = ""
    @State private var minimumScore: Double = 0
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30, longitude: 10),
            span: MKCoordinateSpan(latitudeDelta: 80, longitudeDelta: 80)
        )
    )

    private var filteredOpportunities: [Opportunity] {
        radar.filtered(
            market: selectedMarket.isEmpty ? nil : selectedMarket,
            minimumScore: minimumScore
        )
    }

    private var uniqueMarkets: [String] {
        Array(Set(radar.opportunities.map(\.market))).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                VStack(spacing: 0) {
                    FilterBar(
                        selectedMarket: $selectedMarket,
                        minimumScore: $minimumScore,
                        markets: uniqueMarkets
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.meridianSurface.opacity(0.9))

                    GeometryReader { geo in
                        HSplitOrVStack(isWide: geo.size.width > 700) {
                            OpportunityMap(
                                opportunities: filteredOpportunities,
                                selected: $selectedOpportunity,
                                position: $mapPosition
                            )
                            .frame(minHeight: 300)

                            OpportunitySidebar(
                                opportunities: filteredOpportunities,
                                selected: $selectedOpportunity,
                                radar: radar
                            )
                        }
                    }
                }

                ScoreLegend()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .navigationTitle("Opportunity Radar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await radar.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.meridianAccent)
                    }
                    .disabled(radar.isLoading)
                }
            }
            .sheet(item: $selectedOpportunity) { opp in
                OpportunityDetailSheet(
                    opportunity: opp,
                    isPinned: radar.isPinned(opp.id),
                    onPin: { radar.pin(id: opp.id) },
                    onDismiss: {
                        radar.dismiss(id: opp.id)
                        selectedOpportunity = nil
                    }
                )
            }
        }
        .task { await radar.refresh() }
    }
}

struct OpportunityMap: View {
    let opportunities: [Opportunity]
    @Binding var selected: Opportunity?
    @Binding var position: MapCameraPosition

    private let countryCoordinates: [String: CLLocationCoordinate2D] = [
        "DE": CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
        "SG": CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        "SE": CLLocationCoordinate2D(latitude: 60.1282, longitude: 18.6435),
        "AE": CLLocationCoordinate2D(latitude: 23.4241, longitude: 53.8478),
        "US": CLLocationCoordinate2D(latitude: 37.0902, longitude: -95.7129),
        "GB": CLLocationCoordinate2D(latitude: 55.3781, longitude: -3.4360),
        "JP": CLLocationCoordinate2D(latitude: 36.2048, longitude: 138.2529),
        "AU": CLLocationCoordinate2D(latitude: -25.2744, longitude: 133.7751),
        "CA": CLLocationCoordinate2D(latitude: 56.1304, longitude: -106.3468),
        "FR": CLLocationCoordinate2D(latitude: 46.2276, longitude: 2.2137),
        "IN": CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        "BR": CLLocationCoordinate2D(latitude: -14.2350, longitude: -51.9253)
    ]

    var body: some View {
        Map(position: $position) {
            ForEach(opportunities) { opp in
                if let coord = countryCoordinates[opp.geography] {
                    Annotation(opp.geography, coordinate: coord) {
                        OpportunityPin(opportunity: opp, isSelected: selected?.id == opp.id) {
                            selected = opp
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

struct OpportunityPin: View {
    let opportunity: Opportunity
    let isSelected: Bool
    let onTap: () -> Void

    private var colour: Color {
        Color.opportunityColour(score: opportunity.opportunityScore)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(colour.opacity(0.2))
                    .frame(width: isSelected ? 52 : 36, height: isSelected ? 52 : 36)

                Circle()
                    .fill(colour)
                    .frame(width: isSelected ? 28 : 20, height: isSelected ? 28 : 20)
                    .overlay(
                        Text(String(Int(opportunity.opportunityScore)))
                            .font(.system(size: isSelected ? 9 : 7, weight: .bold))
                            .foregroundStyle(.black)
                    )
            }
            .meridianGlow(colour: colour)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

struct OpportunitySidebar: View {
    let opportunities: [Opportunity]
    @Binding var selected: Opportunity?
    let radar: OpportunityRadar

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(opportunities) { opp in
                    OpportunityCardView(
                        opportunity: opp,
                        onPin: { radar.pin(id: opp.id) },
                        onDismiss: { radar.dismiss(id: opp.id) }
                    )
                    .onTapGesture { selected = opp }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                Color.meridianAccent,
                                lineWidth: selected?.id == opp.id ? 2 : 0
                            )
                    )
                }
            }
            .padding()
        }
    }
}

struct FilterBar: View {
    @Binding var selectedMarket: String
    @Binding var minimumScore: Double
    let markets: [String]

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedMarket.isEmpty) {
                        selectedMarket = ""
                    }
                    ForEach(markets, id: \.self) { market in
                        FilterChip(title: market, isSelected: selectedMarket == market) {
                            selectedMarket = market == selectedMarket ? "" : market
                        }
                    }
                }
            }

            HStack {
                Text("Min Score:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $minimumScore, in: 0...100, step: 5)
                    .tint(Color.meridianAccent)
                Text("\(Int(minimumScore))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.meridianAccent)
                    .frame(width: 28)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.meridianAccent : Color.meridianSurface)
                .foregroundStyle(isSelected ? Color.meridianBackground : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ScoreLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LegendRow(colour: .meridianGreen, label: "80+ Excellent")
            LegendRow(colour: .meridianGold, label: "60-79 Good")
            LegendRow(colour: .meridianRed, label: "< 60 Monitor")
        }
        .padding(10)
        .background(Color.meridianSurface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct LegendRow: View {
    let colour: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colour)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct OpportunityDetailSheet: View {
    let opportunity: Opportunity
    let isPinned: Bool
    let onPin: () -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        OpportunityScoreHeader(opportunity: opportunity)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Intelligence Summary")
                                .font(.headline)
                            Text(opportunity.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineSpacing(6)
                        }
                        .padding()
                        .meridianCard()

                        VStack(spacing: 0) {
                            MetricRow(label: "Currency Stability", value: "\(Int(opportunity.currencyStability * 100))%", colour: .meridianGreen)
                            Divider().overlay(Color.meridianAccent.opacity(0.15))
                            MetricRow(label: "Traffic Gap", value: "\(Int(opportunity.trafficGap * 100))% unmet demand", colour: .meridianGold)
                            Divider().overlay(Color.meridianAccent.opacity(0.15))
                            MetricRow(label: "Est. Revenue", value: opportunity.formattedRevenue, colour: .meridianAccent)
                            Divider().overlay(Color.meridianAccent.opacity(0.15))
                            MetricRow(label: "Market", value: opportunity.market, colour: .primary)
                            Divider().overlay(Color.meridianAccent.opacity(0.15))
                            MetricRow(label: "Geography", value: opportunity.geography, colour: .primary)
                        }
                        .meridianCard()
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button(action: {
                                onPin()
                                dismiss()
                            }) {
                                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.meridianBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.meridianGold)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button(action: onDismiss) {
                                Label("Dismiss", systemImage: "xmark.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.meridianRed)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.meridianRed.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(opportunity.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct OpportunityScoreHeader: View {
    let opportunity: Opportunity

    var body: some View {
        HStack(spacing: 20) {
            CircularScoreView(score: opportunity.opportunityScore, size: 80)

            VStack(alignment: .leading, spacing: 6) {
                if opportunity.isNew {
                    Text("New Opportunity")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.meridianAccent.opacity(0.15))
                        .foregroundStyle(Color.meridianAccent)
                        .clipShape(Capsule())
                }
                Text(opportunity.geography)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(opportunity.market)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .meridianCard()
        .padding(.horizontal)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let colour: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(colour)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct HSplitOrVStack<Content: View>: View {
    let isWide: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isWide {
            HStack(spacing: 0) { content() }
        } else {
            VStack(spacing: 0) { content() }
        }
    }
}

#Preview {
    RadarView()
        .preferredColorScheme(.dark)
}
