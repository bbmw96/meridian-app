import SwiftUI
import Translation

struct PrismTranslateView: View {
    @State private var translator = PrismTranslator()
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var targetLanguage: PrismLanguage = PrismLanguage.supported.first { $0.id == "es" }!
    @State private var showLanguagePicker = false
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                VStack(spacing: 0) {
                    PrismHeaderBanner()

                    ScrollView {
                        VStack(spacing: 16) {
                            // Language selector
                            PrismLanguageSelectorRow(
                                targetLanguage: targetLanguage,
                                detectedSource: translator.detectedLanguage,
                                onTapTarget: { showLanguagePicker = true }
                            )

                            // Input
                            PrismInputCard(
                                text: $inputText,
                                detectedLanguage: translator.detectedLanguage,
                                onDetect: { translator.detectLanguage($0) }
                            )

                            // Translate button
                            if !inputText.isEmpty {
                                Button {
                                    triggerTranslation()
                                } label: {
                                    Label("Translate with PRISM", systemImage: "globe.europe.africa.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.meridianAccent)
                                        .foregroundStyle(.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                            }

                            // Output
                            if !translatedText.isEmpty {
                                PrismOutputCard(
                                    text: translatedText,
                                    language: targetLanguage
                                )
                            }

                            // Supported languages grid
                            PrismLanguageTiers()
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("PRISM")
            .navigationBarTitleDisplayMode(.large)
        }
        // Apple Translation framework — on-device, fully offline
        .translationTask(translationConfig) { session in
            do {
                let response = try await session.translate(inputText)
                translatedText = response.targetText
            } catch {
                translatedText = "Translation unavailable for this language pair on this device."
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            PrismLanguagePickerSheet(
                selected: $targetLanguage,
                searchQuery: $searchQuery
            )
        }
    }

    private func triggerTranslation() {
        guard !inputText.isEmpty else { return }
        let sourceId = translator.detectLanguageCode(inputText)
        let source = Locale.Language(identifier: sourceId)
        let target = Locale.Language(identifier: targetLanguage.id)
        translationConfig = TranslationSession.Configuration(source: source, target: target)
    }
}

// MARK: - Sub-views

struct PrismHeaderBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(Color.meridianAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Neural Translation — Fully On-Device")
                    .font(.subheadline).fontWeight(.semibold)
                Text("21 languages · Zero network · Zero API")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
                .font(.callout)
        }
        .padding(14)
        .background(Color.green.opacity(0.08))
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.green.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct PrismLanguageSelectorRow: View {
    let targetLanguage: PrismLanguage
    let detectedSource: PrismLanguage?
    let onTapTarget: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Source (auto-detected)
            VStack(spacing: 4) {
                Text(detectedSource?.nativeName ?? "Detect")
                    .font(.subheadline).fontWeight(.semibold)
                Text(detectedSource?.englishName ?? "Auto-detect")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Image(systemName: "arrow.right")
                .foregroundStyle(Color.meridianAccent)
                .font(.title3)

            // Target (user-selected)
            Button(action: onTapTarget) {
                VStack(spacing: 4) {
                    Text(targetLanguage.nativeName)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(targetLanguage.englishName)
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.meridianAccent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.meridianAccent.opacity(0.4)))
            }
        }
        .padding(.horizontal)
    }
}

struct PrismInputCard: View {
    @Binding var text: String
    let detectedLanguage: PrismLanguage?
    let onDetect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Input")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                Spacer()
                if let lang = detectedLanguage {
                    Label(lang.englishName, systemImage: "globe.badge.chevron.backward")
                        .font(.caption2)
                        .foregroundStyle(Color.meridianAccent)
                }
            }

            TextEditor(text: $text)
                .frame(minHeight: 100, maxHeight: 180)
                .scrollContentBackground(.hidden)
                .onChange(of: text) { _, newValue in
                    if newValue.count > 20 { onDetect(newValue) }
                }

            HStack {
                Text("\(text.count) characters")
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                if !text.isEmpty {
                    Button("Clear") { text = "" }
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct PrismOutputCard: View {
    let text: String
    let language: PrismLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(language.englishName, systemImage: "checkmark.circle.fill")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.green)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.clipboard")
                        .font(.caption2)
                        .foregroundStyle(Color.meridianAccent)
                }
            }

            Text(text)
                .font(.body)
                .environment(\.layoutDirection, language.isRTL ? .rightToLeft : .leftToRight)
                .frame(maxWidth: .infinity, alignment: language.isRTL ? .trailing : .leading)
        }
        .padding(14)
        .background(Color.green.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2)))
        .padding(.horizontal)
    }
}

struct PrismLanguageTiers: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supported Languages")
                .font(.headline)
                .padding(.horizontal)

            ForEach([
                ("Top 5 Most Spoken", PrismLanguage.tier1, "1.circle.fill"),
                ("Global Tier", PrismLanguage.tier2, "2.circle.fill"),
                ("Extended + Malay", PrismLanguage.tier3, "3.circle.fill")
            ], id: \.0) { tier in
                VStack(alignment: .leading, spacing: 8) {
                    Label(tier.0, systemImage: tier.2)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color.meridianAccent)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tier.1) { lang in
                                VStack(spacing: 2) {
                                    Text(lang.nativeName)
                                        .font(.caption2).fontWeight(.semibold)
                                    Text("\(lang.speakers)M")
                                        .font(.system(size: 9)).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct PrismLanguagePickerSheet: View {
    @Binding var selected: PrismLanguage
    @Binding var searchQuery: String
    @Environment(\.dismiss) private var dismiss

    var filtered: [PrismLanguage] {
        guard !searchQuery.isEmpty else { return PrismLanguage.supported }
        let q = searchQuery.lowercased()
        return PrismLanguage.supported.filter {
            $0.englishName.lowercased().contains(q) || $0.nativeName.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { lang in
                Button {
                    selected = lang
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.nativeName).font(.subheadline).fontWeight(.semibold)
                            Text(lang.englishName).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(lang.speakers)M speakers")
                            .font(.caption2).foregroundStyle(.tertiary)
                        if lang.id == selected.id {
                            Image(systemName: "checkmark").foregroundStyle(Color.meridianAccent)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $searchQuery, prompt: "Search languages")
            .navigationTitle("Target Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
