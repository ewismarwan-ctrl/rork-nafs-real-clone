import Foundation

nonisolated enum OnboardingScreen: Int, CaseIterable {
    case splash = 0
    case languageSelection
    case identity
    case behavior
    case pain
    case shiftBlame
    case solution
    case coreFeature
    case distractions
    case automation
    case demo
    case reward
    case identityShift
    case paywall
}

nonisolated struct SelectionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String

    init(_ id: String, title: String, icon: String = "") {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

nonisolated struct DistractionApp: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let tint: String
}

nonisolated enum OnboardingDistractions {
    static let apps: [DistractionApp] = [
        DistractionApp(id: "tiktok", name: "TikTok", symbol: "music.note", tint: "FE2C55"),
        DistractionApp(id: "instagram", name: "Instagram", symbol: "camera.fill", tint: "E1306C"),
        DistractionApp(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", tint: "FF0000"),
        DistractionApp(id: "twitter", name: "X / Twitter", symbol: "bubble.left.fill", tint: "1DA1F2"),
        DistractionApp(id: "snapchat", name: "Snapchat", symbol: "bolt.fill", tint: "FFFC00"),
        DistractionApp(id: "reddit", name: "Reddit", symbol: "bubble.left.and.bubble.right.fill", tint: "FF4500"),
    ]

    static let storageKey = "nafs_selectedDistractions"
}
