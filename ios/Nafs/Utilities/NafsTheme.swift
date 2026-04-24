import SwiftUI

enum NafsTheme {
    static let background = Color(hex: "F8F6F1")
    static let gold = Color(hex: "C8A96A")
    static let text = Color(hex: "2E2A25")
    static let card = Color(hex: "F0EDE6")
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "D4B87A"), Color(hex: "C8A96A"), Color(hex: "B8955A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let darkText = Color(hex: "2E2A25")
    static let subtleText = Color(hex: "2E2A25").opacity(0.6)
    static let cardBorder = Color(hex: "C8A96A").opacity(0.15)
    static let goldShadow = Color(hex: "C8A96A").opacity(0.3)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
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
}
