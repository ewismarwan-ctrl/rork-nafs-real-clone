import Foundation
import SwiftUI

@Observable
@MainActor
final class DisciplineService {
    private let defaults: UserDefaults = .standard
    private let eventsKey = "nafs_discipline_events_v1"
    private let damageKey = "nafs_discipline_damage_v1"
    private let creditsTotalKey = "nafs_dopamineCredits_total_v1"
    private let creditsDateKey = "nafs_dopamineCredits_date_v1"
    private let creditsEarnedKey = "nafs_dopamineCredits_earned_v1"
    private let creditsSpentKey = "nafs_dopamineCredits_spent_v1"

    var events: [DisciplineEvent] = []
    var damageEvents: [DisciplineDamageEvent] = []
    var credits: DopamineCredits = DopamineCredits(dopamineCreditsMinutes: 0, earnedToday: 0, spentToday: 0)
    var lastEvent: DisciplineEvent?
    var lastDamageMessage: String?

    init() {
        load()
        rolloverCreditsIfNeeded()
    }

    var totalXP: Int {
        events.reduce(0) { $0 + $1.xp }
    }

    var dailyXP: Int {
        eventsToday.reduce(0) { $0 + $1.xp }
    }

    var weeklyXP: Int {
        eventsThisWeek.reduce(0) { $0 + $1.xp }
    }

    var disciplineScore: Int {
        DisciplineDamageService.calculateDailyScore(events: eventsToday, damageEvents: damageToday)
    }

    var rank: DisciplineRank {
        DisciplineRank.rank(for: totalXP, score: disciplineScore)
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        for _ in 0..<365 {
            if hasMinimumDiscipline(on: day, calendar: calendar) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            } else if streak == 0 && calendar.isDateInToday(day) {
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            } else {
                break
            }
        }
        return streak
    }

    var eventsToday: [DisciplineEvent] {
        events.filter { Calendar.current.isDateInToday($0.date) }
    }

    var damageToday: [DisciplineDamageEvent] {
        damageEvents.filter { Calendar.current.isDateInToday($0.date) }
    }

    var eventsThisWeek: [DisciplineEvent] {
        let calendar = Calendar.current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return events.filter { week.contains($0.date) }
    }

    @discardableResult
    func record(_ action: DisciplineActionType, note: String? = nil, xpOverride: Int? = nil, creditsOverride: Int? = nil) -> DisciplineEvent {
        rolloverCreditsIfNeeded()
        let event = DisciplineEvent(action: action, xp: xpOverride, dopamineCreditsMinutes: creditsOverride, note: note)
        events.insert(event, at: 0)
        if event.dopamineCreditsMinutes > 0 {
            credits.dopamineCreditsMinutes += event.dopamineCreditsMinutes
            credits.earnedToday += event.dopamineCreditsMinutes
            saveCredits()
        }
        lastEvent = event
        saveEvents()
        return event
    }

    @discardableResult
    func spendCredits(minutes: Int) -> Bool {
        rolloverCreditsIfNeeded()
        guard minutes > 0, credits.currentAvailableMinutes >= minutes else { return false }
        credits.dopamineCreditsMinutes -= minutes
        credits.spentToday += minutes
        saveCredits()
        return true
    }

    func applyPenalty(_ type: DisciplinePenaltyType) {
        let damage = DisciplineDamageEvent(type: type)
        damageEvents.insert(damage, at: 0)
        lastDamageMessage = damage.message
        saveDamage()
    }

    func checkDailyMinimum() {
        guard !eventsToday.isEmpty else {
            applyPenalty(.missedDailyMinimum)
            return
        }
    }

    private func hasMinimumDiscipline(on date: Date, calendar: Calendar) -> Bool {
        let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayXP = dayEvents.reduce(0) { $0 + $1.xp }
        return dayXP >= 35 || dayEvents.contains(where: { $0.action == .salahCompleted || $0.action == .prayerOnTime })
    }

    private func load() {
        if let data = defaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([DisciplineEvent].self, from: data) {
            events = decoded
        }
        if let data = defaults.data(forKey: damageKey),
           let decoded = try? JSONDecoder().decode([DisciplineDamageEvent].self, from: data) {
            damageEvents = decoded
        }
        credits = DopamineCredits(
            dopamineCreditsMinutes: defaults.integer(forKey: creditsTotalKey),
            earnedToday: defaults.integer(forKey: creditsEarnedKey),
            spentToday: defaults.integer(forKey: creditsSpentKey)
        )
    }

    private func saveEvents() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }

    private func saveDamage() {
        guard let data = try? JSONEncoder().encode(damageEvents) else { return }
        defaults.set(data, forKey: damageKey)
    }

    private func saveCredits() {
        defaults.set(credits.dopamineCreditsMinutes, forKey: creditsTotalKey)
        defaults.set(credits.earnedToday, forKey: creditsEarnedKey)
        defaults.set(credits.spentToday, forKey: creditsSpentKey)
        defaults.set(Self.dayKey(), forKey: creditsDateKey)
    }

    private func rolloverCreditsIfNeeded() {
        let today = Self.dayKey()
        let saved = defaults.string(forKey: creditsDateKey) ?? today
        guard saved != today else { return }
        credits.earnedToday = 0
        credits.spentToday = 0
        saveCredits()
    }

    private static func dayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}

nonisolated enum DisciplineDamageService {
    static func calculateDailyScore(events: [DisciplineEvent], damageEvents: [DisciplineDamageEvent]) -> Int {
        let xpScore = min(events.reduce(0) { $0 + $1.xp } / 2, 70)
        let varietyScore = min(Set(events.map(\.action)).count * 6, 24)
        let base = min(100, 20 + xpScore + varietyScore)
        let penalty = min(35, damageEvents.reduce(0) { $0 + $1.scoreImpact })
        return max(0, base - penalty)
    }
}
