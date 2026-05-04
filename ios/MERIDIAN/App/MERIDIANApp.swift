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
                .tabItem { Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.dashboard)

            IntelligenceScannerView()
                .tabItem { Label("Scanner", systemImage: "viewfinder.circle") }
                .tag(Tab.scanner)

            CurrencyView()
                .tabItem { Label("Currency", systemImage: "arrow.left.arrow.right.circle") }
                .tag(Tab.currency)

            CreativeView()
                .tabItem { Label("Creative", systemImage: "wand.and.stars") }
                .tag(Tab.creative)

            MQLTerminalView()
                .tabItem { Label("Terminal", systemImage: "terminal") }
                .tag(Tab.terminal)

            RadarView()
                .tabItem { Label("Radar", systemImage: "antenna.radiowaves.left.and.right") }
                .tag(Tab.radar)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}
