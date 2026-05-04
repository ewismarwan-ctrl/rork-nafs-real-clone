import Foundation

/// Shared store for daily prayer-completion data, backed by `UserDefaults`.
///
/// Used by `ScreenTimeService` (for prayer-lock unlock logic) and by the
/// Home dashboard, Focus screen, and Progress screen so all surfaces stay
/// in sync.
nonisolated enum PrayerCompletionStore {
    private static let defaults: UserDefaults = .standard

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func key(for prayer: PrayerName, on date: Date) -> String {
        "nafs_prayerComplete_\(dayKey(for: date))_\(prayer.rawValue)"
    }

    static func isCompleted(_ prayer: PrayerName, on date: Date = .now) -> Bool {
        defaults.bool(forKey: key(for: prayer, on: date))
    }

    static func markCompleted(_ prayer: PrayerName, on date: Date = .now) {
        defaults.set(true, forKey: key(for: prayer, on: date))
    }

    static func completedCount(on date: Date = .now) -> Int {
        PrayerName.allCases.reduce(0) { acc, prayer in
            acc + (isCompleted(prayer, on: date) ? 1 : 0)
        }
    }

    static func allCompleted(on date: Date = .now) -> Bool {
        PrayerName.allCases.allSatisfy { isCompleted($0, on: date) }
    }

    /// Number of consecutive days (ending today) where every prayer was completed.
    static func currentStreakDays() -> Int {
        let cal = Calendar.current
        var streak = 0
        var day = Date.now
        for _ in 0..<365 {
            if allCompleted(on: day) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                // Allow today to be in-progress without breaking streak
                if streak == 0 && cal.isDateInToday(day) {
                    guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                    day = prev
                    continue
                }
                break
            }
        }
        return streak
    }

    /// Returns one Date per day for the last `days` days (oldest → newest).
    static func recentDays(_ days: Int, calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: .now)
        return (0..<days).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }
}
