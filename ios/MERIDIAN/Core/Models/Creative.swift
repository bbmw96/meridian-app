import Foundation

enum CreativePlatform: String, Codable, CaseIterable, Identifiable {
    case instagram
    case tiktok
    case google
    case linkedin
    case snapchat
    case pinterest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .google: return "Google"
        case .linkedin: return "LinkedIn"
        case .snapchat: return "Snapchat"
        case .pinterest: return "Pinterest"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .google: return "magnifyingglass"
        case .linkedin: return "briefcase.fill"
        case .snapchat: return "bolt.fill"
        case .pinterest: return "pin.fill"
        }
    }
}

enum CreativeFormat: String, Codable, CaseIterable, Identifiable {
    case staticImage
    case ugcVideo
    case carousel
    case story

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .staticImage: return "Static Image"
        case .ugcVideo: return "UGC Video"
        case .carousel: return "Carousel"
        case .story: return "Story"
        }
    }
}

enum CreativeFramework: String, Codable, CaseIterable, Identifiable {
    case aida
    case pas
    case beforeAfterBridge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aida: return "AIDA"
        case .pas: return "PAS"
        case .beforeAfterBridge: return "Before-After-Bridge"
        }
    }

    var description: String {
        switch self {
        case .aida: return "Attention, Interest, Desire, Action"
        case .pas: return "Problem, Agitation, Solution"
        case .beforeAfterBridge: return "Before, After, Bridge"
        }
    }
}

struct Creative: Identifiable, Codable {
    var id: UUID
    var title: String
    var body: String
    var platform: CreativePlatform
    var format: CreativeFormat
    var language: String
    var currency: String
    var framework: CreativeFramework
    var generatedAt: Date
    var imageURL: URL?

    static let preview = Creative(
        id: UUID(),
        title: "Stop Overpaying for Your Online Store",
        body: "Attention: 73% of merchants are leaving revenue on the table every single month.\n\nInterest: What if you could double your conversion rate in 30 days — without spending more on ads?\n\nDesire: MERIDIAN Intelligence reveals the exact traffic gaps your competitors exploit — and shows you how to close them first.\n\nAction: Scan your domain free today. No credit card required.",
        platform: .instagram,
        format: .staticImage,
        language: "en",
        currency: "GBP",
        framework: .aida,
        generatedAt: Date(),
        imageURL: nil
    )
}
