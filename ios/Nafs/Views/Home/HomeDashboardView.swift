import SwiftUI

struct HomeDashboardView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var showPanicButton: Bool = false
    @State private var showGarden: Bool = false
    @State private var pendingPrayer: PrayerName? = nil
    @State private var showMarkConfirm: Bool = false
    @State private var showPrayerSuccess: Bool = false
    @State private var lastCompletedPrayer: PrayerName? = nil
    @State private var lastCompletedCount: Int = 0
    @State private var lastCompletedStreak: Int = 0
    @State private var completionTick: Int = 0
    @Environment(LanguageManager.self) private var lang
    @Environment(AppNavigationState.self) private var navigationState

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                    headerSection
                    scaleSection
                    balanceCard
                    prayerStrip
                    focusShortcutCard
                    habitsQuickSummary
                    quickLogRow
                    streakCard
                    gardenPreview
                    ayahCard

                    if !viewModel.isPremium && viewModel.showFreePlanBanner {
                        FreePlanBanner {
                            viewModel.premiumGateFeature = "Nafs Premium"
                            viewModel.premiumGateBenefit = "Unlock all features and take full control of your screen time and spiritual growth."
                            viewModel.showPremiumGate = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 100)
                    }
                    .frame(width: proxy.size.width)
                }
                .scrollClipDisabled(false)
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .clipped()
                .background(NafsTheme.background.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            panicButton
        }
        .fullScreenCover(isPresented: $showPanicButton) {
            PanicButtonView(appViewModel: viewModel)
        }
        .navigationDestination(isPresented: $showGarden) {
            GardenOfDeedsView(viewModel: viewModel, storeViewModel: storeViewModel)
        }
        .confirmationDialog(
            confirmTitle,
            isPresented: $showMarkConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.text("Yes, I’ve prayed", "نعم، لقد صليت")) {
                if let prayer = pendingPrayer { completePrayer(prayer) }
            }
            Button(L10n.text("Not yet", "ليس بعد"), role: .cancel) {
                pendingPrayer = nil
            }
        } message: {
            if let prayer = pendingPrayer {
                Text(L10n.text(
                    "Did you complete your \(NafsStrings.prayerName(prayer)) prayer?",
                    "هل أتممت صلاة \(NafsStrings.prayerName(prayer))؟"
                ))
            }
        }
        .fullScreenCover(isPresented: $showPrayerSuccess) {
            if let prayer = lastCompletedPrayer {
                PrayerSuccessView(
                    prayer: prayer,
                    completedCount: lastCompletedCount,
                    totalCount: PrayerName.allCases.count,
                    streak: lastCompletedStreak,
                    onContinue: { showPrayerSuccess = false }
                )
            }
        }
        }
        }
    }

    private var confirmTitle: String {
        L10n.text("Confirm Prayer", "تأكيد الصلاة")
    }

    private func completePrayer(_ prayer: PrayerName) {
        PrayerCompletionStore.markCompleted(prayer, on: .now)
        let count = PrayerCompletionStore.completedCount(on: .now)
        let streak = PrayerCompletionStore.currentStreakDays()
        lastCompletedPrayer = prayer
        lastCompletedCount = count
        lastCompletedStreak = streak
        completionTick += 1
        let _ = viewModel.logHabit(.fardOnTime)
        pendingPrayer = nil
        showPrayerSuccess = true
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NafsHeaderBrand()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(NafsStrings.assalamuAlaikum.localized), \(viewModel.userName)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text(viewModel.hijriDate)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.gold)
                Text(viewModel.dailyMotivation)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var scaleSection: some View {
        VStack(spacing: 4) {
            MizanScaleView(tilt: viewModel.scaleState.tilt, size: 160)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: viewModel.scaleState.tilt)
        }
        .padding(.vertical, 8)
    }

    private var balanceCard: some View {
        VStack(spacing: 6) {
            Text(NafsStrings.hasanatBalance.localized)
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)
                .tracking(1.5)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.hasanatBalance)")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(NafsTheme.gold)
                    .contentTransition(.numericText())
                Text(NafsStrings.hasanat.localized)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var prayerStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NafsStrings.prayerTimes.localized)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                if let next = viewModel.nextPrayer {
                    Text("\(NafsStrings.prayerName(next.name)) \(lang.isArabic ? "بعد" : "in") \(viewModel.nextPrayerCountdown)")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.gold)
                }
            }

            let rows: [[PrayerTime]] = stride(from: 0, to: viewModel.prayerTimes.count, by: 3).map {
                Array(viewModel.prayerTimes[$0 ..< min($0 + 3, viewModel.prayerTimes.count)])
            }

            VStack(spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 8) {
                        ForEach(row) { prayer in
                            let _ = completionTick
                            let done = PrayerCompletionStore.isCompleted(prayer.name, on: .now)
                            Button {
                                pendingPrayer = prayer.name
                                showMarkConfirm = true
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Image(systemName: prayer.name.icon)
                                            .font(.system(.caption))
                                            .foregroundStyle(done ? NafsTheme.gold : (prayer.isNext ? .white : NafsTheme.subtleText))
                                        if done {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(.caption2, weight: .bold))
                                                .foregroundStyle(NafsTheme.gold)
                                                .background(Circle().fill(NafsTheme.card).frame(width: 12, height: 12))
                                                .offset(x: 9, y: -9)
                                        }
                                    }
                                    Text(NafsStrings.prayerName(prayer.name))
                                        .font(.system(.caption2, weight: .semibold))
                                        .foregroundStyle(done ? NafsTheme.gold : (prayer.isNext ? .white : NafsTheme.text))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(prayer.timeString)
                                        .font(.system(.caption2))
                                        .foregroundStyle(done ? NafsTheme.gold.opacity(0.8) : (prayer.isNext ? .white.opacity(0.8) : NafsTheme.subtleText))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(done ? NafsTheme.gold.opacity(0.12) : (prayer.isNext ? NafsTheme.gold : Color.clear))
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay {
                                    if done {
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(NafsTheme.gold.opacity(0.4), lineWidth: 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(done)
                        }

                        if row.count < 3 {
                            ForEach(0..<(3 - row.count), id: \.self) { _ in
                                Color.clear
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(4)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var quickLogRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NafsStrings.quickLog.localized)
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            HStack(spacing: 12) {
                if viewModel.isPremium {
                    QuickLogButton(
                        icon: "checkmark.seal.fill",
                        label: NafsStrings.salah.localized,
                        tokens: 50,
                        isLogged: !viewModel.canLogHabit(.fardOnTime)
                    ) {
                        let _ = viewModel.logHabit(.fardOnTime)
                    }
                    .frame(maxWidth: .infinity)

                    QuickLogButton(
                        icon: "book.fill",
                        label: NafsStrings.quranLabel.localized,
                        tokens: 30,
                        isLogged: !viewModel.canLogHabit(.quran)
                    ) {
                        let _ = viewModel.logHabit(.quran)
                    }
                    .frame(maxWidth: .infinity)

                    QuickLogButton(
                        icon: "hands.sparkles.fill",
                        label: NafsStrings.dhikrLabel.localized,
                        tokens: 20,
                        isLogged: !viewModel.canLogHabit(.dhikr)
                    ) {
                        let _ = viewModel.logHabit(.dhikr)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button {
                        viewModel.premiumGateFeature = lang.isArabic ? "تسجيل العادات" : "Habit Logging"
                        viewModel.premiumGateBenefit = lang.isArabic ? "أعمالك تستحق أن تُحصى. افتح جميع الميزات مع نفس بريميوم." : "Your deeds deserve to be counted. Unlock all features with Nafs Premium."
                        viewModel.showPremiumGate = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(.caption))
                                .foregroundStyle(NafsTheme.gold)
                            Text(lang.isArabic ? "افتح تسجيل العادات مع بريميوم" : "Unlock habit logging with Premium")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(NafsTheme.text)
                            Spacer()
                            Text("PRO")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(NafsTheme.goldGradient)
                                .clipShape(.capsule)
                        }
                        .padding(14)
                        .background(NafsTheme.gold.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.gold)
                    Text(NafsStrings.currentStreak.localized)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.streakDays)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                        .contentTransition(.numericText())
                    Text(viewModel.streakDays == 1 ? NafsStrings.day.localized : NafsStrings.days.localized)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Text(viewModel.streakDays == 0 ? NafsStrings.startStreakToday.localized : NafsStrings.keepItGoing.localized)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(day < viewModel.streakDays ? NafsTheme.gold : NafsTheme.card)
                        .frame(width: 12, height: day < viewModel.streakDays ? 28 + CGFloat(day) * 4 : 16)
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var gardenPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NafsStrings.gardenOfDeeds.localized)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                if viewModel.isPremium {
                    Button {
                        showGarden = true
                    } label: {
                        Text(NafsStrings.view.localized)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(.caption2))
                        Text("PRO")
                            .font(.system(.caption2, weight: .bold))
                    }
                    .foregroundStyle(NafsTheme.gold)
                }
            }

            HStack(spacing: 12) {
                GardenPreviewItem(icon: "tree.fill", count: viewModel.gardenTrees, label: NafsStrings.trees.localized)
                GardenPreviewItem(icon: "leaf.fill", count: viewModel.gardenFlowers, label: NafsStrings.flowers.localized)
                GardenPreviewItem(icon: "sparkle", count: viewModel.gardenOrbs, label: NafsStrings.orbs.localized)
                GardenPreviewItem(icon: "moonphase.waxing.crescent", count: viewModel.gardenBlooms, label: NafsStrings.blooms.localized)
            }

            if viewModel.gardenTrees == 0 && viewModel.gardenFlowers == 0 && viewModel.gardenOrbs == 0 && viewModel.gardenBlooms == 0 {
                Text(lang.isArabic ? "تبدأ حديقتك بأول عمل صالح." : "Your garden begins with your first deed.")
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var ayahCard: some View {
        let ayah = DailyAyah.today
        return VStack(spacing: 12) {
            Text(ayah.arabic)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .foregroundStyle(NafsTheme.gold)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            Text(ayah.translation)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)
            Text(ayah.reference)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var focusShortcutCard: some View {
        Button {
            navigationState.selectedTab = .focus
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "shield.checkered")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("Stay focused", "ابقَ مركزاً"))
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(L10n.text("Block distractions and protect your time", "احجب المشتتات واحمِ وقتك"))
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Spacer()

                Text(L10n.text("Start", "ابدأ"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.capsule)
            }
            .padding(16)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var habitsQuickSummary: some View {
        let todayCount = viewModel.todayLogs.count
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(.body))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("Today's Habits", "عادات اليوم"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text(todayCount > 0
                     ? L10n.text("\(todayCount) logged today", "\(todayCount) مسجلة اليوم")
                     : L10n.text("No habits logged yet", "لم تُسجّل عادات بعد"))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(viewModel.hasanatBalance)")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                Image(systemName: "sparkle")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
        }
        .padding(14)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var panicButton: some View {
        Button {
            showPanicButton = true
        } label: {
            ZStack {
                Circle()
                    .fill(NafsTheme.goldGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: NafsTheme.goldShadow, radius: 12, y: 4)
                CrescentStarMark(size: 28, color: .white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .sensoryFeedback(.impact(weight: .medium), trigger: showPanicButton)
    }
}

private struct GardenPreviewItem: View {
    let icon: String
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(NafsTheme.gold)
            Text("\(count)")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 12))
    }
}
