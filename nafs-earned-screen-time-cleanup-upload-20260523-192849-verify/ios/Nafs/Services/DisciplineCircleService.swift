import Foundation

@Observable
@MainActor
final class DisciplineCircleService {
    var circle: DisciplineCircle
    var soloChallenges: [DisciplineChallenge]

    init() {
        // TODO: Replace these local demo records with Firebase, Supabase, or CloudKit once account sync exists.
        self.soloChallenges = []
        self.circle = DisciplineCircle(
            id: "local-circle",
            name: "Discipline Circle",
            inviteCode: "",
            members: [],
            activeChallenge: nil
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

}
