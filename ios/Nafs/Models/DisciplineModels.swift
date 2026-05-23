import Foundation

nonisolated enum DisciplineRank: String, CaseIterable, Codable, Sendable {
    case starting = "Starting"
    case consistent = "Consistent"
    case lockedIn = "Locked In"
    case disciplined = "Disciplined"
    case elite = "Elite"

    static func rank(for xp: Int, score: Int) -> DisciplineRank {
        if xp >= 6000 || score >= 92 { return .elite }
        if xp >= 3000 || score >= 82 { return .disciplined }
        if xp >= 1500 || score >= 70 { return .lockedIn }
        if xp >= 500 || score >= 55 { return .consistent }
        return .starting
    }
}

nonisolated enum DisciplineActionKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case salah
    case quran
    case dhikr
    case reflection
    case focusSession

    var id: String { rawValue }
}

nonisolated struct EarnedScreenTime: Codable, Sendable {
    var availableMinutes: Int
    var earnedTodayMinutes: Int
    var spentTodayMinutes: Int
    var lifetimeEarnedMinutes: Int
}

nonisolated struct DisciplineAction: Identifiable, Codable, Sendable {
    let id: String
    let type: DisciplineActionKind
    var title: String
    var rewardMinutes: Int
    var rewardXP: Int
    var completedAt: Date?

    var isCompletedToday: Bool {
        guard let completedAt else { return false }
        return Calendar.current.isDateInToday(completedAt)
    }

    init(id: String, type: DisciplineActionKind, title: String, rewardMinutes: Int, rewardXP: Int, completedAt: Date? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.rewardMinutes = rewardMinutes
        self.rewardXP = rewardXP
        self.completedAt = completedAt
    }
}

nonisolated enum DisciplineActionType: String, Codable, CaseIterable, Sendable, Identifiable {
    case prayerOnTime
    case salahCompleted
    case quranReading
    case dhikrSession
    case muhasabahReflection
    case focusSessionCompleted
    case lockInSessionCompleted
    case customHabit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prayerOnTime: return "Prayed on time"
        case .salahCompleted: return "Completed Salah"
        case .quranReading: return "Read Quran"
        case .dhikrSession: return "Dhikr session"
        case .muhasabahReflection: return "Muhasabah reflection"
        case .focusSessionCompleted: return "Nafs Lock completed"
        case .lockInSessionCompleted: return "Lock In completed"
        case .customHabit: return "Custom discipline habit"
        }
    }

    var icon: String {
        switch self {
        case .prayerOnTime, .salahCompleted: return "checkmark.seal.fill"
        case .quranReading: return "book.fill"
        case .dhikrSession: return "hands.sparkles.fill"
        case .muhasabahReflection: return "moon.stars.fill"
        case .focusSessionCompleted: return "shield.checkered"
        case .lockInSessionCompleted: return "bolt.shield.fill"
        case .customHabit: return "target"
        }
    }

    var defaultXP: Int {
        switch self {
        case .prayerOnTime: return 50
        case .salahCompleted: return 35
        case .quranReading: return 30
        case .dhikrSession: return 20
        case .muhasabahReflection: return 25
        case .focusSessionCompleted: return 45
        case .lockInSessionCompleted: return 40
        case .customHabit: return 20
        }
    }

    var dopamineMinutes: Int {
        switch self {
        case .prayerOnTime: return 20
        case .salahCompleted: return 20
        case .quranReading: return 10
        case .dhikrSession: return 5
        case .muhasabahReflection: return 5
        case .focusSessionCompleted: return 15
        case .lockInSessionCompleted: return 10
        case .customHabit: return 0
        }
    }
}

nonisolated struct DisciplineEvent: Identifiable, Codable, Sendable {
    let id: String
    let action: DisciplineActionType
    let xp: Int
    let dopamineCreditsMinutes: Int
    let date: Date
    let note: String?

    init(action: DisciplineActionType, xp: Int? = nil, dopamineCreditsMinutes: Int? = nil, date: Date = .now, note: String? = nil) {
        self.id = UUID().uuidString
        self.action = action
        self.xp = xp ?? action.defaultXP
        self.dopamineCreditsMinutes = dopamineCreditsMinutes ?? action.dopamineMinutes
        self.date = date
        self.note = note
    }
}

nonisolated struct DopamineCredits: Codable, Sendable {
    var dopamineCreditsMinutes: Int
    var earnedToday: Int
    var spentToday: Int
    var lifetimeEarned: Int = 0

    var currentAvailableMinutes: Int {
        max(0, dopamineCreditsMinutes)
    }
}

nonisolated enum DisciplinePenaltyType: String, Codable, Sendable {
    case missedPrayer
    case skippedCheckIn
    case brokeFocusEarly
    case missedDailyMinimum

    var title: String {
        switch self {
        case .missedPrayer: return "Missed prayer check"
        case .skippedCheckIn: return "Skipped check-in"
        case .brokeFocusEarly: return "Nafs Lock ended early"
        case .missedDailyMinimum: return "Daily minimum missed"
        }
    }

    var scoreImpact: Int {
        switch self {
        case .missedPrayer: return 4
        case .skippedCheckIn: return 3
        case .brokeFocusEarly: return 5
        case .missedDailyMinimum: return 6
        }
    }
}

nonisolated struct DisciplineDamageEvent: Identifiable, Codable, Sendable {
    let id: String
    let type: DisciplinePenaltyType
    let date: Date
    let scoreImpact: Int
    let message: String

    init(type: DisciplinePenaltyType, date: Date = .now) {
        self.id = UUID().uuidString
        self.type = type
        self.date = date
        self.scoreImpact = type.scoreImpact
        self.message = "Reset. Rebuild. Keep going."
    }
}

nonisolated enum ChallengeGoalType: String, Codable, CaseIterable, Sendable {
    case fajr
    case noTikTokAfterIsha
    case quranMinutes
    case lockInSessions
    case allPrayersOnTime
}

nonisolated struct DisciplineChallenge: Identifiable, Codable, Sendable {
    let id: String
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var goalType: ChallengeGoalType
    var progress: Int
    var goal: Int
    var participants: [String]
    var isCompleted: Bool
    var isFailed: Bool
    var rewardXP: Int
    var rewardDopamineCreditsMinutes: Int

    var progressRatio: Double {
        guard goal > 0 else { return 0 }
        return min(Double(progress) / Double(goal), 1)
    }
}

nonisolated struct DisciplineCircleMember: Identifiable, Codable, Sendable {
    let id: String
    var name: String
    var weeklyXP: Int
    var disciplineScore: Int
    var currentStreak: Int
    var completedFocusSessions: Int
    var salahConsistencyPercentage: Int
    var colorHex: String
}

nonisolated struct DisciplineCircle: Identifiable, Codable, Sendable {
    let id: String
    var name: String
    var inviteCode: String
    var members: [DisciplineCircleMember]
    var activeChallenge: DisciplineChallenge?
}
