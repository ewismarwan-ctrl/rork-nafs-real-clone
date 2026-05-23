import SwiftUI

struct ProgressDashboardView: View {
    let viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    scoreCard
                    xpGrid
                    streakCard
                    weeklyCard
                    recentActivityCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var scoreCard: some View {
        let score = viewModel.discipline.disciplineScore
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discipline Score")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                        .contentTransition(.numericText())
                }
                Spacer()
                Text(viewModel.discipline.rank.rawValue)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(NafsTheme.gold.opacity(0.12))
                    .clipShape(.capsule)
            }
            ProgressView(value: Double(score), total: 100)
                .tint(NafsTheme.gold)
            Text("Build consistency. Discipline earns freedom.")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1))
    }

    private var xpGrid: some View {
        HStack(spacing: 12) {
            metric("Total XP", "\(viewModel.discipline.totalXP)", "sparkles")
            metric("Today", "\(viewModel.discipline.dailyXP)", "sun.max.fill")
            metric("Week", "\(viewModel.discipline.weeklyXP)", "calendar")
        }
    }

    private var streakCard: some View {
        let prayerStreak = PrayerCompletionStore.currentStreakDays()
        let disciplineStreak = viewModel.discipline.currentStreak
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
                Text("\(max(prayerStreak, disciplineStreak)) days")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                Text("Complete worship actions daily to keep it alive.")
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(NafsTheme.gold.opacity(0.45))
        }
        .padding(18)
        .background(NafsTheme.background)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    private var weeklyCard: some View {
        let completed = PrayerCompletionStore.recentDays(7).reduce(0) { $0 + PrayerCompletionStore.completedCount(on: $1) }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Discipline This Week")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            HStack(spacing: 10) {
                metric("Prayers", "\(completed)", "checkmark.seal.fill")
                metric("Earned Today", "\(viewModel.discipline.credits.earnedToday) min", "timer")
                metric("Spent Today", "\(viewModel.discipline.credits.spentToday) min", "lock.open.fill")
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Discipline")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            if viewModel.discipline.eventsToday.isEmpty {
                Text("Complete Salah to earn screen time.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.discipline.eventsToday.prefix(5)) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.action.icon)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                            .frame(width: 22)
                        Text(event.action.title)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                        Spacer()
                        Text("+\(event.xp) XP")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .padding(12)
                    .background(NafsTheme.background)
                    .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
            Text(value)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NafsTheme.background)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }
}
