import Foundation

@MainActor
enum PrayerStatsService {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let bestStreakKey = "nafs_bestPrayerStreak"
    private static let allPrayers: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private static func key(for prayer: PrayerName, on date: Date) -> String {
        "nafs_prayerComplete_\(dateFormatter.string(from: date))_\(prayer.rawValue)"
    }

    /// Number of prayers completed on a given calendar day.
    static func completedCount(on date: Date) -> Int {
        let defaults = UserDefaults.standard
        return allPrayers.reduce(0) { sum, p in
            sum + (defaults.bool(forKey: key(for: p, on: date)) ? 1 : 0)
        }
    }

    /// Whether at least one prayer was completed on a given day.
    static func didPrayAnything(on date: Date) -> Bool {
        completedCount(on: date) > 0
    }

    /// Current consecutive-day prayer streak (counts a day if at least 1 prayer was logged).
    /// Includes today only if any prayer completed today; otherwise looks back from yesterday.
    static func currentStreak() -> Int {
        let cal = Calendar.current
        var date = Date.now
        var streak = 0

        // If today has no completions yet, start from yesterday so the streak doesn't drop mid-day.
        if !didPrayAnything(on: date) {
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = prev
        }

        while didPrayAnything(on: date) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
            if streak > 3650 { break } // safety
        }
        return streak
    }

    /// Best streak ever recorded (persisted, auto-updates against current streak).
    static func bestStreak() -> Int {
        let defaults = UserDefaults.standard
        let stored = defaults.integer(forKey: bestStreakKey)
        let current = currentStreak()
        if current > stored {
            defaults.set(current, forKey: bestStreakKey)
            return current
        }
        return stored
    }

    /// Returns 7 days (oldest → today) with completion status.
    struct DayDot: Identifiable {
        let id: String
        let date: Date
        let completedAny: Bool
        let isToday: Bool
        let weekdayLetter: String
    }

    static func lastSevenDays() -> [DayDot] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let symbols = cal.veryShortWeekdaySymbols
        return (0..<7).reversed().compactMap { offset -> DayDot? in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let weekday = cal.component(.weekday, from: d) // 1...7
            let letter = symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "-"
            return DayDot(
                id: dateFormatter.string(from: d),
                date: d,
                completedAny: didPrayAnything(on: d),
                isToday: cal.isDateInToday(d),
                weekdayLetter: letter
            )
        }
    }
}
