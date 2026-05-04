import SwiftUI

struct MeridianCardView<Content: View>: View {
    let title: String
    let subtitle: String?
    let badgeColour: Color
    let badgeText: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        badgeColour: Color = .meridianAccent,
        badgeText: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badgeColour = badgeColour
        self.badgeText = badgeText
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let badge = badgeText {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColour.opacity(0.15))
                        .foregroundStyle(badgeColour)
                        .clipShape(Capsule())
                }
            }

            content()
        }
        .padding()
        .meridianCard()
    }
}

#Preview {
    VStack(spacing: 16) {
        MeridianCardView(
            title: "Intelligence Report",
            subtitle: "shopify.com",
            badgeColour: .meridianGreen,
            badgeText: "Rising"
        ) {
            HStack {
                Text("Monthly Traffic")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("142M")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.meridianAccent)
            }
        }

        MeridianCardView(
            title: "Currency Alert",
            badgeColour: .meridianGold,
            badgeText: "Active"
        ) {
            Text("GBP/USD above 1.30")
                .font(.subheadline)
        }
    }
    .padding()
    .meridianBackground()
    .preferredColorScheme(.dark)
}
