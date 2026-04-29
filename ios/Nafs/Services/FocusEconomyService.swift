import SwiftUI

nonisolated enum EarnSource: String, Sendable {
    case fard
    case dhikr
    case quran

    var baseMinutes: Int {
        switch self {
        case .fard: return 15
        case .dhikr: return 5
        case .quran: return 10
        }
    }

    var displayName: String {
        switch self {
        case .fard: return "Fard Salah"
        case .dhikr: return "Dhikr"
        case .quran: return "Quran"
        }
    }

    var icon: String {
        switch self {
        case .fard: return "moon.stars.fill"
        case .dhikr: return "hands.sparkles.fill"
        case .quran: return "book.fill"
        }
    }
}

@Observable
@MainActor
final class FocusEconomyService {
    static let dailyCap: Int = 120

    var availableMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_focus_availableMinutes") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_focus_availableMinutes") }
    }

    var todayEarnedMinutes: Int = 0
    var streakDays: Int = 0
    var lastEarnedAmount: Int = 0
    var earnFeedbackTrigger: Int = 0
    var lowBalanceTrigger: Int = 0

    private let defaults: UserDefaults = .standard

    init() {
        rolloverIfNeeded()
        loadStreak()
    }

    var streakMultiplier: Double {
        if streakDays >= 14 { return 1.5 }
        if streakDays >= 7 { return 1.25 }
        if streakDays >= 3 { return 1.1 }
        return 1.0
    }

    var streakMultiplierLabel: String {
        let m = streakMultiplier
        if m == 1.5 { return "1.5x" }
        if m == 1.25 { return "1.25x" }
        if m == 1.1 { return "1.1x" }
        return "1.0x"
    }

    var remainingDailyCap: Int {
        max(0, Self.dailyCap - todayEarnedMinutes)
    }

    @discardableResult
    func earn(from source: EarnSource) -> Int {
        rolloverIfNeeded()
        let multiplied = Int((Double(source.baseMinutes) * streakMultiplier).rounded())
        let allowed = min(multiplied, remainingDailyCap)
        guard allowed > 0 else {
            lastEarnedAmount = 0
            earnFeedbackTrigger &+= 1
            return 0
        }
        availableMinutes += allowed
        todayEarnedMinutes += allowed
        saveTodayEarned()
        bumpStreakIfNeeded()
        lastEarnedAmount = allowed
        earnFeedbackTrigger &+= 1
        return allowed
    }

    @discardableResult
    func spend(minutes: Int) -> Bool {
        guard minutes > 0, availableMinutes >= minutes else {
            lowBalanceTrigger &+= 1
            return false
        }
        availableMinutes -= minutes
        return true
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    private func rolloverIfNeeded() {
        let saved = defaults.string(forKey: "nafs_focus_todayDate") ?? ""
        let today = todayKey()
        if saved != today {
            todayEarnedMinutes = 0
            defaults.set(today, forKey: "nafs_focus_todayDate")
            defaults.set(0, forKey: "nafs_focus_todayEarnedMinutes")
        } else {
            todayEarnedMinutes = defaults.integer(forKey: "nafs_focus_todayEarnedMinutes")
        }
    }

    private func saveTodayEarned() {
        defaults.set(todayEarnedMinutes, forKey: "nafs_focus_todayEarnedMinutes")
    }

    private func loadStreak() {
        streakDays = defaults.integer(forKey: "nafs_focus_streakDays")
    }

    private func bumpStreakIfNeeded() {
        let today = todayKey()
        let last = defaults.string(forKey: "nafs_focus_lastEarnDate") ?? ""
        guard last != today else { return }

        let yesterday = yesterdayKey()
        if last == yesterday {
            streakDays += 1
        } else {
            streakDays = 1
        }
        defaults.set(streakDays, forKey: "nafs_focus_streakDays")
        defaults.set(today, forKey: "nafs_focus_lastEarnDate")
    }

    private func yesterdayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        let date = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        return f.string(from: date)
    }
}
