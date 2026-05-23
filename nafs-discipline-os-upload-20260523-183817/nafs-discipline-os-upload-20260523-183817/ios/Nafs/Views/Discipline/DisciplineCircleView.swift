import SwiftUI

struct DisciplineCircleView: View {
    let viewModel: AppViewModel

    private var circle: DisciplineCircle {
        viewModel.disciplineCircles.circle
    }

    private var sortedMembers: [DisciplineCircleMember] {
        circle.members.sorted { $0.weeklyXP > $1.weeklyXP }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overviewCard
                challengeCard
                leaderboardCard
                membersCard
                privacyCard
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle("Discipline Circle")
        .navigationBarTitleDisplayMode(.large)
        .task { viewModel.syncCircleStats() }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text("\(circle.members.count)/8 members")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                Text(circle.inviteCode)
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NafsTheme.gold.opacity(0.12))
                    .clipShape(.capsule)
            }

            Text("Private invite-only accountability. No feeds, no likes, no public profiles.")
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var challengeCard: some View {
        if let challenge = circle.activeChallenge {
            VStack(alignment: .leading, spacing: 12) {
                Text("Circle Challenge")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
                Text(challenge.title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(challenge.description)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: challenge.progressRatio)
                    .tint(NafsTheme.gold)
                HStack {
                    Text("\(challenge.progress)/\(challenge.goal)")
                    Spacer()
                    Text("+\(challenge.rewardXP) XP | +\(challenge.rewardDopamineCreditsMinutes) min")
                }
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
            }
            .padding(18)
            .background(NafsTheme.gold.opacity(0.07))
            .clipShape(.rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.gold.opacity(0.18), lineWidth: 1))
        }
    }

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Leaderboard")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                        .frame(width: 24, height: 24)
                        .background(NafsTheme.gold.opacity(0.12))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                        Text("\(member.disciplineScore) score | \(member.currentStreak) day streak")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    Spacer()
                    Text("\(member.weeklyXP) XP")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                }
                .padding(12)
                .background(NafsTheme.background)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    private var membersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Members")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            ForEach(circle.members) { member in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(Color(hex: member.colorHex))
                            .frame(width: 10, height: 10)
                        Text(member.name)
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Spacer()
                        Text("\(member.salahConsistencyPercentage)% Salah")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    HStack(spacing: 8) {
                        statChip("\(member.weeklyXP)", "Weekly XP")
                        statChip("\(member.completedFocusSessions)", "Lock Ins")
                        statChip("\(member.currentStreak)", "Streak")
                    }
                }
                .padding(12)
                .background(NafsTheme.background)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    private var privacyCard: some View {
        Text("Visible: weekly XP, discipline score, streak, Lock In sessions, and Salah consistency. Private: exact app usage, sins, reflections, and missed details.")
            .font(.system(.caption, weight: .medium))
            .foregroundStyle(NafsTheme.subtleText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .background(NafsTheme.gold.opacity(0.06))
            .clipShape(.rect(cornerRadius: 14))
    }

    private func statChip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyChallengesView: View {
    let viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ForEach(viewModel.disciplineCircles.soloChallenges) { challenge in
                    challengeCard(challenge)
                }
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle("Weekly Challenges")
        .navigationBarTitleDisplayMode(.large)
    }

    private func challengeCard(_ challenge: DisciplineChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(NafsTheme.gold)
                Text(challenge.title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
            }
            Text(challenge.description)
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)
                .fixedSize(horizontal: false, vertical: true)
            ProgressView(value: challenge.progressRatio)
                .tint(NafsTheme.gold)
            HStack {
                Text("\(challenge.progress)/\(challenge.goal) complete")
                Spacer()
                Text("+\(challenge.rewardXP) XP | +\(challenge.rewardDopamineCreditsMinutes) min")
            }
            .font(.system(.caption, weight: .semibold))
            .foregroundStyle(NafsTheme.gold)
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }
}
