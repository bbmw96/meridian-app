import SwiftUI

struct CurrencyTickerView: View {
    let rates: [CurrencyRate]
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        if rates.isEmpty {
            TickerSkeleton()
        } else {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        tickerContent
                        tickerContent
                    }
                    .offset(x: offset)
                    .onAppear { startScrolling(viewWidth: geo.size.width) }
                }
                .clipped()
            }
        }
    }

    private var tickerContent: some View {
        HStack(spacing: 12) {
            ForEach(rates) { rate in
                CurrencyPillView(rate: rate)
            }
        }
        .padding(.horizontal, 8)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(ContentWidthKey.self) { width in
            contentWidth = width
        }
    }

    private func startScrolling(viewWidth: CGFloat) {
        guard contentWidth > 0 else { return }
        let duration = Double(contentWidth) / 40
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }
}

struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CurrencyPillView: View {
    let rate: CurrencyRate

    var body: some View {
        HStack(spacing: 6) {
            Text(rate.id)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(rate.formattedRate)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Color.meridianAccent)

            HStack(spacing: 2) {
                Image(systemName: rate.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8))
                Text(rate.formattedChange)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(rate.isPositive ? Color.meridianGreen : Color.meridianRed)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.meridianSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    rate.isPositive ? Color.meridianGreen.opacity(0.3) : Color.meridianRed.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

struct TickerSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.meridianSurface)
                    .frame(width: 100, height: 30)
                    .opacity(isAnimating ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .onAppear { isAnimating = true }
    }
}

#Preview {
    CurrencyTickerView(rates: CurrencyRate.previewList)
        .frame(height: 50)
        .meridianBackground()
        .preferredColorScheme(.dark)
}
