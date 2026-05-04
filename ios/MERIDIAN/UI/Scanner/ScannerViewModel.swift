import SwiftUI
import AVFoundation

@Observable
final class ScannerViewModel {

    var inputText: String = ""
    var scanResult: DomainScanResult?
    var isScanning: Bool = false
    var errorMessage: String?
    var isCameraPermissionGranted: Bool = false

    private let intelligenceEngine: IntelligenceEngine
    private let scanner = DomainScanner()

    init(intelligenceEngine: IntelligenceEngine) {
        self.intelligenceEngine = intelligenceEngine
    }

    func scan() async {
        let raw = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        let domain = DomainScanner.normalise(input: raw)
        guard DomainScanner.isValid(domain: domain) else {
            errorMessage = String(localized: "error.scan")
            return
        }
        errorMessage = nil
        isScanning = true
        defer { isScanning = false }
        await intelligenceEngine.scan(domain: domain)
        scanResult = intelligenceEngine.currentScan
        if scanResult == nil {
            errorMessage = intelligenceEngine.error ?? String(localized: "error.scan")
        }
    }

    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isCameraPermissionGranted = true
        case .notDetermined:
            isCameraPermissionGranted = await AVCaptureDevice.requestAccess(for: .video)
        default:
            isCameraPermissionGranted = false
        }
    }

    func handleQRScan(value: String) {
        inputText = value
        Task { await scan() }
    }

    func clearResult() {
        scanResult = nil
        errorMessage = nil
        inputText = ""
    }
}
