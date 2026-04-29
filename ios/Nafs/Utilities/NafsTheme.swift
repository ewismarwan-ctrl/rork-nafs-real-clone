import SwiftUI
import UIKit

enum NafsTheme {
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "0E0E10")
            : UIColor(hex: "F8F6F1")
    })

    static let card = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "1C1B1F")
            : UIColor(hex: "F0EDE6")
    })

    static let text = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "F2EFE8")
            : UIColor(hex: "2E2A25")
    })

    static let darkText = text

    static let subtleText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "F2EFE8").withAlphaComponent(0.6)
            : UIColor(hex: "2E2A25").withAlphaComponent(0.6)
    })

    static let gold = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "D4B87A")
            : UIColor(hex: "C8A96A")
    })

    static let cardBorder = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "D4B87A").withAlphaComponent(0.18)
            : UIColor(hex: "C8A96A").withAlphaComponent(0.15)
    })

    static let goldShadow = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "D4B87A").withAlphaComponent(0.35)
            : UIColor(hex: "C8A96A").withAlphaComponent(0.3)
    })

    static let goldGradient = LinearGradient(
        colors: [Color(hex: "D4B87A"), Color(hex: "C8A96A"), Color(hex: "B8955A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension UIColor {
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

@MainActor
@Observable
final class AppearanceManager {
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        var arabicName: String {
            switch self {
            case .system: return "النظام"
            case .light: return "فاتح"
            case .dark: return "داكن"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    static let shared = AppearanceManager()

    private static let storageKey = "nafs_appearance"

    var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Appearance.system.rawValue
        self.appearance = Appearance(rawValue: raw) ?? .system
    }
}
