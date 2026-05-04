import Foundation
import Combine

struct SupportedLanguage: Identifiable {
    var id: String
    var nativeName: String
    var englishName: String
    var isRTL: Bool

    static let all: [SupportedLanguage] = [
        SupportedLanguage(id: "en", nativeName: "English", englishName: "English", isRTL: false),
        SupportedLanguage(id: "ar", nativeName: "العربية", englishName: "Arabic", isRTL: true),
        SupportedLanguage(id: "zh-Hans", nativeName: "中文（简体）", englishName: "Chinese (Simplified)", isRTL: false),
        SupportedLanguage(id: "zh-Hant", nativeName: "中文（繁體）", englishName: "Chinese (Traditional)", isRTL: false),
        SupportedLanguage(id: "cs", nativeName: "Čeština", englishName: "Czech", isRTL: false),
        SupportedLanguage(id: "da", nativeName: "Dansk", englishName: "Danish", isRTL: false),
        SupportedLanguage(id: "nl", nativeName: "Nederlands", englishName: "Dutch", isRTL: false),
        SupportedLanguage(id: "fi", nativeName: "Suomi", englishName: "Finnish", isRTL: false),
        SupportedLanguage(id: "fr", nativeName: "Français", englishName: "French", isRTL: false),
        SupportedLanguage(id: "de", nativeName: "Deutsch", englishName: "German", isRTL: false),
        SupportedLanguage(id: "el", nativeName: "Ελληνικά", englishName: "Greek", isRTL: false),
        SupportedLanguage(id: "he", nativeName: "עברית", englishName: "Hebrew", isRTL: true),
        SupportedLanguage(id: "hi", nativeName: "हिन्दी", englishName: "Hindi", isRTL: false),
        SupportedLanguage(id: "hu", nativeName: "Magyar", englishName: "Hungarian", isRTL: false),
        SupportedLanguage(id: "id", nativeName: "Bahasa Indonesia", englishName: "Indonesian", isRTL: false),
        SupportedLanguage(id: "it", nativeName: "Italiano", englishName: "Italian", isRTL: false),
        SupportedLanguage(id: "ja", nativeName: "日本語", englishName: "Japanese", isRTL: false),
        SupportedLanguage(id: "ko", nativeName: "한국어", englishName: "Korean", isRTL: false),
        SupportedLanguage(id: "ms", nativeName: "Bahasa Melayu", englishName: "Malay", isRTL: false),
        SupportedLanguage(id: "nb", nativeName: "Norsk bokmål", englishName: "Norwegian", isRTL: false),
        SupportedLanguage(id: "fa", nativeName: "فارسی", englishName: "Persian", isRTL: true),
        SupportedLanguage(id: "pl", nativeName: "Polski", englishName: "Polish", isRTL: false),
        SupportedLanguage(id: "pt-BR", nativeName: "Português (Brasil)", englishName: "Portuguese (Brazil)", isRTL: false),
        SupportedLanguage(id: "pt-PT", nativeName: "Português (Portugal)", englishName: "Portuguese (Portugal)", isRTL: false),
        SupportedLanguage(id: "ro", nativeName: "Română", englishName: "Romanian", isRTL: false),
        SupportedLanguage(id: "ru", nativeName: "Русский", englishName: "Russian", isRTL: false),
        SupportedLanguage(id: "sk", nativeName: "Slovenčina", englishName: "Slovak", isRTL: false),
        SupportedLanguage(id: "es", nativeName: "Español", englishName: "Spanish", isRTL: false),
        SupportedLanguage(id: "sv", nativeName: "Svenska", englishName: "Swedish", isRTL: false),
        SupportedLanguage(id: "th", nativeName: "ไทย", englishName: "Thai", isRTL: false),
        SupportedLanguage(id: "tr", nativeName: "Türkçe", englishName: "Turkish", isRTL: false),
        SupportedLanguage(id: "uk", nativeName: "Українська", englishName: "Ukrainian", isRTL: false),
        SupportedLanguage(id: "ur", nativeName: "اردو", englishName: "Urdu", isRTL: true),
        SupportedLanguage(id: "vi", nativeName: "Tiếng Việt", englishName: "Vietnamese", isRTL: false),
        SupportedLanguage(id: "cy", nativeName: "Cymraeg", englishName: "Welsh", isRTL: false),
        SupportedLanguage(id: "af", nativeName: "Afrikaans", englishName: "Afrikaans", isRTL: false),
        SupportedLanguage(id: "sq", nativeName: "Shqip", englishName: "Albanian", isRTL: false),
        SupportedLanguage(id: "am", nativeName: "አማርኛ", englishName: "Amharic", isRTL: false),
        SupportedLanguage(id: "hy", nativeName: "Հայերեն", englishName: "Armenian", isRTL: false),
        SupportedLanguage(id: "az", nativeName: "Azərbaycan", englishName: "Azerbaijani", isRTL: false),
        SupportedLanguage(id: "eu", nativeName: "Euskara", englishName: "Basque", isRTL: false),
        SupportedLanguage(id: "be", nativeName: "Беларуская", englishName: "Belarusian", isRTL: false),
        SupportedLanguage(id: "bn", nativeName: "বাংলা", englishName: "Bengali", isRTL: false),
        SupportedLanguage(id: "bs", nativeName: "Bosanski", englishName: "Bosnian", isRTL: false),
        SupportedLanguage(id: "bg", nativeName: "Български", englishName: "Bulgarian", isRTL: false),
        SupportedLanguage(id: "ca", nativeName: "Català", englishName: "Catalan", isRTL: false),
        SupportedLanguage(id: "hr", nativeName: "Hrvatski", englishName: "Croatian", isRTL: false),
        SupportedLanguage(id: "et", nativeName: "Eesti", englishName: "Estonian", isRTL: false),
        SupportedLanguage(id: "gl", nativeName: "Galego", englishName: "Galician", isRTL: false),
        SupportedLanguage(id: "ka", nativeName: "ქართული", englishName: "Georgian", isRTL: false),
        SupportedLanguage(id: "gu", nativeName: "ગુજરાતી", englishName: "Gujarati", isRTL: false),
        SupportedLanguage(id: "ha", nativeName: "Hausa", englishName: "Hausa", isRTL: false),
        SupportedLanguage(id: "is", nativeName: "Íslenska", englishName: "Icelandic", isRTL: false),
        SupportedLanguage(id: "ig", nativeName: "Igbo", englishName: "Igbo", isRTL: false),
        SupportedLanguage(id: "kn", nativeName: "ಕನ್ನಡ", englishName: "Kannada", isRTL: false),
        SupportedLanguage(id: "kk", nativeName: "Қазақ", englishName: "Kazakh", isRTL: false),
        SupportedLanguage(id: "km", nativeName: "ខ្មែរ", englishName: "Khmer", isRTL: false),
        SupportedLanguage(id: "ky", nativeName: "Кыргызча", englishName: "Kyrgyz", isRTL: false),
        SupportedLanguage(id: "lo", nativeName: "ລາວ", englishName: "Lao", isRTL: false),
        SupportedLanguage(id: "lv", nativeName: "Latviešu", englishName: "Latvian", isRTL: false),
        SupportedLanguage(id: "lt", nativeName: "Lietuvių", englishName: "Lithuanian", isRTL: false),
        SupportedLanguage(id: "mk", nativeName: "Македонски", englishName: "Macedonian", isRTL: false),
        SupportedLanguage(id: "mg", nativeName: "Malagasy", englishName: "Malagasy", isRTL: false),
        SupportedLanguage(id: "ml", nativeName: "മലയാളം", englishName: "Malayalam", isRTL: false),
        SupportedLanguage(id: "mt", nativeName: "Malti", englishName: "Maltese", isRTL: false),
        SupportedLanguage(id: "mi", nativeName: "Māori", englishName: "Maori", isRTL: false),
        SupportedLanguage(id: "mr", nativeName: "मराठी", englishName: "Marathi", isRTL: false),
        SupportedLanguage(id: "mn", nativeName: "Монгол", englishName: "Mongolian", isRTL: false),
        SupportedLanguage(id: "my", nativeName: "မြန်မာ", englishName: "Myanmar", isRTL: false),
        SupportedLanguage(id: "ne", nativeName: "नेपाली", englishName: "Nepali", isRTL: false),
        SupportedLanguage(id: "ps", nativeName: "پښتو", englishName: "Pashto", isRTL: true),
        SupportedLanguage(id: "pa", nativeName: "ਪੰਜਾਬੀ", englishName: "Punjabi", isRTL: false),
        SupportedLanguage(id: "sr", nativeName: "Српски", englishName: "Serbian", isRTL: false),
        SupportedLanguage(id: "si", nativeName: "සිංහල", englishName: "Sinhala", isRTL: false),
        SupportedLanguage(id: "sl", nativeName: "Slovenščina", englishName: "Slovenian", isRTL: false),
        SupportedLanguage(id: "so", nativeName: "Soomaali", englishName: "Somali", isRTL: false),
        SupportedLanguage(id: "sw", nativeName: "Kiswahili", englishName: "Swahili", isRTL: false),
        SupportedLanguage(id: "tl", nativeName: "Filipino", englishName: "Tagalog", isRTL: false),
        SupportedLanguage(id: "tg", nativeName: "Тоҷикӣ", englishName: "Tajik", isRTL: false),
        SupportedLanguage(id: "ta", nativeName: "தமிழ்", englishName: "Tamil", isRTL: false),
        SupportedLanguage(id: "tt", nativeName: "Татар", englishName: "Tatar", isRTL: false),
        SupportedLanguage(id: "te", nativeName: "తెలుగు", englishName: "Telugu", isRTL: false),
        SupportedLanguage(id: "tk", nativeName: "Türkmen", englishName: "Turkmen", isRTL: false),
        SupportedLanguage(id: "ug", nativeName: "ئۇيغۇرچە", englishName: "Uyghur", isRTL: true),
        SupportedLanguage(id: "uz", nativeName: "O'zbek", englishName: "Uzbek", isRTL: false),
        SupportedLanguage(id: "xh", nativeName: "isiXhosa", englishName: "Xhosa", isRTL: false),
        SupportedLanguage(id: "yo", nativeName: "Yorùbá", englishName: "Yoruba", isRTL: false),
        SupportedLanguage(id: "zu", nativeName: "isiZulu", englishName: "Zulu", isRTL: false)
    ]
}

final class LanguageEngine: ObservableObject {
    @Published var supportedLanguages: [SupportedLanguage] = SupportedLanguage.all

    private let apiClient = APIClient.shared

    func language(for id: String) -> SupportedLanguage? {
        supportedLanguages.first { $0.id == id }
    }

    func translate(text: String, to languageCode: String) async throws -> String {
        struct TranslationRequest: Encodable {
            let text: String
            let targetLanguage: String
        }
        struct TranslationResponse: Decodable {
            let translatedText: String
        }

        var request = URLRequest(url: URL(string: "https://api.meridian.io/v1/translate")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TranslationRequest(text: text, targetLanguage: languageCode)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TranslationResponse.self, from: data)
        return response.translatedText
    }

    func searchLanguages(query: String) -> [SupportedLanguage] {
        guard !query.isEmpty else { return supportedLanguages }
        let lower = query.lowercased()
        return supportedLanguages.filter {
            $0.englishName.lowercased().contains(lower) ||
            $0.nativeName.lowercased().contains(lower) ||
            $0.id.lowercased().contains(lower)
        }
    }
}
