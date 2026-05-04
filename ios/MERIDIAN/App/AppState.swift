import SwiftUI
import Observation

enum Tab: String, CaseIterable, Identifiable {
    case dashboard
    case scanner
    case currency
    case creative
    case terminal
    case radar
    case settings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dashboard: return "Dashboard"
        case .scanner: return "Scanner"
        case .currency: return "Currency"
        case .creative: return "Creative"
        case .terminal: return "Terminal"
        case .radar: return "Radar"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .scanner: return "viewfinder.circle"
        case .currency: return "arrow.left.arrow.right.circle"
        case .creative: return "wand.and.stars"
        case .terminal: return "terminal"
        case .radar: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape"
        }
    }
}

@Observable
final class AppState {
    var selectedTab: Tab = .dashboard
    var isOnboarded: Bool
    var preferredCurrency: String
    var preferredLanguage: String

    private let defaults = UserDefaults.standard

    init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "meridian.isOnboarded")
        self.preferredCurrency = UserDefaults.standard.string(forKey: "meridian.preferredCurrency") ?? "GBP"
        self.preferredLanguage = UserDefaults.standard.string(forKey: "meridian.preferredLanguage") ?? "en"
    }

    func persistPreferences() {
        defaults.set(isOnboarded, forKey: "meridian.isOnboarded")
        defaults.set(preferredCurrency, forKey: "meridian.preferredCurrency")
        defaults.set(preferredLanguage, forKey: "meridian.preferredLanguage")
    }
}
