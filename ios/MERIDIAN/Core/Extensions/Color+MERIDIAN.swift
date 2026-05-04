import SwiftUI

extension Color {
    static let meridianPrimary = Color(hex: "#0A2540")
    static let meridianAccent = Color(hex: "#00D4FF")
    static let meridianGold = Color(hex: "#F5A623")
    static let meridianGreen = Color(hex: "#00C896")
    static let meridianRed = Color(hex: "#FF4757")
    static let meridianSurface = Color(hex: "#111827")
    static let meridianBackground = Color(hex: "#070D1A")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func opportunityColour(score: Double) -> Color {
        switch score {
        case 80...: return .meridianGreen
        case 60..<80: return .meridianGold
        default: return .meridianRed
        }
    }

    static func trendColour(_ trend: TrafficTrend) -> Color {
        switch trend {
        case .rising: return .meridianGreen
        case .stable: return .secondary
        case .declining: return .meridianRed
        }
    }

    static func deltaColour(_ delta: Double) -> Color {
        delta >= 0 ? .meridianGreen : .meridianRed
    }
}
