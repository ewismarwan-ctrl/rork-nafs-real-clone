import Foundation
import WidgetKit

nonisolated struct SharedPrayerTime: Codable, Sendable {
    let name: String
    let time: Date
}

nonisolated struct SharedPrayerDay: Codable, Sendable {
    let dayStart: Date
    let times: [SharedPrayerTime]
}

enum SharedDataService {
    private static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"

    static var shared: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func syncToWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Push the latest streak + today's completion count to the App Group so widgets can display them.
    static func syncPrayerStreak() {
        guard let shared = shared else { return }
        let streak = PrayerCompletionStore.currentStreakDays()
        let completed = PrayerCompletionStore.completedCount(on: .now)
        let total = PrayerName.allCases.count
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        shared.set(streak, forKey: "nafs_widget_streakDays")
        shared.set(completed, forKey: "nafs_widget_completedToday")
        shared.set(total, forKey: "nafs_widget_totalToday")
        shared.set(f.string(from: .now), forKey: "nafs_widget_completedDateKey")
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

    /// Stores prayer times for multiple upcoming days so widgets remain accurate after midnight.
    static func syncMultiDayPrayerTimes(_ days: [[(name: String, time: Date)]]) {
        guard let shared = shared, !days.isEmpty else { return }
        let cal = Calendar(identifier: .gregorian)
        let payload: [SharedPrayerDay] = days.compactMap { day in
            guard let first = day.first?.time else { return nil }
            let dayStart = cal.startOfDay(for: first)
            let times = day.map { SharedPrayerTime(name: $0.name, time: $0.time) }
            return SharedPrayerDay(dayStart: dayStart, times: times)
        }
        if let data = try? JSONEncoder().encode(payload) {
            shared.set(data, forKey: "nafs_prayerTimesMultiDay")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
