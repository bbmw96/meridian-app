import Foundation
import Translation
import NaturalLanguage
import Observation

// PRISM Translator - Precision Real-time Intelligence Signal Machine
// On-device neural translation using Apple's Translation framework (iOS 17.4+).
// Zero API calls. Zero data exfiltration. Fully offline capability.
// Top 20 most-spoken world languages + Malay.

struct PrismLanguage: Identifiable, Hashable {
    let id: String          // BCP-47 tag
    let nativeName: String
    let englishName: String
    let speakers: Int       // millions
    let isRTL: Bool
    let tier: Tier

    enum Tier: Int {
        case tier1 = 1      // Top 5 by speakers
        case tier2 = 2      // Top 6-15
        case tier3 = 3      // Top 16-21 + Malay (user requirement)
    }

    // Top spoken languages worldwide + Malay
    static let supported: [PrismLanguage] = [
        // Tier 1 - >400M native speakers
        PrismLanguage(id: "zh-Hans", nativeName: "普通话", englishName: "Mandarin Chinese", speakers: 1100, isRTL: false, tier: .tier1),
        PrismLanguage(id: "es",      nativeName: "Español",   englishName: "Spanish",          speakers: 485, isRTL: false, tier: .tier1),
        PrismLanguage(id: "en",      nativeName: "English",   englishName: "English",          speakers: 380, isRTL: false, tier: .tier1),
        PrismLanguage(id: "hi",      nativeName: "हिन्दी",    englishName: "Hindi",            speakers: 345, isRTL: false, tier: .tier1),
        PrismLanguage(id: "ar",      nativeName: "العربية",   englishName: "Arabic",           speakers: 420, isRTL: true,  tier: .tier1),

        // Tier 2 - 60-300M native speakers
        PrismLanguage(id: "pt-BR",   nativeName: "Português", englishName: "Portuguese",       speakers: 234, isRTL: false, tier: .tier2),
        PrismLanguage(id: "bn",      nativeName: "বাংলা",     englishName: "Bengali",          speakers: 228, isRTL: false, tier: .tier2),
        PrismLanguage(id: "ru",      nativeName: "Русский",   englishName: "Russian",          speakers: 154, isRTL: false, tier: .tier2),
        PrismLanguage(id: "ja",      nativeName: "日本語",     englishName: "Japanese",         speakers: 125, isRTL: false, tier: .tier2),
        PrismLanguage(id: "ko",      nativeName: "한국어",     englishName: "Korean",           speakers: 77, isRTL: false, tier: .tier2),
        PrismLanguage(id: "vi",      nativeName: "Tiếng Việt", englishName: "Vietnamese",      speakers: 77, isRTL: false, tier: .tier2),
        PrismLanguage(id: "tr",      nativeName: "Türkçe",    englishName: "Turkish",          speakers: 76, isRTL: false, tier: .tier2),
        PrismLanguage(id: "fr",      nativeName: "Français",  englishName: "French",           speakers: 74, isRTL: false, tier: .tier2),
        PrismLanguage(id: "de",      nativeName: "Deutsch",   englishName: "German",           speakers: 78, isRTL: false, tier: .tier2),
        PrismLanguage(id: "id",      nativeName: "Bahasa Indonesia", englishName: "Indonesian", speakers: 199, isRTL: false, tier: .tier2),

        // Tier 3 - notable + Malay (user requirement)
        PrismLanguage(id: "it",      nativeName: "Italiano",  englishName: "Italian",          speakers: 63, isRTL: false, tier: .tier3),
        PrismLanguage(id: "fa",      nativeName: "فارسی",     englishName: "Persian",          speakers: 77, isRTL: true,  tier: .tier3),
        PrismLanguage(id: "th",      nativeName: "ไทย",       englishName: "Thai",             speakers: 61, isRTL: false, tier: .tier3),
        PrismLanguage(id: "pl",      nativeName: "Polski",    englishName: "Polish",           speakers: 45, isRTL: false, tier: .tier3),
        PrismLanguage(id: "uk",      nativeName: "Українська", englishName: "Ukrainian",       speakers: 40, isRTL: false, tier: .tier3),
        PrismLanguage(id: "ms",      nativeName: "Bahasa Melayu", englishName: "Malay",        speakers: 33, isRTL: false, tier: .tier3),
    ]

    static func language(for id: String) -> PrismLanguage? {
        supported.first { $0.id == id }
    }

    static var tier1: [PrismLanguage] { supported.filter { $0.tier == .tier1 } }
    static var tier2: [PrismLanguage] { supported.filter { $0.tier == .tier2 } }
    static var tier3: [PrismLanguage] { supported.filter { $0.tier == .tier3 } }
}

struct PrismTranslation: Identifiable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguageId: String
    let targetLanguageId: String
    let isOnDevice: Bool
    let translatedAt: Date
    let characterCount: Int
}

@Observable
final class PrismTranslator {
    var recentTranslations: [PrismTranslation] = []
    var isTranslating = false
    var error: String?
    var detectedLanguage: PrismLanguage?

    private let languageRecogniser = NLLanguageRecognizer()

    // MARK: - Translation

    @available(iOS 17.4, *)
    func translate(
        text: String,
        from sourceLang: PrismLanguage?,
        to targetLang: PrismLanguage
    ) async throws -> PrismTranslation {
        isTranslating = true
        defer { isTranslating = false }
        error = nil

        // Auto-detect source if not provided
        let resolved = sourceLang ?? detectLanguage(text)
        let sourceCode = resolved?.id ?? "en"

        guard let source = Locale.Language(identifier: sourceCode) as Locale.Language?,
              let target = Locale.Language(identifier: targetLang.id) as Locale.Language? else {
            throw PrismError.unsupportedLanguagePair
        }

        // Apple Translation - fully on-device, iOS 17.4+
        let session = TranslationSession.Configuration(source: source, target: target)
        // Note: TranslationSession is attached to a View in SwiftUI via .translationTask modifier
        // This engine provides the data model; the View layer drives the actual session

        let translation = PrismTranslation(
            id: UUID(),
            originalText: text,
            translatedText: "[Translation pending - attach to View via .translationTask]",
            sourceLanguageId: sourceCode,
            targetLanguageId: targetLang.id,
            isOnDevice: true,
            translatedAt: Date(),
            characterCount: text.count
        )

        recentTranslations.insert(translation, at: 0)
        if recentTranslations.count > 50 { recentTranslations = Array(recentTranslations.prefix(50)) }
        return translation
    }

    // MARK: - Language Detection (fully on-device)

    func detectLanguage(_ text: String) -> PrismLanguage? {
        languageRecogniser.processString(text)
        guard let lang = languageRecogniser.dominantLanguage else { return nil }
        let detected = PrismLanguage.language(for: lang.rawValue)
        detectedLanguage = detected
        return detected
    }

    func detectLanguageCode(_ text: String) -> String {
        languageRecogniser.processString(text)
        return languageRecogniser.dominantLanguage?.rawValue ?? "und"
    }

    func searchLanguages(_ query: String) -> [PrismLanguage] {
        guard !query.isEmpty else { return PrismLanguage.supported }
        let q = query.lowercased()
        return PrismLanguage.supported.filter {
            $0.englishName.lowercased().contains(q) ||
            $0.nativeName.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    func clearHistory() {
        recentTranslations = []
    }
}

enum PrismError: LocalizedError {
    case unsupportedLanguagePair
    case translationFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedLanguagePair:
            return "This language pair is not supported for on-device translation."
        case .translationFailed(let reason):
            return "Translation failed: \(reason)"
        }
    }
}
