import SwiftUI

struct EarnScreenView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var completionPulse: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    ForEach(viewModel.todayDisciplineActions) { action in
                        actionCard(action)
                    }
                    Text("Full Quran reader, Dhikr counter, Reflection, and Reciters live in More. Earn here; go deeper there.")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .padding(.horizontal, 4)
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle("Earn")
            .navigationBarTitleDisplayMode(.large)
        }
        .sensoryFeedback(.success, trigger: completionPulse)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Worship first. Dopamine later.")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(NafsTheme.text)
            Text("Complete discipline actions to earn intentional screen time.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
            HStack(spacing: 12) {
                metric("Available", "\(viewModel.earnedScreenTime.availableMinutes)m")
                metric("Earned Today", "\(viewModel.earnedScreenTime.earnedTodayMinutes)m")
                metric("Score", "\(viewModel.discipline.disciplineScore)")
            }
        }
        .padding(22)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(NafsTheme.gold.opacity(0.24), lineWidth: 1) }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.system(.headline, weight: .bold)).foregroundStyle(NafsTheme.gold)
            Text(title).font(.system(.caption2, weight: .semibold)).foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionCard(_ action: DisciplineAction) -> some View {
        Button {
            if viewModel.completeEarnAction(action) { completionPulse += 1 }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(action.isCompletedToday ? NafsTheme.gold : NafsTheme.gold.opacity(0.12)).frame(width: 50, height: 50)
                    Image(systemName: icon(for: action.type))
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(action.isCompletedToday ? .black : NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(action.title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    HStack(spacing: 8) {
                        Text("+\(action.rewardMinutes) min")
                        Text("+\(action.rewardXP) XP")
                    }
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                }
                Spacer()
                Image(systemName: action.isCompletedToday ? "checkmark.circle.fill" : "arrow.up.right.circle")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(action.isCompletedToday ? NafsTheme.gold : NafsTheme.subtleText)
            }
            .padding(18)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(NafsTheme.cardBorder, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .disabled(action.isCompletedToday)
    }

    private func icon(for type: DisciplineActionKind) -> String {
        switch type {
        case .salah: return "checkmark.seal.fill"
        case .quran: return "book.fill"
        case .dhikr: return "hands.sparkles.fill"
        case .reflection: return "moon.stars.fill"
        case .focusSession: return "timer.circle.fill"
        }
    }
}
