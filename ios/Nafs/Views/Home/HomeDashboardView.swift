import SwiftUI

struct HomeDashboardView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @Environment(AppNavigationState.self) private var navigationState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    earnedTimeHero
                    lockStatusCard
                    nextPrayerCard
                    nextActionCard
                    disciplineCard
                    lockInButton
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Nafs")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Earn your freedom.")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(NafsTheme.text)
            Text("Nafs helps Muslims earn screen time through worship and discipline.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }

    private var earnedTimeHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Screen Time")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(NafsTheme.subtleText)
                .textCase(.uppercase)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(viewModel.earnedScreenTime.availableMinutes)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(NafsTheme.gold)
                Text("min")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
            }
            Text("Worship first. Dopamine later.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 26))
        .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1) }
    }

    private var lockStatusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "shield.checkered")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
                .frame(width: 44, height: 44)
                .background(NafsTheme.gold.opacity(0.12))
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 3) {
                Text("Current Lock Status")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text("Distractions stay locked until discipline earns freedom.")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            Spacer()
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var nextPrayerCard: some View {
        let next = viewModel.nextPrayer
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Prayer")
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.subtleText)
                Text(next?.name.rawValue ?? "Prayer times loading")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(next.map { "\($0.timeString) · in \(viewModel.nextPrayerCountdown)" } ?? "Open settings if times are missing")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.gold)
            }
            Spacer()
            if let next { Image(systemName: next.name.icon).foregroundStyle(NafsTheme.gold).font(.system(.title2)) }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
    }

    private var nextActionCard: some View {
        let action = viewModel.todayDisciplineActions.first(where: { !$0.isCompletedToday })
        return Button { navigationState.selectedTab = .earn } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Next Earning Action")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                    Text(action?.title ?? "All actions complete")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(action.map { "+\($0.rewardMinutes) min · +\($0.rewardXP) XP" } ?? "Return tomorrow to earn more")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(.title2))
                    .foregroundStyle(NafsTheme.gold)
            }
            .padding(18)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var disciplineCard: some View {
        HStack(spacing: 12) {
            stat("Score", "\(viewModel.discipline.disciplineScore)/100")
            stat("Streak", "\(PrayerCompletionStore.currentStreakDays())d")
            stat("Today", "+\(viewModel.earnedScreenTime.earnedTodayMinutes)m")
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.system(.headline, weight: .bold)).foregroundStyle(NafsTheme.gold)
            Text(title).font(.system(.caption, weight: .semibold)).foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
    }

    private var lockInButton: some View {
        Button { navigationState.selectedTab = .focus } label: {
            Text("Quick Lock In")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(NafsTheme.goldGradient)
                .clipShape(.rect(cornerRadius: 18))
        }
    }
}
