import SwiftUI

struct ProgressStatsView: View {
    let viewModel: AppViewModel
    var storeViewModel: StoreViewModel? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    earnedStats
                    weeklyConsistency
                    completedActions
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I’m becoming disciplined.")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(NafsTheme.text)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(viewModel.discipline.disciplineScore)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(NafsTheme.gold)
                Text("/100")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            ProgressView(value: Double(viewModel.discipline.disciplineScore), total: 100)
                .tint(NafsTheme.gold)
            Text("\(viewModel.discipline.rank.rawValue) · \(viewModel.discipline.totalXP) XP")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
        }
        .padding(24)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 26))
        .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(NafsTheme.gold.opacity(0.24), lineWidth: 1) }
    }

    private var earnedStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            stat("Available", "\(viewModel.earnedScreenTime.availableMinutes)m", "timer.circle.fill")
            stat("Earned Today", "\(viewModel.earnedScreenTime.earnedTodayMinutes)m", "plus.circle.fill")
            stat("Spent Today", "\(viewModel.earnedScreenTime.spentTodayMinutes)m", "iphone")
            stat("Lifetime Earned", "\(viewModel.earnedScreenTime.lifetimeEarnedMinutes)m", "infinity.circle.fill")
            stat("Prayer Streak", "\(PrayerCompletionStore.currentStreakDays())d", "flame.fill")
            stat("XP Today", "\(viewModel.discipline.dailyXP)", "bolt.fill")
        }
    }

    private func stat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(NafsTheme.gold)
            Text(value).font(.system(.title3, weight: .bold)).foregroundStyle(NafsTheme.text)
            Text(label).font(.system(.caption, weight: .semibold)).foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
    }

    private var weeklyConsistency: some View {
        let days = PrayerCompletionStore.recentDays(7, calendar: .current)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Weekly Consistency")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let completed = PrayerCompletionStore.completedCount(on: day)
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(completed == 5 ? NafsTheme.gold : NafsTheme.cardBorder)
                            .frame(height: CGFloat(max(12, completed * 12)))
                        Text(shortDay(day))
                            .font(.system(.caption2, weight: .bold))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 86, alignment: .bottom)
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var completedActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Today")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            if viewModel.discipline.eventsToday.isEmpty {
                Text("No earned actions yet. Start with one prayer, one page, or one minute of dhikr.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 18))
            } else {
                ForEach(viewModel.discipline.eventsToday) { event in
                    HStack {
                        Image(systemName: event.action.icon).foregroundStyle(NafsTheme.gold).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.note ?? event.action.title).font(.system(.subheadline, weight: .bold)).foregroundStyle(NafsTheme.text)
                            Text("+\(event.dopamineCreditsMinutes) min · +\(event.xp) XP").font(.system(.caption, weight: .semibold)).foregroundStyle(NafsTheme.gold)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 16))
                }
            }
        }
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
