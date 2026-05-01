import SwiftUI

struct HabitLoggingView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var showTasbih: Bool = false
    @State private var showAddHabit: Bool = false
    @Environment(LanguageManager.self) private var lang

    // Curated default habits shown to every user.
    private let coreDailyHabits: [HabitType] = [
        .fardOnTime,    // 5 Daily Prayers
        .quran,         // Quran Reading
        .morningDhikr,
        .eveningDhikr,
        .istighfar,
        .salawat,
    ]

    // Optional habits the user can opt into.
    private let optionalCatalog: [HabitType] = [
        .fajrOnTime,
        .prayInMasjid,
        .noPhoneBeforeFajr,
        .lowerGaze,
        .avoidSin,
        .dailyCharity,
        .dailyDua,
    ]

    private let weeklyHabits: [HabitType] = [
        .jumuah,
        .surahKahf,
        .learningSession,
    ]

    private var enabledOptional: [HabitType] {
        let set = viewModel.optionalHabits
        return optionalCatalog.filter { set.contains($0.rawValue) }
    }

    var body: some View {
        Group {
            if viewModel.isPremium {
                habitContent
            } else {
                PremiumGateView(
                    icon: "checkmark.seal.fill",
                    title: lang.isArabic ? "تسجيل العادات" : "Habit Logging",
                    subtitle: lang.isArabic ? "ابقَ على ثبات. سجّل عباداتك مع نفس بريميوم." : "Stay consistent. Log your acts of worship with Nafs Premium.",
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
        .sheet(isPresented: $showAddHabit) {
            AddOptionalHabitsSheet(viewModel: viewModel, catalog: optionalCatalog)
                .presentationDetents([.medium, .large])
        }
    }

    private var habitContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                section(
                    title: lang.isArabic ? "اليومية" : "Daily",
                    habits: coreDailyHabits
                )

                if !enabledOptional.isEmpty {
                    section(
                        title: lang.isArabic ? "إضافية" : "Optional",
                        habits: enabledOptional
                    )
                }

                addOptionalButton

                section(
                    title: lang.isArabic ? "أسبوعية" : "Weekly",
                    habits: weeklyHabits
                )

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lang.isArabic ? "ابقَ على ثبات" : "Stay consistent")
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Text(lang.isArabic ? "أكمل عباداتك اليوم." : "Complete your habits for today.")
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }

    private func section(title: String, habits: [HabitType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(habits) { habit in
                HabitRow(
                    habit: habit,
                    isLogged: !viewModel.canLogHabit(habit),
                    streak: viewModel.habitStreak(habit)
                ) {
                    if habit == .dhikr {
                        showTasbih = true
                    } else {
                        let _ = viewModel.logHabit(habit)
                    }
                }
            }
        }
    }

    private var addOptionalButton: some View {
        Button {
            showAddHabit = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(.body, weight: .semibold))
                Text(lang.isArabic ? "أضف عادة" : "Add a habit")
                    .font(.system(.subheadline, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .foregroundStyle(NafsTheme.gold)
            .padding(14)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
            )
        }
    }
}

struct HabitRow: View {
    let habit: HabitType
    let isLogged: Bool
    let streak: Int
    let action: () -> Void
    @State private var burstTrigger: Bool = false
    @Environment(LanguageManager.self) private var lang

    private var localizedName: String {
        if lang.isArabic {
            switch habit {
            case .fardOnTime: return "الصلوات الخمس"
            case .fardLate: return "صلاة الفريضة متأخرة"
            case .quran: return "قراءة القرآن"
            case .dhikr: return "جلسة ذكر"
            case .voluntaryFast: return "صيام تطوعي"
            case .exercise: return "تمرين"
            case .journal: return "يوميات"
            case .sleepOnTime: return "نوم في الوقت"
            case .guidedPlanStep: return "خطوة خطة إرشادية"
            case .morningDhikr: return "أذكار الصباح"
            case .eveningDhikr: return "أذكار المساء"
            case .istighfar: return "الاستغفار"
            case .salawat: return "الصلاة على النبي ﷺ"
            case .fajrOnTime: return "الاستيقاظ للفجر في وقته"
            case .prayInMasjid: return "الصلاة في المسجد"
            case .noPhoneBeforeFajr: return "لا هاتف قبل الفجر"
            case .lowerGaze: return "غض البصر"
            case .avoidSin: return "اجتناب ذنب"
            case .dailyCharity: return "صدقة يومية"
            case .dailyDua: return "دعاء يومي"
            case .jumuah: return "صلاة الجمعة"
            case .surahKahf: return "سورة الكهف"
            case .learningSession: return "جلسة تعلم"
            }
        }
        switch habit {
        case .fardOnTime: return "5 Daily Prayers"
        case .quran: return "Quran Reading"
        default: return habit.rawValue
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
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedName)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(.caption2, weight: .semibold))
                            Text(lang.isArabic ? "سلسلة \(streak) \(habit.frequency == .weekly ? "أسبوع" : "يوم")" : "\(streak) \(habit.frequency == .weekly ? "week" : "day") streak")
                                .font(.system(.caption, weight: .medium))
                        }
                        .foregroundStyle(NafsTheme.gold.opacity(0.85))
                    } else {
                        Text(habit.frequency == .weekly ? (lang.isArabic ? "أسبوعي" : "Weekly") : (lang.isArabic ? "يومي" : "Daily"))
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }

                Spacer()

                if isLogged {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.title3))
                        .foregroundStyle(NafsTheme.gold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(.title3))
                        .foregroundStyle(NafsTheme.subtleText.opacity(0.6))
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

struct AddOptionalHabitsSheet: View {
    let viewModel: AppViewModel
    let catalog: [HabitType]
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(catalog) { habit in
                        let isOn = viewModel.optionalHabits.contains(habit.rawValue)
                        Button {
                            viewModel.toggleOptionalHabit(habit)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: habit.icon)
                                    .font(.system(.body))
                                    .foregroundStyle(isOn ? NafsTheme.gold : NafsTheme.subtleText)
                                    .frame(width: 32)
                                Text(localizedName(for: habit))
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                Spacer()
                                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                    .font(.system(.title3))
                                    .foregroundStyle(isOn ? NafsTheme.gold : NafsTheme.subtleText.opacity(0.6))
                            }
                            .padding(14)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(isOn ? NafsTheme.gold.opacity(0.25) : NafsTheme.cardBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(NafsTheme.background)
            .navigationTitle(lang.isArabic ? "أضف عادة" : "Add a habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.isArabic ? "تم" : "Done") { dismiss() }
                        .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }

    private func localizedName(for habit: HabitType) -> String {
        if lang.isArabic {
            switch habit {
            case .fajrOnTime: return "الاستيقاظ للفجر في وقته"
            case .prayInMasjid: return "الصلاة في المسجد"
            case .noPhoneBeforeFajr: return "لا هاتف قبل الفجر"
            case .lowerGaze: return "غض البصر"
            case .avoidSin: return "اجتناب ذنب"
            case .dailyCharity: return "صدقة يومية"
            case .dailyDua: return "دعاء يومي"
            default: return habit.rawValue
            }
        }
        return habit.rawValue
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
