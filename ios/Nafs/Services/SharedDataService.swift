import Foundation
import WidgetKit

nonisolated struct SharedPrayerTime: Codable, Sendable {
    let name: String
    let time: Date
}

enum SharedDataService {
    private static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"

    static var shared: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func syncToWidgets(balance: Int, weeklyEarned: [Int]) {
        guard let shared = shared else { return }
        shared.set(balance, forKey: "nafs_hasanatBalance")
        if let data = try? JSONEncoder().encode(weeklyEarned) {
            shared.set(data, forKey: "nafs_weeklyEarned")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncPrayerTimes(_ times: [(name: String, time: Date)], locationName: String) {
        guard let shared = shared else { return }
        let payload = times.map { SharedPrayerTime(name: $0.name, time: $0.time) }
        if let data = try? JSONEncoder().encode(payload) {
            shared.set(data, forKey: "nafs_prayerTimes")
        }
        shared.set(locationName, forKey: "nafs_locationName")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
