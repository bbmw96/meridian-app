import SwiftUI

@Observable
final class SettingsViewModel {

    var preferredCurrency: String
    var preferredLanguage: String
    var appVersion: String
    var mqlVersion: String = "1.0.0"

    private let appState: AppState
    private let languageEngine: LanguageEngine

    init(appState: AppState, languageEngine: LanguageEngine) {
        self.appState = appState
        self.languageEngine = languageEngine
        self.preferredCurrency = appState.preferredCurrency
        self.preferredLanguage = appState.preferredLanguage
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        self.appVersion = "\(version) (\(build))"
    }

    var supportedLanguages: [SupportedLanguage] {
        languageEngine.supportedLanguages
    }

    func applyLanguageChange(_ language: SupportedLanguage) {
        preferredLanguage = language.id
        appState.preferredLanguage = language.id
    }

    func applyCurrencyChange(_ currency: String) {
        preferredCurrency = currency
        appState.preferredCurrency = currency
    }

    var isRTL: Bool {
        languageEngine.supportedLanguages
            .first { $0.id == preferredLanguage }?.isRTL ?? false
    }

    let supportedCurrencies: [String] = [
        "GBP", "USD", "EUR", "JPY", "AUD", "CAD", "CHF", "CNY", "INR", "BRL",
        "MXN", "SGD", "HKD", "NOK", "SEK", "DKK", "NZD", "ZAR", "RUB", "TRY",
        "AED", "SAR", "THB", "MYR", "IDR", "PHP", "PKR", "BDT", "VND", "KRW",
        "CZK", "HUF", "PLN", "RON", "HRK", "BGN", "ILS", "NGN", "KES", "EGP",
        "MAD", "DZD", "TND", "GHS", "ETB", "UGX", "TZS", "XOF", "CLP", "COP",
        "PEN", "ARS", "UYU", "BOB", "PYG", "VEF", "GTQ", "CRC", "HNL", "NIO",
        "DOP", "JMD", "TTD", "BBD", "BSD", "BZD", "GYD", "HTG", "XCD", "AWG",
        "KYD", "BMD", "FJD", "PGK", "SBD", "TOP", "VUV", "WST", "XPF", "MNT",
        "LAK", "KHR", "MMK", "TWD", "LKR", "MVR", "NPR", "AFN", "AMD", "AZN",
        "GEL", "KZT", "KGS", "TJS", "TMT", "UZS", "BYN", "MDL", "UAH", "RSD",
        "BAM", "MKD", "ALL", "MZN", "IQD", "JOD", "KWD", "OMR", "BHD", "QAR",
        "YER", "LYD", "SYP", "LBP", "IRR", "SOS", "DJF", "ERN", "SDG", "SSP",
        "MWK", "ZMW", "BWP", "LSL", "SZL", "NAD", "MUR", "SCR", "KMF", "MGA",
        "GMD", "GNF", "SLL", "LRD", "SLE", "CVE", "STN", "AOA", "CDF", "RWF",
        "BIF", "XAF", "XAG", "XAU", "XPD", "XPT"
    ]
}
