import SwiftUI
import Combine
import FamilyControls

struct FocusView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel

    @State private var screenTimeService: ScreenTimeService = ScreenTimeService()
    @State private var showActivityPicker: Bool = false
    @State private var unlockSuccess: Bool = false
    @State private var tick: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showResetConfirm: Bool = false
    @State private var showPremiumGate: Bool = false
    @State private var showPrayConfirm: Bool = false
    @State private var prayerLockEnabled: Bool = true
    @State private var showRatingPrompt: Bool = false

    @Environment(LanguageManager.self) private var lang

    private let prayerLockKey: String = "nafs_prayerLockEnabled_v1"
    private let firstPrayerCompletedKey: String = "nafs_hasCompletedFirstPrayer"
    private let ratingPromptShownKey: String = "nafs_ratingPromptShown"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.isPremium {
                        premiumPreview
                    } else if !screenTimeService.isAuthorized {
                        authorizationSection
                    } else if !screenTimeService.hasSelection {
                        entryState
                    } else {
                        progressCard
                        consistencyCard
                        if screenTimeService.activePrayerLock != nil {
                            actionCard
                        }
                        toggleCard
                        appBlockingCard
                        manageSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(L10n.text("Focus", "التركيز"))
            .navigationBarTitleDisplayMode(.large)
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: Binding(
                    get: { screenTimeService.activitySelection },
                    set: { newValue in
                        screenTimeService.activitySelection = newValue
                        screenTimeService.onSelectionChanged()
                    }
                )
            )
            .onReceive(timer) { _ in
                tick += 1
                if let expiry = screenTimeService.unlockExpiresAt, expiry <= .now {
                    screenTimeService.relockNow()
                }
                if prayerLockEnabled {
                    screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: .auto)
                }
            }
            .sensoryFeedback(.success, trigger: unlockSuccess)
            .alert(L10n.text("Reset Focus", "إعادة تعيين التركيز"), isPresented: $showResetConfirm) {
                Button(L10n.text("Cancel", "إلغاء"), role: .cancel) {}
                Button(L10n.text("Reset", "إعادة"), role: .destructive) {
                    screenTimeService.clearAll()
                }
            } message: {
                Text(L10n.text("This removes all blocked apps and disables prayer lock.", "سيؤدي هذا إلى إزالة جميع التطبيقات المحجوبة وتعطيل قفل الصلاة."))
            }
            .sheet(isPresented: $showRatingPrompt) {
                PrayerRatingPromptSheet(onDismiss: { showRatingPrompt = false })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPremiumGate) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: L10n.text("Focus", "التركيز"),
                    benefit: L10n.text("Lock distracting apps during prayer times until you've prayed.", "اقفل التطبيقات المشتتة في أوقات الصلاة حتى تصلي."),
                    onDismiss: { showPremiumGate = false },
                    onSuccess: { showPremiumGate = false }
                )
            }
        }
        .task {
            loadPrayerLockEnabled()
            if prayerLockEnabled {
                screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: .auto)
            }
        }
        .onChange(of: viewModel.prayerTimes.map(\.id).joined(separator: "|")) { _, _ in
            if prayerLockEnabled {
                screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: .auto)
            }
        }
        .onChange(of: prayerLockEnabled) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: prayerLockKey)
            if newValue {
                screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: .auto)
            } else {
                screenTimeService.activePrayerLock = nil
                screenTimeService.removeShields()
            }
        }
    }

    // MARK: - Today's Progress
    private var progressCard: some View {
        let completed = PrayerStatsService.completedCount(on: .now)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.text("Today’s Progress", "تقدّم اليوم"))
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Text("\(completed)/5")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }

            ProgressDots(filled: completed, total: 5)

            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                if let next = viewModel.nextPrayer {
                    Text(L10n.text("Next: \(NafsStrings.prayerName(next.name)) in \(viewModel.nextPrayerCountdown)", "التالي: \(NafsStrings.prayerName(next.name)) بعد \(viewModel.nextPrayerCountdown)"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                } else {
                    Text(L10n.text("All prayers done for today", "اكتملت صلوات اليوم"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1612"), Color(hex: "0E0B08")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: NafsTheme.goldShadow, radius: 16, y: 6)
    }

    // MARK: - Consistency
    private var consistencyCard: some View {
        let streak = PrayerStatsService.currentStreak()
        let best = PrayerStatsService.bestStreak()
        let week = PrayerStatsService.lastSevenDays()

        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("Consistency", "المداومة"))
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            HStack(spacing: 12) {
                StreakStat(
                    value: "\(streak)",
                    label: L10n.text("Current streak", "السلسلة الحالية"),
                    icon: "flame.fill",
                    accent: true
                )
                StreakStat(
                    value: "\(best)",
                    label: L10n.text("Best streak", "أفضل سلسلة"),
                    icon: "crown.fill",
                    accent: false
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Last 7 days", "آخر ٧ أيام"))
                    .font(.system(.caption, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(NafsTheme.subtleText)

                HStack(spacing: 8) {
                    ForEach(week) { day in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(day.completedAny ? NafsTheme.gold : NafsTheme.cardBorder.opacity(0.4))
                                    .frame(width: 28, height: 28)
                                if day.completedAny {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                                if day.isToday {
                                    Circle()
                                        .strokeBorder(NafsTheme.gold, lineWidth: 1.5)
                                        .frame(width: 34, height: 34)
                                }
                            }
                            Text(day.weekdayLetter)
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(NafsTheme.subtleText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Action card (only when prayer is active)
    private var actionCard: some View {
        let activePrayer = screenTimeService.activePrayerLock
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.fill")
                        .foregroundStyle(NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Apps locked", "التطبيقات مقفلة"))
                        .font(.system(.caption, weight: .heavy))
                        .tracking(1.5)
                        .foregroundStyle(NafsTheme.gold)
                    if let p = activePrayer {
                        Text(L10n.text("It’s time for \(NafsStrings.prayerName(p))", "حان وقت \(NafsStrings.prayerName(p))"))
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                    }
                }
                Spacer()
            }

            Button {
                showPrayConfirm = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(L10n.text("I’ve Prayed", "لقد صليت"))
                }
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(NafsTheme.goldGradient)
                .clipShape(.rect(cornerRadius: 14))
            }
            .confirmationDialog(
                L10n.text("Confirm Prayer", "تأكيد الصلاة"),
                isPresented: $showPrayConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.text("Yes, I’ve prayed", "نعم، لقد صليت")) {
                    if let p = activePrayer {
                        let f = DateFormatter()
                        f.calendar = Calendar.current
                        f.timeZone = TimeZone.current
                        f.dateFormat = "yyyy-MM-dd"
                        UserDefaults.standard.set(true, forKey: "nafs_prayerComplete_\(f.string(from: .now))_\(p.rawValue)")
                    }
                    screenTimeService.markPrayerComplete(prayerTimes: viewModel.prayerTimes)
                    unlockSuccess.toggle()
                    triggerRatingPromptIfNeeded()
                }
                Button(L10n.text("Not yet", "ليس بعد"), role: .cancel) {}
            } message: {
                if let p = activePrayer {
                    Text(L10n.text("Did you complete your \(NafsStrings.prayerName(p)) prayer?", "هل أتممت صلاة \(NafsStrings.prayerName(p))؟"))
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.4), lineWidth: 1)
        }
    }

    // MARK: - Toggle
    private var toggleCard: some View {
        Toggle(isOn: $prayerLockEnabled) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("Prayer Lock", "قفل الصلاة"))
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(L10n.text("Lock selected apps automatically at prayer times.", "اقفل التطبيقات المختارة تلقائياً عند أوقات الصلاة."))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(NafsTheme.gold)
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - App Blocking
    private var appBlockingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Blocked Apps", "التطبيقات المحجوبة"))
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)

                    let appCount = screenTimeService.selectedAppCount
                    let catCount = screenTimeService.selectedCategoryCount
                    let parts = [
                        appCount > 0 ? L10n.text("\(appCount) app\(appCount == 1 ? "" : "s")", "\(appCount) تطبيق") : nil,
                        catCount > 0 ? L10n.text("\(catCount) categor\(catCount == 1 ? "y" : "ies")", "\(catCount) فئة") : nil,
                    ].compactMap { $0 }
                    Text(parts.joined(separator: " · "))
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "clock.badge.fill")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                if let next = viewModel.nextPrayer {
                    Text(L10n.text("Next lock: \(NafsStrings.prayerName(next.name)) in \(viewModel.nextPrayerCountdown)", "القفل القادم: \(NafsStrings.prayerName(next.name)) بعد \(viewModel.nextPrayerCountdown)"))
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                } else {
                    Text(L10n.text("Standby", "استعداد"))
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(NafsTheme.background)
            .clipShape(.rect(cornerRadius: 12))

            Button {
                showActivityPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(.body, weight: .semibold))
                    Text(L10n.text("Change Selection", "تغيير الاختيار"))
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundStyle(NafsTheme.gold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(.rect(cornerRadius: 14))
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Authorization
    private var authorizationSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(spacing: 6) {
                Text(L10n.text("Enable App Blocking", "تفعيل حجب التطبيقات"))
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(L10n.text("Grant Screen Time access. Prayer lock cannot work without it.", "امنح صلاحية مدة الاستخدام. لا يعمل قفل الصلاة بدونها."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            NafsButton(
                title: L10n.text("Enable Screen Time Access", "تفعيل صلاحية مدة الاستخدام"),
                isLoading: screenTimeService.isRequestingAuth
            ) {
                Task {
                    await screenTimeService.requestAuthorization()
                }
            }
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Premium preview
    private var premiumPreview: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                Text(L10n.text("Focus is part of Nafs Premium", "التركيز ضمن نفس بريميوم"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Lock distracting apps during prayer times until you've prayed.", "اقفل التطبيقات المشتتة في أوقات الصلاة حتى تصلي."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                previewRow(icon: "moon.stars.fill", title: L10n.text("Locks at every prayer", "يقفل عند كل صلاة"), subtitle: L10n.text("Selected apps lock automatically at prayer times.", "تُقفل التطبيقات المحددة تلقائياً عند أوقات الصلاة."))
                previewRow(icon: "checkmark.circle.fill", title: L10n.text("Unlocks after you pray", "يفتح بعد الصلاة"), subtitle: L10n.text("Mark prayer complete and your apps open back up.", "أكمل الصلاة لتفتح تطبيقاتك."))
                previewRow(icon: "app.badge.checkmark", title: L10n.text("Pick your distractions", "اختر مشتتاتك"), subtitle: L10n.text("Choose exactly which apps and categories to block.", "اختر التطبيقات والفئات التي ستُحجب."))
            }

            NafsButton(title: L10n.text("Unlock Focus", "افتح التركيز")) {
                showPremiumGate = true
            }
        }
        .padding(22)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    private func previewRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text(subtitle)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Entry
    private var entryState: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                Text(L10n.text("Lock apps during prayer", "اقفل التطبيقات أثناء الصلاة"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Select the apps you keep wasting time on. Nafs will lock them at every prayer time.", "اختر التطبيقات التي تضيّع فيها وقتك. سيقفلها نفس عند كل صلاة."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            NafsButton(title: L10n.text("Select Apps to Block", "اختر التطبيقات للحجب")) {
                showActivityPicker = true
            }
        }
        .padding(22)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    private var manageSection: some View {
        Button {
            showResetConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(.caption, weight: .semibold))
                Text(L10n.text("Reset All Blocks", "إعادة تعيين جميع الحجب"))
                    .font(.system(.subheadline, weight: .medium))
            }
            .foregroundStyle(.red.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.red.opacity(0.06))
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    // MARK: - Helpers
    private func triggerRatingPromptIfNeeded() {
        let defaults = UserDefaults.standard
        let firstPrayerDone = defaults.bool(forKey: firstPrayerCompletedKey)
        if !firstPrayerDone {
            defaults.set(true, forKey: firstPrayerCompletedKey)
            let alreadyShown = defaults.bool(forKey: ratingPromptShownKey)
            if !alreadyShown && !RatingService.shared.hasRated {
                defaults.set(true, forKey: ratingPromptShownKey)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showRatingPrompt = true
                }
            }
        }
    }

    private func loadPrayerLockEnabled() {
        if UserDefaults.standard.object(forKey: prayerLockKey) == nil {
            prayerLockEnabled = true
            UserDefaults.standard.set(true, forKey: prayerLockKey)
        } else {
            prayerLockEnabled = UserDefaults.standard.bool(forKey: prayerLockKey)
        }
        UserDefaults.standard.set("auto", forKey: "nafs_focusMode_v2")
    }
}

// MARK: - Reusable bits

private struct ProgressDots: View {
    let filled: Int
    let total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? NafsTheme.goldGradient : LinearGradient(colors: [NafsTheme.cardBorder.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
                    .overlay {
                        if i < filled {
                            Capsule().strokeBorder(NafsTheme.gold.opacity(0.5), lineWidth: 0.6)
                        }
                    }
            }
        }
    }
}

private struct StreakStat: View {
    let value: String
    let label: String
    let icon: String
    let accent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(accent ? .orange : NafsTheme.gold)
                Text(label)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                    .tracking(0.5)
            }
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(NafsTheme.text)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NafsTheme.background)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accent ? NafsTheme.gold.opacity(0.4) : NafsTheme.cardBorder, lineWidth: 1)
        }
    }
}

nonisolated enum FocusMode: String, Sendable {
    case auto
    case earn
}
