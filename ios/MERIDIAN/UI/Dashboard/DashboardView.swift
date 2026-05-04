import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel(
        intelligenceEngine: IntelligenceEngine(),
        currencyEngine: CurrencyEngine(),
        opportunityRadar: OpportunityRadar()
    )

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        CurrencyTickerView(rates: viewModel.currencyTicker)
                            .frame(height: 60)

                        if !viewModel.opportunityRadar.visibleOpportunities.isEmpty {
                            SectionHeader(title: "Top Opportunities", count: viewModel.opportunityRadar.visibleOpportunities.count)
                            ForEach(viewModel.opportunityRadar.visibleOpportunities.prefix(3)) { opp in
                                OpportunityCardView(
                                    opportunity: opp,
                                    onPin: { viewModel.opportunityRadar.pin(id: opp.id) },
                                    onDismiss: { viewModel.opportunityRadar.dismiss(id: opp.id) }
                                )
                                .padding(.horizontal)
                            }
                        }

                        if !viewModel.intelligenceEngine.recentScans.isEmpty {
                            SectionHeader(title: "Recent Scans", count: viewModel.intelligenceEngine.recentScans.count)
                            ForEach(viewModel.intelligenceEngine.recentScans.prefix(3)) { domain in
                                RecentScanRow(profile: domain)
                                    .padding(.horizontal)
                            }
                        }

                        if viewModel.intelligenceEngine.recentScans.isEmpty &&
                           viewModel.opportunityRadar.opportunities.isEmpty {
                            DashboardEmptyState()
                                .padding(.top, 60)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable { await viewModel.refresh() }
            }
            .navigationTitle("MERIDIAN")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasNewData {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(Color.meridianAccent)
                            .pulseAnimation()
                    }
                }
            }
        }
        .task { await viewModel.onAppear() }
    }
}

struct SectionHeader: View {
    let title: LocalizedStringKey
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(Color.meridianAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.meridianAccent.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
    }
}

struct RecentScanRow: View {
    let profile: DomainProfile

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(Color.meridianAccent)
                .frame(width: 40, height: 40)
                .background(Color.meridianAccent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(profile.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(profile.formattedTraffic)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.meridianAccent)
                Text("monthly")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: profile.trafficTrend.icon)
                .foregroundStyle(Color.trendColour(profile.trafficTrend))
                .font(.callout)
        }
        .padding(14)
        .meridianCard()
    }
}

struct DashboardEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.meridianAccent.opacity(0.6))
                .meridianGlow(colour: .meridianAccent)

            VStack(spacing: 8) {
                Text("Ready to Scan")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Head to the Scanner tab to analyse any domain and discover opportunities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
