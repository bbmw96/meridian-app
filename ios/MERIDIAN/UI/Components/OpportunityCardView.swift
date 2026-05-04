import SwiftUI

struct OpportunityCardView: View {
    let opportunity: Opportunity
    let onPin: () -> Void
    let onDismiss: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDismissing = false

    private var scoreColour: Color {
        Color.opportunityColour(score: opportunity.opportunityScore)
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                scoreColour.opacity(0.15),
                Color.meridianSurface,
                Color.meridianSurface
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            CircularScoreView(score: opportunity.opportunityScore, size: 60)
                .meridianGlow(colour: scoreColour)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if opportunity.isNew {
                        NewBadge()
                    }
                    Text(opportunity.geography)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.meridianAccent)
                    Spacer()
                    Text(opportunity.market)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(opportunity.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(opportunity.formattedRevenue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.meridianGold)
            }

            VStack(spacing: 8) {
                Button(action: onPin) {
                    Image(systemName: opportunity.isPinned ? "pin.fill" : "pin")
                        .font(.body)
                        .foregroundStyle(Color.meridianGold)
                }

                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) { isDismissing = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDismiss() }
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundStyle(Color.meridianRed.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(scoreColour.opacity(0.2), lineWidth: 1)
        )
        .offset(y: isDismissing ? -20 : 0)
        .opacity(isDismissing ? 0 : 1)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = CGSize(width: value.translation.width, height: 0)
                    }
                }
                .onEnded { value in
                    if value.translation.width < -80 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = CGSize(width: -400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
                    } else {
                        withAnimation(.spring(duration: 0.3)) { dragOffset = .zero }
                    }
                }
        )
    }
}

struct NewBadge: View {
    @State private var isAnimating = false

    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(Color.meridianBackground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.meridianAccent)
            .clipShape(Capsule())
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Opportunity.previewList) { opp in
            OpportunityCardView(
                opportunity: opp,
                onPin: {},
                onDismiss: {}
            )
        }
    }
    .padding()
    .meridianBackground()
    .preferredColorScheme(.dark)
}
