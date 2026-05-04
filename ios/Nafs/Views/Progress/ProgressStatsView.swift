import SwiftUI

struct ProgressStatsView: View {
    let viewModel: AppViewModel
    var storeViewModel: StoreViewModel? = nil
    @State private var showMonthly: Bool = false
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        Group {
            if viewModel.isPremium {
                progressContent
            } else if let store = storeViewModel {
                PremiumGateView(
                    icon: "chart.bar.fill",
                    title: L10n.text("Progress", "التقدم"),
                    subtitle: L10n.text("Track your spiritual stats and streaks with Nafs Premium.", "تابع إحصائياتك الروحية وسلاسلك مع نفس بريميوم."),
                    storeViewModel: store
                )
            } else {
                progressContent
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("Progress", "التقدم"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var progressContent: some View {
        ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(L10n.text("Your journey, \(viewModel.userName)", "رحلتك، \(viewModel.userName)"))
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                    }
                    .frame(maxWidth: .infinity)

                    weekSummaryCard
                    prayerStreakCard
                    prayerGrid
                    scaleStatus
                    statsGrid
                    quranStreakCard
                    screenTimeCard

                    Picker("", selection: $showMonthly) {
                        Text(L10n.text("This Week", "هذا الأسبوع")).tag(false)
                        Text(L10n.text("This Month", "هذا الشهر")).tag(true)
                    }
                    .pickerStyle(.segmented)

                    bestStreakCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
    }

    private var weekSummaryCard: some View {
        let cal = Calendar.current
        let days = showMonthly ? 30 : 7
        let prayersDone = PrayerCompletionStore.recentDays(days, calendar: cal)
            .reduce(0) { $0 + PrayerCompletionStore.completedCount(on: $1) }
        return HStack(spacing: 12) {
            SummaryStatPill(value: "\(prayersDone)", label: "Prayers", icon: "moon.stars.fill")
            SummaryStatPill(value: "\(viewModel.quranStreak * 10)", label: "Quran min", icon: "book.fill")
            SummaryStatPill(value: "\(PrayerCompletionStore.currentStreakDays())", label: "Streak", icon: "flame.fill")
        }
    }

    private var prayerStreakCard: some View {
        let streak = PrayerCompletionStore.currentStreakDays()
        let cal = Calendar.current
        let days = PrayerCompletionStore.recentDays(7, calendar: cal)
        let todayCount = PrayerCompletionStore.completedCount(on: .now)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("Prayer Streak", "سلسلة الصلاة"))
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .tracking(0.8)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                        Text("\(streak)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                            .contentTransition(.numericText())
                        Text(streak == 1 ? L10n.text("day", "يوم") : L10n.text("days", "أيام"))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(L10n.text("Today", "اليوم"))
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .tracking(0.8)
                    Text("\(todayCount)/\(PrayerName.allCases.count)")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                }
            }

            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let allDone = PrayerCompletionStore.allCompleted(on: day)
                    let isToday = cal.isDateInToday(day)
                    VStack(spacing: 6) {
                        Circle()
                            .fill(allDone ? NafsTheme.gold : NafsTheme.background)
                            .frame(width: 22, height: 22)
                            .overlay {
                                if allDone {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                } else if isToday {
                                    Circle().strokeBorder(NafsTheme.gold, lineWidth: 1.5)
                                }
                            }
                        Text(weekdayLabel(for: day))
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(isToday ? NafsTheme.gold : NafsTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func weekdayLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EE"
        return f.string(from: date)
    }

    private var prayerGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("Prayer Consistency", "انتظام الصلاة"))
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            let days = showMonthly ? ["W1", "W2", "W3", "W4"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("")
                        .font(.system(.caption2))
                        .frame(height: 20)
                    ForEach(PrayerName.allCases, id: \.rawValue) { prayer in
                        Text(String(prayer.rawValue.prefix(3)))
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .frame(height: 20)
                    }
                }
                .frame(width: 36)

                ForEach(days, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text(day)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .frame(height: 20)
                        ForEach(PrayerName.allCases, id: \.rawValue) { prayer in
                            let status = prayerStatus(prayer: prayer, day: day)
                            Circle()
                                .fill(status == .onTime ? NafsTheme.gold : status == .late ? Color(hex: "FFB300") : NafsTheme.card)
                                .frame(width: 16, height: 16)
                                .frame(height: 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(NafsTheme.gold).frame(width: 8, height: 8)
                    Text(L10n.text("On time", "في الوقت")).font(.system(.caption2)).foregroundStyle(NafsTheme.subtleText)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "FFB300")).frame(width: 8, height: 8)
                    Text(L10n.text("Late", "متأخر")).font(.system(.caption2)).foregroundStyle(NafsTheme.subtleText)
                }
                HStack(spacing: 4) {
                    Circle().fill(NafsTheme.card).frame(width: 8, height: 8)
                    Text(L10n.text("Missed", "فائتة")).font(.system(.caption2)).foregroundStyle(NafsTheme.subtleText)
                }
            }
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var scaleStatus: some View {
        VStack(spacing: 12) {
            MizanScaleView(tilt: viewModel.scaleState.tilt, size: 120)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: viewModel.scaleState.tilt)
            Text(scaleLabel)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Text(scaleMessage)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var scaleLabel: String {
        switch viewModel.scaleState {
        case .balanced: return L10n.text("Balanced — Great Week!", "متوازن — أسبوع رائع!")
        case .tippingGold: return L10n.text("Tipping Gold — Good Progress", "تقدم جيد")
        case .tippingDark: return L10n.text("Needs Attention", "يحتاج اهتمام")
        case .fallen: return L10n.text("Time to Reset", "حان وقت البداية الجديدة")
        }
    }

    private var scaleMessage: String {
        switch viewModel.scaleState {
        case .fallen:
            return "Every day is a new beginning. The Prophet \u{FDFA} said: 'All of the children of Adam make mistakes, and the best of those who make mistakes are those who repent.'"
        default:
            return viewModel.scaleState.message
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(label: "Prayer", value: "\(Int(viewModel.prayerConsistency * 100))%", icon: "moon.stars.fill", subtitle: "Weekly consistency")
            StatCard(label: "Quran", value: "\(viewModel.quranStreak) days", icon: "book.fill", subtitle: "Current streak")
            StatCard(label: "Screen Time", value: viewModel.screenTimeReduced > 0 ? "-\(viewModel.screenTimeReduced)%" : "0%", icon: "iphone.slash", subtitle: "vs last week")
            StatCard(label: "Streak", value: "\(PrayerCompletionStore.currentStreakDays()) days", icon: "flame.fill", subtitle: "All prayers complete")
        }
    }

    private var quranStreakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("Quran Streak", "سلسلة القرآن"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.gold)
                    Text("\(viewModel.quranStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                    Text(L10n.text("days in a row", "يوم متتالي"))
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            Spacer()
            Image(systemName: "book.fill")
                .font(.system(size: 36))
                .foregroundStyle(NafsTheme.gold.opacity(0.3))
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var screenTimeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("Screen Time Saved", "وقت الشاشة الموفر"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                Text(L10n.text("You saved \(viewModel.screenTimeReduced) hours this week", "وفرت \(viewModel.screenTimeReduced) ساعات هذا الأسبوع"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Text(L10n.text("that you gave back to your deen", "أعدتها لدينك"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            Spacer()
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundStyle(NafsTheme.gold.opacity(0.3))
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private var bestStreakCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(NafsTheme.gold)
            Text(L10n.text("Your Best Streak", "أفضل سلسلة لك"))
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
            Text("\(viewModel.streakDays) days")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(NafsTheme.gold.opacity(0.06))
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.15), lineWidth: 1)
        )
    }

    private enum PrayerStatus {
        case onTime, late, missed
    }

    private func prayerStatus(prayer: PrayerName, day: String) -> PrayerStatus {
        let cal = Calendar.current
        let date: Date? = {
            if showMonthly {
                guard let weekIndex = Int(day.dropFirst()) else { return nil }
                return cal.date(byAdding: .day, value: -7 * (4 - weekIndex), to: .now)
            } else {
                let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                guard let idx = order.firstIndex(of: day) else { return nil }
                let weekday = cal.component(.weekday, from: .now) // 1=Sun
                let mondayBased = (weekday + 5) % 7 // 0=Mon
                let delta = idx - mondayBased
                return cal.date(byAdding: .day, value: delta, to: .now)
            }
        }()
        guard let date else { return .missed }
        let isFuture = date > .now && !cal.isDateInToday(date)
        if isFuture { return .missed }
        return PrayerCompletionStore.isCompleted(prayer, on: date) ? .onTime : .missed
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(NafsTheme.gold)
            Text(value)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text(subtitle)
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }
}

private struct SummaryStatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.gold)
            Text(value)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }
}
