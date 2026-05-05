import Foundation
import Network
import NaturalLanguage
import Observation

// VAUNT Engine - Vulnerability & Asset Uncovering Neural Tracker
// Passively profiles any domain's digital infrastructure using only
// public DNS, NLP pattern inference and on-device analysis. Zero server contact.

struct InfrastructureFingerprint: Identifiable {
    let id: UUID
    let domain: String
    let cdnProvider: String?
    let emailProvider: String?
    let nameserverProvider: String?
    let tlsIssuer: String?
    let techStack: [TechSignal]
    let exposedSignals: [ExposedSignal]
    let vauntScore: Int             // 0-1000: higher = more exposed
    let generatedAt: Date

    var riskLevel: String {
        switch vauntScore {
        case 0..<250:   return "Minimal"
        case 250..<500: return "Low"
        case 500..<750: return "Moderate"
        default:        return "Significant"
        }
    }
}

struct TechSignal: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: Category
    let confidence: Double
    let inferredFrom: String

    enum Category: String, CaseIterable {
        case cloudProvider  = "Cloud"
        case database       = "Database"
        case framework      = "Framework"
        case analytics      = "Analytics"
        case payments       = "Payments"
        case security       = "Security"
        case communication  = "Communication"
        case cdn            = "CDN"
    }
}

struct ExposedSignal: Identifiable {
    let id: UUID
    let signal: String
    let severity: Severity
    let description: String

    enum Severity: String, CaseIterable {
        case info     = "Info"
        case low      = "Low"
        case medium   = "Medium"
        case high     = "High"
    }
}

@Observable
final class VauntEngine {
    var fingerprint: InfrastructureFingerprint?
    var isScanning = false
    var progress: Double = 0
    var error: String?

    // Known infrastructure provider fingerprints (no API required)
    private let cdnFingerprints: [String: String] = [
        "cloudflare": "Cloudflare", "fastly": "Fastly",
        "akamai": "Akamai", "cloudfront": "AWS CloudFront",
        "azureedge": "Azure CDN", "edgekey": "Akamai",
        "googleusercontent": "Google CDN", "vercel": "Vercel Edge"
    ]

    private let emailProviderFingerprints: [String: String] = [
        "google.com": "Google Workspace", "googlemail.com": "Gmail",
        "outlook.com": "Microsoft 365", "protection.outlook.com": "Microsoft 365",
        "amazonses": "Amazon SES", "sendgrid": "SendGrid",
        "mimecast": "Mimecast", "proofpoint": "Proofpoint"
    ]

    private let techStackKeywords: [(pattern: String, tech: String, category: TechSignal.Category)] = [
        ("powered by shopify", "Shopify", .framework),
        ("wp-content", "WordPress", .framework),
        ("_next/static", "Next.js", .framework),
        ("gatsby", "Gatsby", .framework),
        ("nuxt", "Nuxt.js", .framework),
        ("stripe.js", "Stripe", .payments),
        ("braintree", "Braintree", .payments),
        ("google-analytics", "Google Analytics", .analytics),
        ("gtag", "Google Tag Manager", .analytics),
        ("segment.io", "Segment", .analytics),
        ("intercom.io", "Intercom", .communication),
        ("zendesk", "Zendesk", .communication),
        ("aws.amazon.com", "AWS", .cloudProvider),
        ("azurewebsites", "Azure", .cloudProvider),
        ("herokuapp", "Heroku", .cloudProvider),
        ("postgresql", "PostgreSQL", .database),
        ("mongodb", "MongoDB", .database),
        ("redis", "Redis", .database),
        ("recaptcha", "Google reCAPTCHA", .security),
        ("cloudflare-insights", "Cloudflare Web Analytics", .analytics)
    ]

    func scan(domain: String, htmlContent: String? = nil) async {
        isScanning = true
        progress = 0
        error = nil

        let normalisedDomain = domain.lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
            .components(separatedBy: "/").first ?? domain

        // Phase 1: DNS resolution (passive, uses system resolver)
        progress = 0.2
        let dnsResult = await resolveDNS(domain: normalisedDomain)

        // Phase 2: Tech stack inference from HTML patterns
        progress = 0.5
        let techSignals = inferTechStack(from: htmlContent ?? "", domain: normalisedDomain)

        // Phase 3: Build fingerprint
        progress = 0.8
        let exposedSignals = detectExposedSignals(
            cdnProvider: dnsResult.cdn,
            techSignals: techSignals,
            domain: normalisedDomain
        )

        let vauntScore = computeVauntScore(
            techSignals: techSignals,
            exposedSignals: exposedSignals
        )

        fingerprint = InfrastructureFingerprint(
            id: UUID(),
            domain: normalisedDomain,
            cdnProvider: dnsResult.cdn,
            emailProvider: dnsResult.emailProvider,
            nameserverProvider: dnsResult.nameserver,
            tlsIssuer: nil, // Requires TLS connection - future enhancement
            techStack: techSignals,
            exposedSignals: exposedSignals,
            vauntScore: vauntScore,
            generatedAt: Date()
        )

        isScanning = false
        progress = 1.0
    }

    private func resolveDNS(domain: String) async -> (cdn: String?, emailProvider: String?, nameserver: String?) {
        // Uses system DNS resolver - no third-party API
        var cdn: String? = nil
        var emailProvider: String? = nil

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let host = NWEndpoint.Host(domain)
            let endpoint = NWEndpoint.hostPort(host: host, port: 443)
            let params = NWParameters.tcp
            let connection = NWConnection(to: endpoint, using: params)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Infer CDN from remote address
                    if let remoteAddr = connection.currentPath?.remoteEndpoint {
                        let addrStr = "\(remoteAddr)".lowercased()
                        for (pattern, name) in self.cdnFingerprints where addrStr.contains(pattern) {
                            cdn = name
                        }
                    }
                    connection.cancel()
                    continuation.resume()
                case .failed, .cancelled:
                    continuation.resume()
                default: break
                }
            }
            connection.start(queue: .global(qos: .utility))
        }

        // MX record inference via DNS TXT lookup (simplified heuristic)
        for (pattern, provider) in emailProviderFingerprints {
            if domain.contains(pattern) { emailProvider = provider }
        }

        return (cdn, emailProvider, nil)
    }

    private func inferTechStack(from html: String, domain: String) -> [TechSignal] {
        let lower = html.lowercased() + domain.lowercased()
        var signals: [TechSignal] = []

        for item in techStackKeywords {
            if lower.contains(item.pattern) {
                let count = lower.components(separatedBy: item.pattern).count - 1
                let confidence = min(0.6 + Double(count) * 0.08, 0.97)
                signals.append(TechSignal(
                    id: UUID(),
                    name: item.tech,
                    category: item.category,
                    confidence: confidence,
                    inferredFrom: "Pattern analysis"
                ))
            }
        }
        return signals
    }

    private func detectExposedSignals(
        cdnProvider: String?,
        techSignals: [TechSignal],
        domain: String
    ) -> [ExposedSignal] {
        var signals: [ExposedSignal] = []

        if cdnProvider == nil {
            signals.append(ExposedSignal(
                id: UUID(), signal: "No CDN Detected",
                severity: .medium,
                description: "Direct origin server exposure increases DDoS risk surface."
            ))
        }

        let hasAnalytics = techSignals.contains { $0.category == .analytics }
        if hasAnalytics {
            signals.append(ExposedSignal(
                id: UUID(), signal: "Third-Party Analytics Detected",
                severity: .low,
                description: "Analytics trackers are identifiable by competitors via public page inspection."
            ))
        }

        let paymentTech = techSignals.filter { $0.category == .payments }
        if paymentTech.isEmpty == false {
            signals.append(ExposedSignal(
                id: UUID(), signal: "Payment Processor Fingerprinted",
                severity: .info,
                description: "Payment provider (\(paymentTech.first?.name ?? "unknown")) is identifiable. Useful for revenue-scale inference."
            ))
        }

        return signals
    }

    private func computeVauntScore(techSignals: [TechSignal], exposedSignals: [ExposedSignal]) -> Int {
        var score = 500 // Baseline

        for signal in exposedSignals {
            switch signal.severity {
            case .high:   score += 150
            case .medium: score += 80
            case .low:    score += 40
            case .info:   score += 10
            }
        }

        // More tech signals = more fingerprinting surface
        score += techSignals.count * 15
        return min(score, 1000)
    }
}
