import SwiftUI

struct QuorumView: View {
    @State private var engine = QuorumEngine()
    @State private var domain = ""
    @State private var inputText = ""
    @State private var selectedCohort: StakeholderCohort = .customer
    @State private var inputs: [(text: String, cohort: StakeholderCohort)] = []
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        QuorumHeaderCard()

                        if let report = engine.currentReport {
                            QuorumScoreCard(report: report)
                            QuorumCohortBreakdown(report: report)
                            if !report.anomalyFlags.isEmpty {
                                QuorumAnomalySection(flags: report.anomalyFlags)
                            }
                        } else {
                            QuorumInputSection(
                                domain: $domain,
                                inputs: $inputs,
                                onAddInput: { showingAddSheet = true }
                            )

                            if !inputs.isEmpty {
                                Button {
                                    Task { await engine.analyse(domain: domain, inputs: inputs) }
                                } label: {
                                    Label("Run QUORUM Analysis", systemImage: "waveform.path.ecg")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.meridianAccent)
                                        .foregroundStyle(.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                                .disabled(engine.isAnalysing || domain.isEmpty)
                            }

                            if engine.isAnalysing {
                                VStack(spacing: 10) {
                                    ProgressView(value: engine.progress)
                                        .tint(Color.meridianAccent)
                                    Text("Aggregating stakeholder signals...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }

                        if engine.currentReport != nil {
                            Button("New Analysis") {
                                engine.currentReport = nil
                                inputs = []
                                domain = ""
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.meridianAccent)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("QUORUM")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddObservationSheet(
                text: $inputText,
                selectedCohort: $selectedCohort,
                onAdd: {
                    inputs.append((inputText, selectedCohort))
                    inputText = ""
                    showingAddSheet = false
                }
            )
        }
    }
}

// MARK: - Sub-views

struct QuorumHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.and.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(Color.meridianAccent)
                Text("Stakeholder Reputation Engine")
                    .font(.headline)
                Spacer()
                Text("ON-DEVICE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
            Text("Aggregates multilingual sentiment across all stakeholder cohorts. Zero data leaves your device.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct QuorumScoreCard: View {
    let report: QuorumReport

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.domain)
                        .font(.title3).fontWeight(.bold)
                    Text("QUORUM Score")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(report.reputationScore))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(report.riskColour))
                    Text(report.riskBand)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Color(report.riskColour))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(report.riskColour))
                        .frame(width: geo.size.width * (report.reputationScore / 1000), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Label("Velocity", systemImage: "arrow.up.right")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(report.velocityDelta > 0 ? "+\(String(format: "%.1f", report.velocityDelta * 100))%" : "\(String(format: "%.1f", report.velocityDelta * 100))%")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(report.velocityDelta >= 0 ? .green : .red)
            }
        }
        .padding(16)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct QuorumCohortBreakdown: View {
    let report: QuorumReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cohort Breakdown")
                .font(.headline)
                .padding(.horizontal)

            ForEach(StakeholderCohort.allCases) { cohort in
                let score = report.cohortScores[cohort] ?? 0
                HStack(spacing: 12) {
                    Image(systemName: cohort.icon)
                        .font(.callout)
                        .foregroundStyle(Color.meridianAccent)
                        .frame(width: 28)

                    Text(cohort.rawValue)
                        .font(.subheadline)
                        .frame(width: 90, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: score >= 0 ? .leading : .trailing) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(score >= 0 ? Color.green : Color.red)
                                .frame(width: geo.size.width * abs(score), height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text(String(format: "%+.2f", score))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(score >= 0 ? .green : .red)
                        .frame(width: 46, alignment: .trailing)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .meridianCard()
        .padding(.horizontal)
    }
}

struct QuorumAnomalySection: View {
    let flags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Anomaly Flags", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(flags, id: \.self) { flag in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(.orange).frame(width: 6, height: 6).padding(.top, 5)
                    Text(flag).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct QuorumInputSection: View {
    @Binding var domain: String
    @Binding var inputs: [(text: String, cohort: StakeholderCohort)]
    let onAddInput: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            TextField("Target domain (e.g. apple.com)", text: $domain)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal)

            if !inputs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Observations (\(inputs.count))")
                        .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                    ForEach(inputs.indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            Image(systemName: StakeholderCohort(rawValue: inputs[i].cohort.rawValue)?.icon ?? "person")
                                .font(.caption)
                                .foregroundStyle(Color.meridianAccent)
                            Text(inputs[i].text)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button { inputs.remove(at: i) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Button(action: onAddInput) {
                Label("Add Observation", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.meridianAccent)
            }
        }
    }
}

struct AddObservationSheet: View {
    @Binding var text: String
    @Binding var selectedCohort: StakeholderCohort
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Stakeholder Cohort") {
                    Picker("Cohort", selection: $selectedCohort) {
                        ForEach(StakeholderCohort.allCases) { cohort in
                            Label(cohort.rawValue, systemImage: cohort.icon).tag(cohort)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                Section("Observation Text") {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
