import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.meridianBackground.ignoresSafeArea()

            TabView(selection: $viewModel.currentPage) {
                OnboardingPageView(page: .welcome)
                    .tag(0)
                OnboardingPageView(page: .scanner)
                    .tag(1)
                OnboardingPageView(page: .currency)
                    .tag(2)
                OnboardingPageView(page: .terminal)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: viewModel.currentPage)

            if !viewModel.isLastPage {
                Button {
                    viewModel.complete(appState: appState)
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.subheadline)
                        .foregroundStyle(Color.meridianAccent.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .padding(.top, 56)
                .padding(.trailing, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        @Environment(AppState.self) var appState
        ZStack {
            OnboardingGradient(colours: page.gradientColours)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        page.accentColour.opacity(0.25),
                                        page.accentColour.opacity(0.05),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: page.symbol)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(page.accentColour)
                            .meridianGlow(colour: page.accentColour)
                    }

                    VStack(spacing: 14) {
                        if case .welcome = page {
                            Text("MERIDIAN")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(Color.meridianAccent)
                                .meridianGlow(colour: .meridianAccent)
                        } else {
                            Text(page.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }

                        Text(page.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()
                Spacer()

                if case .terminal = page {
                    GetStartedButton(appState: appState)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 80)
                }
            }
        }
    }
}

private struct GetStartedButton: View {
    let appState: AppState

    var body: some View {
        Button {
            appState.isOnboarded = true
            appState.persistPreferences()
        } label: {
            HStack(spacing: 10) {
                Text(String(localized: "Get Started"))
                    .font(.headline)
                    .fontWeight(.bold)
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.meridianBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [Color.meridianAccent, Color.meridianAccent.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.meridianAccent.opacity(0.45), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingGradient: View {
    let colours: [Color]

    var body: some View {
        ZStack {
            Color.meridianBackground.ignoresSafeArea()
            LinearGradient(
                colors: colours,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.18)
            .ignoresSafeArea()
        }
    }
}

private enum OnboardingPage {
    case welcome
    case scanner
    case currency
    case terminal

    var symbol: String {
        switch self {
        case .welcome: return "globe"
        case .scanner: return "arrow.up.right.square"
        case .currency: return "chart.line.uptrend.xyaxis"
        case .terminal: return "terminal"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .welcome: return "MERIDIAN"
        case .scanner: return "Scan Any Domain"
        case .currency: return "Live Currency Intelligence"
        case .terminal: return "MQL \u{2014} Your Query Language"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .welcome:
            return "Global Business Intelligence at your fingertips."
        case .scanner:
            return "Analyse competitors and discover market gaps in seconds."
        case .currency:
            return "Track live rates and set smart alerts across 170+ currency pairs."
        case .terminal:
            return "Query global markets with natural language using the MQL terminal."
        }
    }

    var accentColour: Color {
        switch self {
        case .welcome: return .meridianAccent
        case .scanner: return .meridianGold
        case .currency: return .meridianGreen
        case .terminal: return .meridianAccent
        }
    }

    var gradientColours: [Color] {
        switch self {
        case .welcome:
            return [Color.meridianAccent, Color.meridianPrimary]
        case .scanner:
            return [Color.meridianGold, Color.meridianPrimary]
        case .currency:
            return [Color.meridianGreen, Color.meridianPrimary]
        case .terminal:
            return [Color.meridianAccent, Color(hex: "#0A1628")]
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
