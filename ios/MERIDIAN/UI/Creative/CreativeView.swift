import SwiftUI

struct CreativeView: View {
    @State private var arsenal = CreativeArsenal()
    @State private var urlInput = ""
    @State private var selectedPlatform = CreativePlatform.instagram
    @State private var selectedFormat = CreativeFormat.staticImage
    @State private var selectedFramework = CreativeFramework.aida
    @State private var selectedLanguage = "en"
    @State private var selectedCurrency = "GBP"
    @State private var generatedCreative: Creative?
    @State private var showingHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        CreativeConfigCard(
                            urlInput: $urlInput,
                            selectedPlatform: $selectedPlatform,
                            selectedFormat: $selectedFormat,
                            selectedFramework: $selectedFramework,
                            selectedLanguage: $selectedLanguage,
                            selectedCurrency: $selectedCurrency,
                            isGenerating: arsenal.isGenerating,
                            onGenerate: generateCreative
                        )
                        .padding(.horizontal)

                        if let error = arsenal.lastError {
                            ErrorBanner(message: error) { arsenal.lastError = nil }
                                .padding(.horizontal)
                        }

                        if let creative = generatedCreative {
                            CreativeResultCard(creative: creative)
                                .padding(.horizontal)
                        }

                        if !arsenal.generatedCreatives.isEmpty {
                            SectionHeader(title: "History", count: arsenal.generatedCreatives.count)
                                .padding(.horizontal)
                            ForEach(arsenal.generatedCreatives.prefix(5)) { creative in
                                CreativeHistoryRow(creative: creative) {
                                    arsenal.remove(id: creative.id)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Creative Arsenal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateCreative() {
        Task {
            do {
                let creative = try await arsenal.generate(
                    fromURL: urlInput,
                    platform: selectedPlatform,
                    format: selectedFormat,
                    language: selectedLanguage,
                    framework: selectedFramework,
                    currency: selectedCurrency
                )
                generatedCreative = creative
            } catch {
                // arsenal.lastError is set internally
            }
        }
    }
}

struct CreativeConfigCard: View {
    @Binding var urlInput: String
    @Binding var selectedPlatform: CreativePlatform
    @Binding var selectedFormat: CreativeFormat
    @Binding var selectedFramework: CreativeFramework
    @Binding var selectedLanguage: String
    @Binding var selectedCurrency: String
    let isGenerating: Bool
    let onGenerate: () -> Void

    private let languages = SupportedLanguage.all.prefix(20).map { $0 }
    private let currencies = ["GBP", "USD", "EUR", "JPY", "AUD", "CAD", "CHF", "SGD", "HKD", "NZD"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generate Creative")
                .font(.headline)

            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(Color.meridianAccent.opacity(0.7))
                TextField("Source domain (e.g. nike.com)", text: $urlInput)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            .background(Color.meridianBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Platform")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CreativePlatform.allCases) { platform in
                        PlatformPill(platform: platform, isSelected: selectedPlatform == platform) {
                            selectedPlatform = platform
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Format")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(CreativeFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.meridianAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Framework")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Framework", selection: $selectedFramework) {
                        ForEach(CreativeFramework.allCases) { fw in
                            Text(fw.displayName).tag(fw)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.meridianAccent)
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Language")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages) { lang in
                            Text(lang.englishName).tag(lang.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.meridianAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.meridianAccent)
                }
            }

            Button(action: onGenerate) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(Color.meridianBackground)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Creative")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.meridianBackground)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(urlInput.isEmpty || isGenerating ? Color.meridianAccent.opacity(0.4) : Color.meridianAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(urlInput.isEmpty || isGenerating)
        }
        .padding()
        .meridianCard()
    }
}

struct PlatformPill: View {
    let platform: CreativePlatform
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.caption)
                Text(platform.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.meridianAccent : Color.meridianSurface)
            .foregroundStyle(isSelected ? Color.meridianBackground : Color.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.meridianAccent.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CreativeResultCard: View {
    let creative: Creative

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(creative.platform.displayName)
                        .font(.caption)
                        .foregroundStyle(Color.meridianAccent)
                    Text(creative.title)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(creative.framework.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.meridianGold.opacity(0.15))
                        .foregroundStyle(Color.meridianGold)
                        .clipShape(Capsule())
                    Text(creative.format.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            PlatformPreviewFrame(platform: creative.platform) {
                Text(creative.body)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
            }

            HStack(spacing: 12) {
                ShareLink(item: creative.body) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.meridianAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.meridianAccent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Button {
                    UIPasteboard.general.string = creative.body
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.meridianGold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.meridianGold.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .meridianCard()
    }
}

struct PlatformPreviewFrame<Content: View>: View {
    let platform: CreativePlatform
    @ViewBuilder let content: Content

    private var accentColour: Color {
        switch platform {
        case .instagram: return Color(hex: "#E1306C")
        case .tiktok: return Color(hex: "#69C9D0")
        case .google: return Color(hex: "#4285F4")
        case .linkedin: return Color(hex: "#0A66C2")
        case .snapchat: return Color(hex: "#FFFC00")
        case .pinterest: return Color(hex: "#BD081C")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.caption)
                Text(platform.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(accentColour)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColour.opacity(0.1))

            content
                .padding(12)
        }
        .background(Color.meridianBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(accentColour.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CreativeHistoryRow: View {
    let creative: Creative
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: creative.platform.icon)
                .font(.body)
                .foregroundStyle(Color.meridianAccent)
                .frame(width: 36, height: 36)
                .background(Color.meridianAccent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(creative.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("\(creative.platform.displayName) • \(creative.framework.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.meridianRed.opacity(0.7))
                    .font(.body)
            }
        }
        .padding(12)
        .meridianCard()
    }
}

#Preview {
    CreativeView()
        .preferredColorScheme(.dark)
}
