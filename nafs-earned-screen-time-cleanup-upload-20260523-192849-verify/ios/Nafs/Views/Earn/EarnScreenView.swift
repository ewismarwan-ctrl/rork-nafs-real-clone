import SwiftUI

struct EarnScreenView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @Environment(AppNavigationState.self) private var navigationState
    @State private var feedback: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    salahCard
                    earnActionCard(
                        icon: "book.fill",
                        title: "Read Quran",
                        subtitle: "Worship first. Dopamine later.",
                        minutes: HabitType.quran.screenTimeMinutes,
                        xp: DisciplineActionType.quranReading.defaultXP,
                        isComplete: !viewModel.canLogHabit(.quran)
                    ) {
                        complete(.quran, message: "Quran logged. Screen time earned.")
                    }
                    earnActionCard(
                        icon: "hands.sparkles.fill",
                        title: "Complete Dhikr",
                        subtitle: "Build consistency through remembrance.",
                        minutes: HabitType.dhikr.screenTimeMinutes,
                        xp: DisciplineActionType.dhikrSession.defaultXP,
                        isComplete: !viewModel.canLogHabit(.dhikr)
                    ) {
                        complete(.dhikr, message: "Dhikr logged. Discipline earns freedom.")
                    }
                    earnActionCard(
                        icon: "shield.checkered",
                        title: "Start Nafs Lock",
                        subtitle: "Lock in when your nafs starts pulling.",
                        minutes: DisciplineActionType.focusSessionCompleted.dopamineMinutes,
                        xp: DisciplineActionType.focusSessionCompleted.defaultXP,
                        isComplete: false
                    ) {
                        navigationState.selectedTab = .lock
                    }
                    if viewModel.isPremium {
                        earnActionCard(
                            icon: "moon.stars.fill",
                            title: "Reflection",
                            subtitle: "Reset. Rebuild. Keep going.",
                            minutes: DisciplineActionType.muhasabahReflection.dopamineMinutes,
                            xp: DisciplineActionType.muhasabahReflection.defaultXP,
                            isComplete: false
                        ) {
                            viewModel.recordDiscipline(.muhasabahReflection)
                            feedback = "Reflection counted. Keep building."
                        }
                    }

                    if let feedback {
                        Text(feedback)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Earn")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Earn your screen time.")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text("Complete worship actions to unlock dopamine with discipline.")
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
            HStack {
                Text("Available")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                Spacer()
                Text("\(viewModel.discipline.credits.currentAvailableMinutes) min")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1))
    }

    private var salahCard: some View {
        let completed = PrayerCompletionStore.completedCount(on: .now)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Complete Salah")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text("\(completed)/\(PrayerName.allCases.count) prayers completed today")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(HabitType.fardOnTime.screenTimeMinutes) min")
                    Text("+\(DisciplineActionType.prayerOnTime.defaultXP) XP")
                }
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
            }

            HStack(spacing: 8) {
                ForEach(PrayerName.allCases, id: \.rawValue) { prayer in
                    let done = PrayerCompletionStore.isCompleted(prayer, on: .now)
                    Button {
                        guard !done else { return }
                        PrayerCompletionStore.markCompleted(prayer, on: .now)
                        SharedDataService.syncPrayerStreak()
                        viewModel.recordDiscipline(.prayerOnTime, note: prayer.rawValue)
                        feedback = "\(prayer.rawValue) complete. Screen time earned."
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: done ? "checkmark.circle.fill" : prayer.icon)
                                .font(.system(.caption, weight: .semibold))
                            Text(String(prayer.rawValue.prefix(3)))
                                .font(.system(.caption2, weight: .bold))
                        }
                        .foregroundStyle(done ? NafsTheme.gold : NafsTheme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(done ? NafsTheme.gold.opacity(0.12) : NafsTheme.background)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }

    private func earnActionCard(icon: String, title: String, subtitle: String, minutes: Int, xp: Int, isComplete: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: isComplete ? "checkmark.circle.fill" : icon)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isComplete ? "Done" : "+\(minutes) min")
                    if !isComplete {
                        Text("+\(xp) XP")
                    }
                }
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(isComplete ? NafsTheme.subtleText : NafsTheme.gold)
            }
            .padding(16)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isComplete)
    }

    private func complete(_ habit: HabitType, message: String) {
        if viewModel.logHabit(habit) {
            feedback = message
        }
    }
}
