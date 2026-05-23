import SwiftUI

struct DhikrView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var selectedDhikr: DhikrType?
    @State private var dhikrCounts: [DhikrType: Int] = [:]
    @State private var dhikrDailyTotals: [DhikrType: Int] = [:]
    @State private var currentPeriodKey: String = ""
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        dhikrContent
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(lang.isArabic ? "ذكر" : "Dhikr")
        .navigationBarTitleDisplayMode(.large)
    }

    private var dhikrContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                prayerPeriodBadge

                ForEach(DhikrType.allCases) { dhikr in
                    DhikrCard(dhikr: dhikr, count: dhikrCounts[dhikr] ?? 0, isArabic: lang.isArabic) {
                        selectedDhikr = dhikr
                    }
                }

                if allDhikrComplete {
                    allCompleteCard
                }

                totalCard

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .onAppear { refreshCounts() }
        .fullScreenCover(item: $selectedDhikr) { dhikr in
            DhikrCounterView(dhikr: dhikr, initialCount: dhikrCounts[dhikr] ?? 0) { finalCount, increments in
                saveDhikrCount(dhikr, count: finalCount, increments: increments)
                dhikrCounts[dhikr] = finalCount
                dhikrDailyTotals[dhikr] = (dhikrDailyTotals[dhikr] ?? 0) + increments
                if finalCount >= dhikr.target {
                    let _ = viewModel.logHabit(.dhikr)
                }
                selectedDhikr = nil
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("ذِكْر")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(NafsTheme.gold)
            Text(lang.isArabic ? "ذكر الله" : "Remembrance of Allah")
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var prayerPeriodBadge: some View {
        let periodName = currentPrayerPeriodDisplayName
        return HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(.caption, weight: .semibold))
            Text(periodName)
                .font(.system(.caption, weight: .semibold))
        }
        .foregroundStyle(NafsTheme.gold)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(NafsTheme.gold.opacity(0.1))
        .clipShape(.capsule)
    }

    private var currentPrayerPeriodDisplayName: String {
        let period = DhikrPeriodHelper.currentPrayerPeriod(from: viewModel.prayerTimes)
        switch period {
        case "fajr": return lang.isArabic ? "بعد الفجر" : "After Fajr"
        case "dhuhr": return lang.isArabic ? "بعد الظهر" : "After Dhuhr"
        case "asr": return lang.isArabic ? "بعد العصر" : "After Asr"
        case "maghrib": return lang.isArabic ? "بعد المغرب" : "After Maghrib"
        case "isha": return lang.isArabic ? "بعد العشاء" : "After Isha"
        default: return lang.isArabic ? "ذكر اليوم" : "Today's Dhikr"
        }
    }

    private var allDhikrComplete: Bool {
        DhikrType.allCases.allSatisfy { (dhikrCounts[$0] ?? 0) >= $0.target }
    }

    private var allCompleteCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(NafsTheme.gold)
                .symbolEffect(.bounce)

            Text(lang.isArabic ? "ما شاء الله!" : "MashaAllah!")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            Text(lang.isArabic ? "لقد أكملت جميع أذكارك لهذا اليوم." : "You have completed all your dhikr for today.")
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)

            Text(lang.isArabic ? "سبحان الله ٣٣ + الحمد لله ٣٣ + الله أكبر ٣٣ = ٩٩" : "SubhanAllah 33 + Alhamdulillah 33 + Allahu Akbar 33 = 99")
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.gold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [NafsTheme.gold.opacity(0.12), NafsTheme.gold.opacity(0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1.5)
        )
        .transition(.scale.combined(with: .opacity))
    }

    private var totalCard: some View {
        let total = DhikrType.allCases.reduce(0) { $0 + (dhikrDailyTotals[$1] ?? 0) }
        return VStack(spacing: 8) {
            Text(lang.isArabic ? "إجمالي اليوم" : "Today's Total")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .textCase(.uppercase)
                .tracking(1)
            Text("\(total)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
                .contentTransition(.numericText())
            Text(lang.isArabic ? "ذكر محسوب" : "dhikr counted")
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(NafsTheme.gold.opacity(0.06))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.15), lineWidth: 1)
        )
    }

    private func refreshCounts() {
        let periodKey = DhikrPeriodHelper.periodKey(from: viewModel.prayerTimes)
        let dayKey = DhikrPeriodHelper.dayKey()
        if periodKey != currentPeriodKey {
            currentPeriodKey = periodKey
        }
        for dhikr in DhikrType.allCases {
            let key = "nafs_dhikr_\(dhikr.rawValue)_\(periodKey)"
            dhikrCounts[dhikr] = UserDefaults.standard.integer(forKey: key)
            let dailyKey = "nafs_dhikr_daily_\(dhikr.rawValue)_\(dayKey)"
            dhikrDailyTotals[dhikr] = UserDefaults.standard.integer(forKey: dailyKey)
        }
    }

    private func saveDhikrCount(_ dhikr: DhikrType, count: Int, increments: Int) {
        let periodKey = DhikrPeriodHelper.periodKey(from: viewModel.prayerTimes)
        let key = "nafs_dhikr_\(dhikr.rawValue)_\(periodKey)"
        UserDefaults.standard.set(count, forKey: key)

        let dayKey = DhikrPeriodHelper.dayKey()
        let dailyKey = "nafs_dhikr_daily_\(dhikr.rawValue)_\(dayKey)"
        let currentDaily = UserDefaults.standard.integer(forKey: dailyKey)
        UserDefaults.standard.set(currentDaily + increments, forKey: dailyKey)
    }
}

enum DhikrPeriodHelper {
    static func currentPrayerPeriod(from prayerTimes: [PrayerTime]) -> String {
        let now = Date.now
        let sorted = prayerTimes.sorted { $0.time < $1.time }

        var lastPassed: PrayerTime?
        for prayer in sorted {
            if prayer.time <= now {
                lastPassed = prayer
            } else {
                break
            }
        }

        if let last = lastPassed {
            return last.name.rawValue.lowercased()
        }

        return sorted.last.map { $0.name.rawValue.lowercased() } ?? "default"
    }

    static func periodKey(from prayerTimes: [PrayerTime]) -> String {
        let period = currentPrayerPeriod(from: prayerTimes)
        return "\(dayKey())_\(period)"
    }

    static func dayKey() -> String {
        DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
    }
}

nonisolated enum DhikrType: String, CaseIterable, Identifiable, Sendable {
    case subhanAllah = "subhanallah"
    case alhamdulillah = "alhamdulillah"
    case allahuAkbar = "allahu_akbar"

    var id: String { rawValue }

    var arabic: String {
        switch self {
        case .subhanAllah: return "سُبْحَانَ اللَّهِ"
        case .alhamdulillah: return "الْحَمْدُ لِلَّهِ"
        case .allahuAkbar: return "اللَّهُ أَكْبَرُ"
        }
    }

    var transliteration: String {
        switch self {
        case .subhanAllah: return "SubhanAllah"
        case .alhamdulillah: return "Alhamdulillah"
        case .allahuAkbar: return "Allahu Akbar"
        }
    }

    var meaning: String {
        switch self {
        case .subhanAllah: return "Glory be to Allah"
        case .alhamdulillah: return "All praise is due to Allah"
        case .allahuAkbar: return "Allah is the Greatest"
        }
    }

    var meaningArabic: String {
        switch self {
        case .subhanAllah: return "تنزيه الله عن كل نقص"
        case .alhamdulillah: return "الثناء والشكر لله"
        case .allahuAkbar: return "الله أعظم من كل شيء"
        }
    }

    var target: Int { 33 }

    var icon: String {
        switch self {
        case .subhanAllah: return "sparkle"
        case .alhamdulillah: return "heart.fill"
        case .allahuAkbar: return "star.fill"
        }
    }
}

private struct DhikrCard: View {
    let dhikr: DhikrType
    let count: Int
    let isArabic: Bool
    let onTap: () -> Void

    private var isComplete: Bool { count >= dhikr.target }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(NafsTheme.card, lineWidth: 4)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: min(CGFloat(count) / CGFloat(dhikr.target), 1.0))
                        .stroke(NafsTheme.goldGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: isComplete ? "checkmark" : dhikr.icon)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(dhikr.arabic)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(NafsTheme.gold)
                    Text(dhikr.transliteration)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                    Text(isArabic ? dhikr.meaningArabic : dhikr.meaning)
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(isComplete ? NafsTheme.gold : NafsTheme.text)
                        .contentTransition(.numericText())
                    Text("/ \(dhikr.target)")
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .padding(16)
            .background(isComplete ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isComplete ? NafsTheme.gold.opacity(0.2) : NafsTheme.cardBorder, lineWidth: 1)
            )
        }
    }
}

struct DhikrCounterView: View {
    let dhikr: DhikrType
    let initialCount: Int
    let onDone: (Int, Int) -> Void
    @State private var count: Int = 0
    @State private var incrementsAdded: Int = 0
    @State private var pulseTrigger: Bool = false
    @State private var showCompletion: Bool = false
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        onDone(count, incrementsAdded)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                            .frame(width: 40, height: 40)
                            .background(NafsTheme.card)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button {
                        count = 0
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 16) {
                    Text(dhikr.arabic)
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(NafsTheme.gold)
                        .multilineTextAlignment(.center)

                    Text(dhikr.transliteration)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)

                    Text(lang.isArabic ? dhikr.meaningArabic : dhikr.meaning)
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(NafsTheme.card, lineWidth: 6)
                        .frame(width: 200, height: 200)
                    Circle()
                        .trim(from: 0, to: min(CGFloat(count) / CGFloat(dhikr.target), 1.0))
                        .stroke(NafsTheme.goldGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.3), value: count)

                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .contentTransition(.numericText())
                        Text(lang.isArabic ? "من \(dhikr.target)" : "of \(dhikr.target)")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }

                Spacer()

                Button {
                    count += 1
                    incrementsAdded += 1
                    pulseTrigger.toggle()
                    if count == dhikr.target {
                        withAnimation(.spring(response: 0.5)) {
                            showCompletion = true
                        }
                    }
                } label: {
                    Circle()
                        .fill(NafsTheme.goldGradient)
                        .frame(width: 88, height: 88)
                        .overlay {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(.title))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: NafsTheme.goldShadow, radius: 16, y: 6)
                        .scaleEffect(pulseTrigger ? 0.95 : 1.0)
                        .animation(.spring(response: 0.15), value: pulseTrigger)
                }
                .sensoryFeedback(.impact(weight: .light), trigger: pulseTrigger)

                Spacer().frame(height: 40)
            }
            .onAppear { count = initialCount }

            if showCompletion {
                completionOverlay
            }
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showCompletion = false }
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(NafsTheme.gold)
                    .symbolEffect(.bounce)

                Text(lang.isArabic ? "ما شاء الله!" : "MashaAllah!")
                    .font(.system(.title, weight: .bold))
                    .foregroundStyle(NafsTheme.text)

                Text(lang.isArabic ? "\(dhikr.target)× \(dhikr.transliteration) اكتمل" : "\(dhikr.target)x \(dhikr.transliteration) complete")
                    .font(.system(.body))
                    .foregroundStyle(NafsTheme.subtleText)

                NafsButton(title: lang.isArabic ? "متابعة" : "Continue") {
                    withAnimation { showCompletion = false }
                }
                .padding(.horizontal, 40)

                Button {
                    onDone(count, incrementsAdded)
                } label: {
                    Text(lang.isArabic ? "تم" : "Done")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .padding(32)
            .background(NafsTheme.background)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }
}
