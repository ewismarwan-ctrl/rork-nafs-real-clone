import SwiftUI

struct HabitLoggingView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var loggedHabit: HabitType?
    @State private var showTasbih: Bool = false
    @Environment(LanguageManager.self) private var lang

    private var categories: [(String, [HabitType])] {
        [
            (NafsStrings.prayer.localized, [.fardOnTime, .fardLate]),
            (lang.isArabic ? "القرآن والذكر" : "Quran & Dhikr", [.quran, .dhikr]),
            (lang.isArabic ? "الصيام والعافية" : "Fasting & Wellness", [.voluntaryFast, .exercise, .sleepOnTime]),
            (lang.isArabic ? "التأمل والخطط" : "Reflection & Plans", [.journal, .guidedPlanStep]),
        ]
    }

    var body: some View {
        Group {
            if viewModel.isPremium {
                habitContent
            } else {
                PremiumGateView(
                    icon: "checkmark.seal.fill",
                    title: lang.isArabic ? "تسجيل العادات" : "Habit Logging",
                    subtitle: lang.isArabic ? "أعمالك تستحق أن تُحصى. افتح تسجيل العادات مع نفس بريميوم." : "Your deeds deserve to be counted. Unlock habit logging with Nafs Premium.",
                    storeViewModel: storeViewModel
                )
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(NafsStrings.logHabits.localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showTasbih) {
            TasbihCounterSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }

    private var habitContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(categories, id: \.0) { category, habits in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .textCase(.uppercase)
                            .tracking(1)

                        ForEach(habits) { habit in
                            HabitRow(
                                habit: habit,
                                isLogged: !viewModel.canLogHabit(habit),
                                loggedHabit: $loggedHabit
                            ) {
                                if habit == .dhikr {
                                    showTasbih = true
                                } else {
                                    let _ = viewModel.logHabit(habit)
                                    loggedHabit = habit
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}

struct HabitRow: View {
    let habit: HabitType
    let isLogged: Bool
    @Binding var loggedHabit: HabitType?
    let action: () -> Void
    @State private var burstTrigger: Bool = false
    @Environment(LanguageManager.self) private var lang

    private var localizedName: String {
        guard lang.isArabic else { return habit.rawValue }
        switch habit {
        case .fardOnTime: return "صلاة الفريضة في وقتها"
        case .fardLate: return "صلاة الفريضة متأخرة"
        case .quran: return "القرآن (١٠ دقائق)"
        case .dhikr: return "جلسة ذكر"
        case .voluntaryFast: return "صيام تطوعي"
        case .exercise: return "تمرين"
        case .journal: return "يوميات"
        case .sleepOnTime: return "نوم في الوقت"
        case .guidedPlanStep: return "خطوة خطة إرشادية"
        }
    }

    var body: some View {
        Button(action: {
            if !isLogged {
                burstTrigger.toggle()
                action()
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isLogged ? NafsTheme.gold.opacity(0.15) : NafsTheme.card)
                        .frame(width: 44, height: 44)
                    Image(systemName: habit.icon)
                        .font(.system(.body))
                        .foregroundStyle(isLogged ? NafsTheme.gold : NafsTheme.subtleText)
                        .symbolEffect(.bounce, value: burstTrigger)
                    GoldParticleBurst(trigger: burstTrigger)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedName)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                    HStack(spacing: 6) {
                        Text("+\(habit.tokens) \(NafsStrings.hasanat.localized)")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                        if habit.screenTimeMinutes > 0 {
                            Text("·")
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(NafsTheme.subtleText)
                            HStack(spacing: 3) {
                                Image(systemName: "hourglass")
                                    .font(.system(.caption2, weight: .semibold))
                                Text(lang.isArabic ? "+\(habit.screenTimeMinutes) د شاشة" : "+\(habit.screenTimeMinutes) min screen time")
                                    .font(.system(.caption, weight: .medium))
                            }
                            .foregroundStyle(NafsTheme.gold.opacity(0.8))
                        }
                    }
                }

                Spacer()

                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(NafsTheme.gold)
                } else {
                    Text(NafsStrings.log.localized)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(NafsTheme.goldGradient)
                        .clipShape(.capsule)
                }
            }
            .padding(14)
            .background(isLogged ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isLogged ? NafsTheme.gold.opacity(0.2) : NafsTheme.cardBorder, lineWidth: 1)
            )
        }
        .disabled(isLogged)
        .sensoryFeedback(.impact(weight: .medium), trigger: burstTrigger)
    }
}

struct TasbihCounterSheet: View {
    let viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var count: Int = 0
    @State private var pulseTrigger: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Tasbih Counter")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            Text("سبحان الله")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(NafsTheme.gold)

            ZStack {
                Circle()
                    .stroke(NafsTheme.card, lineWidth: 8)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: min(CGFloat(count) / 100.0, 1.0))
                    .stroke(NafsTheme.goldGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: count)
                Text("\(count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .contentTransition(.numericText())
            }

            Button {
                count += 1
                pulseTrigger.toggle()
                if count >= 100 {
                    let _ = viewModel.logHabit(.dhikr)
                    dismiss()
                }
            } label: {
                Circle()
                    .fill(NafsTheme.goldGradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(.title2))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: NafsTheme.goldShadow, radius: 12, y: 4)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: pulseTrigger)

            Text("\(100 - count) remaining")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .padding(24)
    }
}
