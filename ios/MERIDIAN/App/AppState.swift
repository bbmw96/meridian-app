import SwiftUI
import Observation

enum Tab: String, CaseIterable, Identifiable {
    // Core
    case dashboard
    case scanner
    case currency
    // New Invented Engines
    case quorum      // Stakeholder sentiment
    case prism       // On-device translation
    case axiom       // Decision modelling
    case vault       // CIPHER zero-knowledge storage
    // Existing
    case creative
    case terminal
    case radar
    case settings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dashboard: return "Dashboard"
        case .scanner:   return "Scanner"
        case .currency:  return "Currency"
        case .quorum:    return "QUORUM"
        case .prism:     return "PRISM"
        case .axiom:     return "AXIOM"
        case .vault:     return "Vault"
        case .creative:  return "Creative"
        case .terminal:  return "Terminal"
        case .radar:     return "Radar"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .scanner:   return "viewfinder.circle"
        case .currency:  return "arrow.left.arrow.right.circle"
        case .quorum:    return "waveform.and.magnifyingglass"
        case .prism:     return "globe.europe.africa.fill"
        case .axiom:     return "chart.xyaxis.line"
        case .vault:     return "lock.shield.fill"
        case .creative:  return "wand.and.stars"
        case .terminal:  return "terminal"
        case .radar:     return "antenna.radiowaves.left.and.right"
        case .settings:  return "gearshape"
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
