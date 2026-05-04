import SwiftUI

struct CompetitorCardView: View {
    let competitor: Competitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(competitor.domain)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    HStack(spacing: 4) {
                        ForEach(competitor.geographies.prefix(3), id: \.self) { geo in
                            Text(geo)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.meridianPrimary)
                                .foregroundStyle(Color.meridianAccent)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                DeltaBadge(delta: competitor.delta)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Traffic Share")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1f", competitor.trafficShare * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.meridianAccent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.meridianBackground)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.meridianAccent.gradient)
                            .frame(width: geo.size.width * competitor.trafficShare, height: 6)
                    }
                }
                .frame(height: 6)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue (\(competitor.targetCurrency))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(competitor.formattedRevenue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.meridianGold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Opportunity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    CircularScoreView(score: competitor.opportunityScore, size: 36)
                }
            }
        }
        .padding(14)
        .meridianCard()
    }
}

struct DeltaBadge: View {
    let delta: Double

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text(String(format: "%@%.1f%%", delta >= 0 ? "+" : "", delta))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(delta >= 0 ? Color.meridianGreen : Color.meridianRed)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((delta >= 0 ? Color.meridianGreen : Color.meridianRed).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct CircularScoreView: View {
    let score: Double
    let size: CGFloat

    private var colour: Color { Color.opportunityColour(score: score) }
    private var lineWidth: CGFloat { size * 0.12 }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(colour.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(colour, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)
            Text(String(Int(score)))
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(colour)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Competitor.previewList) { competitor in
            CompetitorCardView(competitor: competitor)
        }
    }
    .padding()
    .meridianBackground()
    .preferredColorScheme(.dark)
}
