import SwiftUI
import Charts

struct CurrencyView: View {
    @State private var engine = CurrencyEngine()
    @State private var fromCurrency = "GBP"
    @State private var toCurrency = "USD"
    @State private var amountText = "1000"
    @State private var showingAddAlert = false
    @State private var selectedPair: CurrencyRate?

    private var convertedAmount: String {
        guard let amount = Double(amountText),
              let result = engine.convert(amount: amount, from: fromCurrency, to: toCurrency) else {
            return "--"
        }
        return String(format: "%.2f", result)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        ConverterCard(
                            fromCurrency: $fromCurrency,
                            toCurrency: $toCurrency,
                            amountText: $amountText,
                            convertedAmount: convertedAmount,
                            engine: engine
                        )
                        .padding(.horizontal)

                        SectionHeader(title: "Live Rates", count: engine.rates.count)
                            .padding(.horizontal)

                        ForEach(engine.rates) { rate in
                            CurrencyRateRow(
                                rate: rate,
                                onAddAlert: { selectedPair = rate; showingAddAlert = true }
                            )
                            .padding(.horizontal)
                        }

                        if !engine.alerts.isEmpty {
                            SectionHeader(title: "Your Alerts", count: engine.alerts.count)
                                .padding(.horizontal)
                            ForEach(engine.alerts) { alert in
                                AlertRow(
                                    alert: alert,
                                    onToggle: { engine.toggleAlert(id: alert.id) },
                                    onDelete: { engine.removeAlert(id: alert.id) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(engine.isLive ? Color.meridianGreen : Color.meridianRed)
                            .frame(width: 8, height: 8)
                        Text(engine.isLive ? "Live" : "Offline")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlert) {
                if let pair = selectedPair {
                    AddAlertSheet(pair: pair, onSave: { alert in
                        engine.addAlert(alert)
                        showingAddAlert = false
                    })
                }
            }
        }
        .task { await engine.startLiveFeed() }
    }
}

struct ConverterCard: View {
    @Binding var fromCurrency: String
    @Binding var toCurrency: String
    @Binding var amountText: String
    let convertedAmount: String
    let engine: CurrencyEngine

    private let commonCurrencies = ["GBP", "USD", "EUR", "JPY", "CHF", "AUD", "CAD", "NZD", "SGD", "HKD"]

    var body: some View {
        VStack(spacing: 14) {
            Text("Converter")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Divider().frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("From", selection: $fromCurrency) {
                        ForEach(commonCurrencies, id: \.self) { Text($0) }
                    }
                    .tint(Color.meridianAccent)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.meridianAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("To", selection: $toCurrency) {
                        ForEach(commonCurrencies, id: \.self) { Text($0) }
                    }
                    .tint(Color.meridianAccent)
                }
            }

            Divider().overlay(Color.meridianAccent.opacity(0.2))

            HStack {
                Text("Result")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(convertedAmount) \(toCurrency)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.meridianAccent)
            }
        }
        .padding()
        .meridianCard()
    }
}

struct CurrencyRateRow: View {
    let rate: CurrencyRate
    let onAddAlert: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rate.id)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(rate.source)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            MiniSparkline(isPositive: rate.isPositive)
                .frame(width: 60, height: 28)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(rate.formattedRate)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                HStack(spacing: 3) {
                    Image(systemName: rate.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(rate.formattedChange)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(rate.isPositive ? Color.meridianGreen : Color.meridianRed)
            }

            Button(action: onAddAlert) {
                Image(systemName: "bell.badge")
                    .font(.body)
                    .foregroundStyle(Color.meridianGold)
            }
        }
        .padding(14)
        .meridianCard()
    }
}

struct MiniSparkline: View {
    let isPositive: Bool
    private let points: [Double] = [0.3, 0.5, 0.4, 0.6, 0.55, 0.7, 0.65, 0.8]

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.0) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(isPositive ? Color.meridianGreen : Color.meridianRed)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct AlertRow: View {
    let alert: RateAlert
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.direction == .above ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(alert.isActive ? Color.meridianGold : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.pair)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(alert.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(get: { alert.isActive }, set: { _ in onToggle() }))
                .tint(Color.meridianAccent)
                .labelsHidden()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.meridianRed)
                    .font(.body)
            }
        }
        .padding(14)
        .meridianCard()
    }
}

struct AddAlertSheet: View {
    let pair: CurrencyRate
    let onSave: (RateAlert) -> Void

    @State private var thresholdText = ""
    @State private var direction = CurrencyDirection.above
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                Form {
                    Section {
                        HStack {
                            Text("Pair")
                            Spacer()
                            Text(pair.id)
                                .foregroundStyle(Color.meridianAccent)
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("Current Rate")
                            Spacer()
                            Text(pair.formattedRate)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Alert Condition") {
                        Picker("Direction", selection: $direction) {
                            ForEach(CurrencyDirection.allCases, id: \.self) { dir in
                                Text(dir.label).tag(dir)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField("Threshold (e.g. 1.30)", text: $thresholdText)
                            .keyboardType(.decimalPad)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let threshold = Double(thresholdText) else { return }
                        let alert = RateAlert(
                            id: UUID(),
                            pair: pair.id,
                            threshold: threshold,
                            direction: direction,
                            isActive: true
                        )
                        onSave(alert)
                    }
                    .disabled(Double(thresholdText) == nil)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.meridianAccent)
                }
            }
        }
    }
}

#Preview {
    CurrencyView()
        .preferredColorScheme(.dark)
}
