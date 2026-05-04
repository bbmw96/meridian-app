import SwiftUI

@Observable
final class CreativeViewModel {

    var sourceURL: String = ""
    var selectedPlatform: CreativePlatform = .instagram
    var selectedFormat: CreativeFormat = .staticImage
    var selectedFramework: CreativeFramework = .aida
    var selectedLanguage: String = "en-GB"
    var selectedCurrency: String = "GBP"
    var generatedCreative: Creative?
    var isGenerating: Bool = false
    var errorMessage: String?
    var recentCreatives: [Creative] = []

    private let arsenal: CreativeArsenal

    init(arsenal: CreativeArsenal) {
        self.arsenal = arsenal
    }

    func generate() async {
        let url = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }
        do {
            let creative = try await arsenal.generate(
                fromURL: url,
                platform: selectedPlatform,
                format: selectedFormat,
                language: selectedLanguage,
                framework: selectedFramework,
                currency: selectedCurrency
            )
            generatedCreative = creative
            recentCreatives.insert(creative, at: 0)
            if recentCreatives.count > 20 {
                recentCreatives.removeLast()
            }
        } catch {
            errorMessage = String(localized: "error.creative")
        }
    }

    func selectRecent(_ creative: Creative) {
        generatedCreative = creative
    }

    func clearCurrent() {
        generatedCreative = nil
    }

    var canGenerate: Bool {
        !sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }
}
