import Foundation
import Observation

@Observable
final class IntelligenceEngine {
    var currentScan: DomainScanResult?
    var recentScans: [DomainProfile] = []
    var isScanning = false
    var error: String?

    private let apiClient = APIClient.shared
    private let cache = CacheManager.shared
    private let scanner = DomainScanner()

    func scan(domain: String) async {
        let normalisedDomain = scanner.normalise(input: domain)
        guard scanner.isValid(domain: normalisedDomain) else {
            error = "Invalid domain: \(domain)"
            return
        }

        if let cached = await cache.retrieveDomain(url: normalisedDomain) {
            let cachedResult = DomainScanResult(profile: cached, competitors: [])
            currentScan = cachedResult
            return
        }

        isScanning = true
        error = nil

        do {
            let result: DomainScanResult = try await apiClient.fetch(.scanDomain(normalisedDomain))
            currentScan = result
            await cache.cacheDomain(result.profile)
            addToRecents(result.profile)
            PersistenceController.shared.saveDomain(result.profile)
        } catch {
            self.error = error.localizedDescription
            loadMockData(for: normalisedDomain)
        }

        isScanning = false
    }

    func refresh() async {
        guard let domain = currentScan?.profile.url else { return }
        await cache.invalidate(key: "domain_\(domain)")
        await scan(domain: domain)
    }

    func clearError() {
        error = nil
    }

    private func addToRecents(_ profile: DomainProfile) {
        recentScans.removeAll { $0.url == profile.url }
        recentScans.insert(profile, at: 0)
        if recentScans.count > 20 {
            recentScans = Array(recentScans.prefix(20))
        }
    }

    private func loadMockData(for domain: String) {
        var mockProfile = DomainProfile.preview
        mockProfile.url = domain
        mockProfile.name = domain.components(separatedBy: ".").first?.capitalized ?? domain
        currentScan = DomainScanResult(profile: mockProfile, competitors: DomainScanResult.preview.competitors)
    }
}
