import Foundation

@Observable
@MainActor
final class DisciplineCircleService {
    var circle: DisciplineCircle
    var soloChallenges: [DisciplineChallenge]

    init() {
        // TODO: Replace these local demo records with Firebase, Supabase, or CloudKit once account sync exists.
        self.soloChallenges = Self.sampleChallenges
        self.circle = DisciplineCircle(
            id: "demo-circle",
            name: "Nafs Circle",
            inviteCode: "LOCKIN7",
            members: Self.sampleMembers,
            activeChallenge: Self.sampleChallenges.first
        )
    }

    func updateLocalMember(weeklyXP: Int, score: Int, streak: Int, focusSessions: Int, salahConsistency: Int, name: String) {
        let local = DisciplineCircleMember(
            id: "local-user",
            name: name,
            weeklyXP: weeklyXP,
            disciplineScore: score,
            currentStreak: streak,
            completedFocusSessions: focusSessions,
            salahConsistencyPercentage: salahConsistency,
            colorHex: "C8A96A"
        )

        if let index = circle.members.firstIndex(where: { $0.id == local.id }) {
            circle.members[index] = local
        } else {
            circle.members.insert(local, at: 0)
        }
    }

    private static let sampleMembers: [DisciplineCircleMember] = [
        DisciplineCircleMember(id: "local-user", name: "You", weeklyXP: 320, disciplineScore: 76, currentStreak: 4, completedFocusSessions: 3, salahConsistencyPercentage: 82, colorHex: "C8A96A"),
        DisciplineCircleMember(id: "ahmad", name: "Ahmad", weeklyXP: 610, disciplineScore: 88, currentStreak: 9, completedFocusSessions: 5, salahConsistencyPercentage: 94, colorHex: "4F8A8B"),
        DisciplineCircleMember(id: "omar", name: "Omar", weeklyXP: 470, disciplineScore: 79, currentStreak: 6, completedFocusSessions: 4, salahConsistencyPercentage: 86, colorHex: "7C6A9E"),
        DisciplineCircleMember(id: "yusuf", name: "Yusuf", weeklyXP: 280, disciplineScore: 67, currentStreak: 3, completedFocusSessions: 2, salahConsistencyPercentage: 72, colorHex: "B8955A")
    ]

    private static var sampleChallenges: [DisciplineChallenge] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? .now
        return [
            DisciplineChallenge(
                id: "fajr-7",
                title: "7-Day Fajr Challenge",
                description: "Show up for Fajr every day. Start the day by winning against your nafs.",
                startDate: start,
                endDate: end,
                goalType: .fajr,
                progress: 3,
                goal: 7,
                participants: ["You", "Ahmad", "Omar", "Yusuf"],
                isCompleted: false,
                isFailed: false,
                rewardXP: 350,
                rewardDopamineCreditsMinutes: 60
            ),
            DisciplineChallenge(
                id: "lock-in-3",
                title: "3 Lock-In Sessions This Week",
                description: "Use Lock In when urges hit. Reset. Rebuild. Keep going.",
                startDate: start,
                endDate: end,
                goalType: .lockInSessions,
                progress: 1,
                goal: 3,
                participants: ["You"],
                isCompleted: false,
                isFailed: false,
                rewardXP: 180,
                rewardDopamineCreditsMinutes: 30
            )
        ]
    }
}
