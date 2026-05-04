import SwiftUI
import Charts
import AVFoundation

struct IntelligenceScannerView: View {
    @State private var engine = IntelligenceEngine()
    @State private var inputText = ""
    @State private var showingCamera = false
    @State private var selectedCompetitor: DomainProfile?

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        ScanInputField(
                            text: $inputText,
                            isScanning: engine.isScanning,
                            onScan: {
                                Task { await engine.scan(domain: inputText) }
                            },
                            onCameraRequest: { showingCamera = true }
                        )
                        .padding(.horizontal)

                        if engine.isScanning {
                            ScanningIndicator()
                                .padding()
                        }

                        if let error = engine.error {
                            ErrorBanner(message: error) { engine.clearError() }
                                .padding(.horizontal)
                        }

                        if let result = engine.currentScan {
                            DomainResultCard(profile: result.profile)
                                .padding(.horizontal)

                            if !result.profile.topKeywords.isEmpty {
                                KeywordsCard(keywords: result.profile.topKeywords)
                                    .padding(.horizontal)
                            }

                            if !result.profile.geographyBreakdown.isEmpty {
                                GeographyCard(breakdown: result.profile.geographyBreakdown)
                                    .padding(.horizontal)
                            }

                            if !result.competitors.isEmpty {
                                CompetitorsSection(
                                    competitors: result.competitors,
                                    selectedCompetitor: $selectedCompetitor
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCamera) {
                QRScannerView { scannedValue in
                    let scanner = DomainScanner()
                    if let domain = scanner.guessFromQRCode(scannedValue) {
                        inputText = domain
                        Task { await engine.scan(domain: domain) }
                    }
                    showingCamera = false
                }
            }
        }
    }
}

struct ScanInputField: View {
    @Binding var text: String
    let isScanning: Bool
    let onScan: () -> Void
    let onCameraRequest: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(Color.meridianAccent.opacity(0.7))
                TextField("domain.com", text: $text)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit(onScan)
                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.meridianSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.meridianAccent.opacity(0.3), lineWidth: 1)
            )

            Button(action: onCameraRequest) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title3)
                    .foregroundStyle(Color.meridianAccent)
                    .frame(width: 46, height: 46)
                    .background(Color.meridianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(action: onScan) {
                Group {
                    if isScanning {
                        ProgressView()
                            .tint(Color.meridianBackground)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundStyle(Color.meridianBackground)
                    }
                }
                .frame(width: 46, height: 46)
                .background(Color.meridianAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isScanning || text.isEmpty)
        }
    }
}

struct ScanningIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(Color.meridianAccent.opacity(0.6 - Double(i) * 0.2), lineWidth: 1.5)
                        .frame(width: 40 + CGFloat(i) * 24, height: 40 + CGFloat(i) * 24)
                        .scaleEffect(phase > 0 ? 1.0 + Double(i) * 0.15 : 1.0)
                        .opacity(phase > 0 ? 1.0 - Double(i) * 0.25 : 0.7)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                            value: phase
                        )
                }
                Image(systemName: "viewfinder.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.meridianAccent)
            }
            .frame(height: 100)
            .onAppear { phase = 1.0 }

            Text("Scanning domain...")
                .font(.subheadline)
                .foregroundStyle(Color.meridianAccent)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DomainResultCard: View {
    let profile: DomainProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(profile.url)
                        .font(.caption)
                        .foregroundStyle(Color.meridianAccent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    AdSpendBadge(level: profile.adSpendSignal)
                    Text("Ad Spend Signal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().overlay(Color.meridianAccent.opacity(0.2))

            HStack(spacing: 20) {
                StatBlock(label: "Traffic", value: profile.formattedTraffic, trend: profile.trafficTrend)
                Spacer()
                StatBlock(label: "Revenue (est.)", value: "£\(String(format: "%.0fM", profile.estimatedRevenuePounds / 1_000_000))", trend: nil)
            }

            if !profile.technologyStack.isEmpty {
                FlowLayout(items: profile.technologyStack) { tech in
                    Text(tech)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.meridianPrimary)
                        .clipShape(Capsule())
                        .foregroundStyle(Color.meridianAccent)
                }
            }
        }
        .padding()
        .meridianCard()
    }
}

struct StatBlock: View {
    let label: String
    let value: String
    let trend: TrafficTrend?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.meridianAccent)
                if let trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundStyle(Color.trendColour(trend))
                }
            }
        }
    }
}

struct AdSpendBadge: View {
    let level: AdSpendLevel
    var colour: Color {
        switch level {
        case .none: return .secondary
        case .low: return .meridianGold
        case .medium: return .orange
        case .high: return .meridianRed
        }
    }
    var body: some View {
        Text(level.displayLabel)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colour.opacity(0.15))
            .foregroundStyle(colour)
            .clipShape(Capsule())
    }
}

struct KeywordsCard: View {
    let keywords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Keywords")
                .font(.headline)
            FlowLayout(items: keywords) { kw in
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                    Text(kw)
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.meridianPrimary.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.primary)
            }
        }
        .padding()
        .meridianCard()
    }
}

struct GeographyCard: View {
    let breakdown: [String: Double]

    private var sorted: [(String, Double)] {
        breakdown.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geography Breakdown")
                .font(.headline)

            Chart {
                ForEach(sorted.prefix(6), id: \.0) { country, share in
                    BarMark(
                        x: .value("Country", country),
                        y: .value("Share", share * 100)
                    )
                    .foregroundStyle(Color.meridianAccent.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))%")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(dash: [2]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                }
            }
        }
        .padding()
        .meridianCard()
    }
}

struct CompetitorsSection: View {
    let competitors: [DomainProfile]
    @Binding var selectedCompetitor: DomainProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Competitors", count: competitors.count)
                .padding(.horizontal)
            ForEach(competitors) { competitor in
                Button {
                    selectedCompetitor = competitor
                } label: {
                    CompetitorDomainRow(profile: competitor)
                        .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CompetitorDomainRow: View {
    let profile: DomainProfile

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.meridianGold)
                .frame(width: 34, height: 34)
                .background(Color.meridianGold.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(profile.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(profile.formattedTraffic)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Image(systemName: profile.trafficTrend.icon)
                    .font(.caption)
                    .foregroundStyle(Color.trendColour(profile.trafficTrend))
            }
        }
        .padding(12)
        .meridianCard()
    }
}

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.meridianRed)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.meridianRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.meridianRed.opacity(0.3), lineWidth: 1)
        )
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .code39, .dataMatrix]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput objects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        captureSession?.stopRunning()
        onScan?(value)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

#Preview {
    IntelligenceScannerView()
        .preferredColorScheme(.dark)
}
