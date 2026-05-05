import SwiftUI
import Charts

struct AxiomView: View {
    @State private var engine = AxiomEngine()
    @State private var question = ""
    @State private var context = ""
    @State private var selectedType: AxiomDecisionType = .marketEntry
    @State private var showingInput = true

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        AxiomHeaderCard()

                        if let model = engine.currentModel, !showingInput {
                            AxiomResultView(model: model) {
                                withAnimation { showingInput = true; engine.currentModel = nil }
                            }
                        } else {
                            AxiomInputView(
                                question: $question,
                                context: $context,
                                selectedType: $selectedType,
                                isModelling: engine.isModelling,
                                progress: engine.progress
                            ) {
                                Task {
                                    await engine.model(question: question, type: selectedType, context: context)
                                    withAnimation { showingInput = false }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("AXIOM")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Header

struct AxiomHeaderCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2).foregroundStyle(Color.meridianAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Decision Intelligence Engine")
                    .font(.subheadline).fontWeight(.semibold)
                Text("On-device scenario modelling · 10,000 case analogues")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("ON-DEVICE")
                .font(.caption2).fontWeight(.bold)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.green.opacity(0.2)).foregroundStyle(.green)
                .clipShape(Capsule())
        }
        .padding(16)
        .meridianCard()
        .padding(.horizontal)
    }
}

// MARK: - Input

struct AxiomInputView: View {
    @Binding var question: String
    @Binding var context: String
    @Binding var selectedType: AxiomDecisionType
    let isModelling: Bool
    let progress: Double
    let onModel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Decision type picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Decision Type").font(.headline).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AxiomDecisionType.allCases) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedType == type ? Color.meridianAccent : Color.white.opacity(0.07))
                                    .foregroundStyle(selectedType == type ? .black : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Decision Question").font(.headline).padding(.horizontal)
                TextField("e.g. Should we enter the Malaysian fintech market in Q3?", text: $question, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
                    .padding(.horizontal)
            }

            // Context
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Context").font(.headline).padding(.horizontal)
                Text("Include: budget, team size, current metrics, timeline, competitors.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                TextField("e.g. We have $2M runway, 12-person team, $800K ARR, 18-month horizon...", text: $context, axis: .vertical)
                    .lineLimit(4...8)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
                    .padding(.horizontal)
            }

            if isModelling {
                VStack(spacing: 8) {
                    ProgressView(value: progress).tint(Color.meridianAccent)
                    Text("AXIOM is modelling your scenarios...")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            } else {
                Button(action: onModel) {
                    Label("Generate Scenario Models", systemImage: "chart.xyaxis.line")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.meridianAccent).foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .disabled(question.isEmpty || context.isEmpty)
            }
        }
    }
}

// MARK: - Results

struct AxiomResultView: View {
    let model: AxiomDecisionModel
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Quality score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.question).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                    Text(model.decisionType.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                CircularQualityScore(score: model.decisionQualityScore)
            }
            .padding(16).meridianCard().padding(.horizontal)

            // Recommended badge
            if let rec = model.recommendedScenario {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AXIOM Recommends: \(rec.label)")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("\(Int(rec.probabilityOfSuccess * 100))% success probability · \(rec.medianTimeToROI) month ROI")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.yellow.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.2)))
                .padding(.horizontal)
            }

            // Scenarios
            Text("Scenario Models").font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            ForEach(model.scenarios) { scenario in
                AxiomScenarioCard(scenario: scenario, isRecommended: scenario.id == model.recommendedScenario?.id)
            }

            // Sensitivity
            AxiomSensitivityCard(rankings: model.sensitivityRankings)

            // Analogues
            if !model.analogueCases.isEmpty {
                AxiomAnaloguesCard(analogues: model.analogueCases)
            }

            Button("New Model", action: onReset)
                .font(.subheadline).foregroundStyle(Color.meridianAccent).padding(.top, 8)
        }
    }
}

struct AxiomScenarioCard: View {
    let scenario: AxiomScenario
    let isRecommended: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scenario.label)
                    .font(.headline)
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(.caption2).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2)).foregroundStyle(.yellow)
                        .clipShape(Capsule())
                }
                Spacer()
                Text("\(Int(scenario.probabilityOfSuccess * 100))%")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(Color(scenario.outcomeColour))
            }

            HStack(spacing: 20) {
                AxiomMetric(label: "Success", value: "\(Int(scenario.probabilityOfSuccess * 100))%", colour: scenario.outcomeColour)
                AxiomMetric(label: "ROI", value: "\(scenario.medianTimeToROI)mo", colour: "meridianAccent")
                AxiomMetric(label: "Capital", value: scenario.capitalRequirement, colour: "white")
            }

            if !scenario.keyRisks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Risks").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    ForEach(scenario.keyRisks.prefix(2), id: \.self) { risk in
                        Label(risk, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .meridianCard()
        .overlay(
            isRecommended ? RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.4), lineWidth: 1) : nil
        )
        .padding(.horizontal)
    }
}

struct AxiomMetric: View {
    let label: String
    let value: String
    let colour: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).fontWeight(.bold).foregroundStyle(Color(colour))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct AxiomSensitivityCard: View {
    let rankings: [(variable: String, impact: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Sensitivity Variables").font(.headline)
            ForEach(rankings.prefix(5), id: \.variable) { item in
                HStack {
                    Text(item.variable).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3).fill(Color.meridianAccent).frame(width: geo.size.width * item.impact, height: 6)
                        }
                    }
                    .frame(height: 6)
                    .frame(width: 80)
                    Text("\(Int(item.impact * 100))%").font(.caption2.monospacedDigit()).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                }
            }
        }
        .padding(16).meridianCard().padding(.horizontal)
    }
}

struct AxiomAnaloguesCard: View {
    let analogues: [AxiomAnalogue]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historical Analogues").font(.headline)
            ForEach(analogues) { analogue in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(analogue.companyArchetype).font(.caption).fontWeight(.semibold)
                        Spacer()
                        Text("\(Int(analogue.relevanceScore * 100))% relevance")
                            .font(.caption2).foregroundStyle(Color.meridianAccent)
                    }
                    Text(analogue.outcome).font(.caption).foregroundStyle(.secondary)
                    Label(analogue.keyLearning, systemImage: "lightbulb.fill")
                        .font(.caption2).foregroundStyle(.orange)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16).meridianCard().padding(.horizontal)
    }
}

struct CircularQualityScore: View {
    let score: Double

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 4)
                Circle().trim(from: 0, to: score).stroke(Color.meridianAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(score * 100))")
                    .font(.caption2.monospacedDigit()).fontWeight(.bold)
            }
            .frame(width: 44, height: 44)
            Text("Input Quality").font(.system(size: 8)).foregroundStyle(.secondary)
        }
    }
}
