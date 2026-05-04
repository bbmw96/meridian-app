import SwiftUI

struct MQLTerminalView: View {
    @State private var runtime = MQLRuntime(
        intelligenceEngine: IntelligenceEngine(),
        opportunityRadar: OpportunityRadar()
    )
    @State private var inputText = ""
    @State private var showingExamples = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                VStack(spacing: 0) {
                    TerminalOutputArea(runtime: runtime)

                    Divider()
                        .overlay(Color.meridianAccent.opacity(0.3))

                    TerminalInputBar(
                        text: $inputText,
                        isRunning: runtime.isRunning,
                        isFocused: $isInputFocused,
                        onSubmit: submitQuery,
                        onExamples: { showingExamples = true }
                    )
                }
            }
            .navigationTitle("MQL Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { runtime.clearHistory() }
                        .foregroundStyle(Color.meridianRed.opacity(0.8))
                        .disabled(runtime.history.isEmpty)
                }
            }
            .sheet(isPresented: $showingExamples) {
                ExamplesSheet { example in
                    inputText = example
                    showingExamples = false
                    isInputFocused = true
                }
            }
        }
    }

    private func submitQuery() {
        let query = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        inputText = ""
        Task { await runtime.execute(query: query) }
    }
}

struct TerminalOutputArea: View {
    let runtime: MQLRuntime

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if runtime.history.isEmpty {
                        TerminalWelcome()
                            .padding()
                    } else {
                        ForEach(runtime.history) { entry in
                            TerminalEntryView(entry: entry)
                                .padding(.horizontal)
                                .id(entry.id)
                        }
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: runtime.history.count) { _, _ in
                if let first = runtime.history.first {
                    withAnimation { proxy.scrollTo(first.id, anchor: .top) }
                }
            }
        }
    }
}

struct TerminalWelcome: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MERIDIAN Query Language v1.0")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.meridianAccent)
            Text("Type HELP for available commands or use the Examples button.")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("_")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.meridianAccent)
                .pulseAnimation()
        }
    }
}

struct TerminalEntryView: View {
    let entry: MQLEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(">")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.meridianAccent)
                Text(entry.query)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.meridianAccent)
                    .textSelection(.enabled)
                Spacer()
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.isRunning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color.meridianAccent)
                    Text("Executing...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } else if let error = entry.error {
                Text("[ERROR] \(error)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.meridianRed)
                    .textSelection(.enabled)
            } else if let result = entry.result {
                MQLResultView(result: result)
            }
        }
        .padding(12)
        .background(Color.meridianSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.meridianAccent.opacity(0.12), lineWidth: 1)
        )
    }
}

struct MQLResultView: View {
    let result: MQLResult

    var body: some View {
        switch result {
        case .scanResult(let scanResult):
            MQLScanResultView(result: scanResult)
        case .opportunities(let opportunities):
            MQLOpportunitiesView(opportunities: opportunities)
        case .creative(let creative):
            MQLCreativeView(creative: creative)
        case .alert(let alert):
            MQLAlertView(alert: alert)
        case .message(let message):
            Text(message)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}

struct MQLScanResultView: View {
    let result: DomainScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("[SCAN RESULT]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.meridianGreen)
            Text("Domain   : \(result.profile.url)")
                .mqlLine()
            Text("Traffic  : \(result.profile.formattedTraffic)/mo")
                .mqlLine()
            Text("Trend    : \(result.profile.trafficTrend.rawValue.capitalized)")
                .mqlLine()
            Text("Revenue  : £\(String(format: "%.0f", result.profile.estimatedRevenuePounds / 1_000_000))M (est.)")
                .mqlLine()
            Text("Tech     : \(result.profile.technologyStack.prefix(3).joined(separator: ", "))")
                .mqlLine()
            Text("Rivals   : \(result.competitors.count) competitor(s) identified")
                .mqlLine()
        }
    }
}

struct MQLOpportunitiesView: View {
    let opportunities: [Opportunity]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("[OPPORTUNITIES: \(opportunities.count)]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.meridianGreen)
            ForEach(opportunities.prefix(5)) { opp in
                HStack(spacing: 8) {
                    Text(String(format: "%.0f", opp.opportunityScore))
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.opportunityColour(score: opp.opportunityScore))
                        .frame(width: 30, alignment: .trailing)
                    Text("|\(opp.geography)| \(opp.title)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct MQLCreativeView: View {
    let creative: Creative

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("[CREATIVE GENERATED]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.meridianGreen)
            Text("Platform : \(creative.platform.displayName)")
                .mqlLine()
            Text("Title    : \(creative.title)")
                .mqlLine()
        }
    }
}

struct MQLAlertView: View {
    let alert: RateAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("[ALERT CREATED]")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.meridianGreen)
            Text("Pair      : \(alert.pair)")
                .mqlLine()
            Text("Condition : \(alert.description)")
                .mqlLine()
            Text("Status    : Active")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color.meridianGreen)
        }
    }
}

struct TerminalInputBar: View {
    @Binding var text: String
    let isRunning: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onExamples: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MQLAutoComplete(text: $text, onSelect: { text = $0 })

            HStack(spacing: 10) {
                Text(">")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.meridianAccent)

                TextField("Enter MQL query...", text: $text)
                    .font(.system(.body, design: .monospaced))
                    .focused(isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit(onSubmit)

                Button(action: onExamples) {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(Color.meridianGold)
                }

                Button(action: onSubmit) {
                    Group {
                        if isRunning {
                            ProgressView()
                                .tint(Color.meridianBackground)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "return")
                                .foregroundStyle(Color.meridianBackground)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(Color.meridianAccent)
                    .clipShape(Circle())
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.meridianSurface)
        }
    }
}

struct MQLAutoComplete: View {
    @Binding var text: String
    let onSelect: (String) -> Void

    private let keywords = ["SCAN ", "SHOW OPPORTUNITIES WHERE ", "ALERT ", "OPPORTUNITIES", "HELP"]

    private var suggestions: [String] {
        guard !text.isEmpty else { return [] }
        let upper = text.uppercased()
        return keywords.filter { $0.hasPrefix(upper) && $0 != upper }
    }

    var body: some View {
        if !suggestions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            onSelect(suggestion)
                        } label: {
                            Text(suggestion.trimmingCharacters(in: .whitespaces))
                                .font(.system(.caption2, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.meridianPrimary)
                                .foregroundStyle(Color.meridianAccent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Color.meridianBackground)
        }
    }
}

struct ExamplesSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                List {
                    ForEach(MQLRuntime.sampleQueries, id: \.self) { query in
                        Button {
                            onSelect(query)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(query)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(Color.meridianAccent)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Example Queries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private extension View {
    func mqlLine() -> some View {
        self
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(.primary)
            .textSelection(.enabled)
    }
}

#Preview {
    MQLTerminalView()
        .preferredColorScheme(.dark)
}
