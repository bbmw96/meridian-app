import SwiftUI

struct MeridianCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.meridianSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.meridianAccent.opacity(0.15), lineWidth: 1)
            )
    }
}

struct MeridianGlowModifier: ViewModifier {
    let colour: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: colour.opacity(0.4), radius: 8, x: 0, y: 0)
            .shadow(color: colour.opacity(0.2), radius: 16, x: 0, y: 0)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.meridianBackground, location: 0),
                .init(color: Color(hex: "#0A1628"), location: 0.5),
                .init(color: Color.meridianBackground, location: 1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            GradientBackground()
            content
        }
    }
}

extension View {
    func meridianCard() -> some View {
        modifier(MeridianCardModifier())
    }

    func meridianGlow(colour: Color = .meridianAccent) -> some View {
        modifier(MeridianGlowModifier(colour: colour))
    }

    func meridianBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.04 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}
