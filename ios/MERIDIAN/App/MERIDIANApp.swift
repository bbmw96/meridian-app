import SwiftUI

@main
struct MERIDIANApp: App {
    @State private var appState = AppState()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.meridianBackground)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.meridianAccent),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.meridianAccent),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.meridianSurface)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color.meridianAccent)
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
    }
}

struct ContentRootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        TabView(selection: $state.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: Tab.dashboard.icon) }
                .tag(Tab.dashboard)

            IntelligenceScannerView()
                .tabItem { Label("Scanner", systemImage: Tab.scanner.icon) }
                .tag(Tab.scanner)

            CurrencyView()
                .tabItem { Label("Currency", systemImage: Tab.currency.icon) }
                .tag(Tab.currency)

            QuorumView()
                .tabItem { Label("QUORUM", systemImage: Tab.quorum.icon) }
                .tag(Tab.quorum)

            PrismTranslateView()
                .tabItem { Label("PRISM", systemImage: Tab.prism.icon) }
                .tag(Tab.prism)

            AxiomView()
                .tabItem { Label("AXIOM", systemImage: Tab.axiom.icon) }
                .tag(Tab.axiom)

            VaultView()
                .tabItem { Label("Vault", systemImage: Tab.vault.icon) }
                .tag(Tab.vault)

            CreativeView()
                .tabItem { Label("Creative", systemImage: Tab.creative.icon) }
                .tag(Tab.creative)

            MQLTerminalView()
                .tabItem { Label("Terminal", systemImage: Tab.terminal.icon) }
                .tag(Tab.terminal)

            RadarView()
                .tabItem { Label("Radar", systemImage: Tab.radar.icon) }
                .tag(Tab.radar)

            SettingsView()
                .tabItem { Label("Settings", systemImage: Tab.settings.icon) }
                .tag(Tab.settings)
        }
    }
}
