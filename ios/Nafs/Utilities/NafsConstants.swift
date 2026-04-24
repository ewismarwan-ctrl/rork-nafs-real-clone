import Foundation

nonisolated enum NafsConstants {
    static let appStoreID: String = "6761731737"
    static let appStoreURL: String = "https://apps.apple.com/us/app/nafs-islamic-life-companion/id6761731737"
    static let rateAppURL: String = "https://apps.apple.com/app/id6761731737?action=write-review"
    static let rateAppURLItmsApps: String = "itms-apps://itunes.apple.com/app/id6761731737?action=write-review"
    static let privacyPolicyURL: String = "https://docs.google.com/document/d/1SATcvvN_-1Qffx45NTkrZ4BXLxhdroMfMjHsSQSNF1E/edit?usp=sharing"
    static let termsOfUseURL: String = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appGroupID: String = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    static let deepLinkScheme: String = "nafs"

    static func circleInviteURL(circleID: String, circleName: String) -> String {
        let encodedName = circleName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "\(appStoreURL)?circle=\(circleID)&name=\(encodedName)"
    }
}
