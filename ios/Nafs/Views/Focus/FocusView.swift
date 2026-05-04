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
    @State private var showFirstPrayerRating: Bool = false
    @State private var feedbackText: String = ""
    @State private var showFeedbackSheet: Bool = false
    @State private var showPrayerSuccess: Bool = false
    @State private var lastCompletedPrayer: PrayerName? = nil
    @State private var lastCompletedCount: Int = 0
    @State private var lastCompletedStreak: Int = 0

    @Environment(LanguageManager.self) private var lang

    private let prayerLockKey: String = "nafs_prayerLockEnabled_v1"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !viewModel.isPremium {
                        premiumPreview
                    } else if !screenTimeService.isAuthorized {
                        authorizationSection
                    } else if !screenTimeService.hasSelection {
                        entryState
                    } else {
                        toggleCard
                        if prayerLockEnabled {
                            statusCard
                            todayCard
                            streakCard
                        }
                        appSelectionCard
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
            .sheet(isPresented: $showPremiumGate) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: L10n.text("Focus", "التركيز"),
                    benefit: L10n.text("Lock distracting apps during prayer times until you've prayed.", "اقفل التطبيقات المشتتة في أوقات الصلاة حتى تصلي."),
                    onDismiss: { showPremiumGate = false },
                    onSuccess: { showPremiumGate = false }
                )
            }
            .sheet(isPresented: $showFirstPrayerRating) {
                FirstPrayerRatingSheet(
                    onYes: {
                        showFirstPrayerRating = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            RatingService.shared.requestReview()
                        }
                    },
                    onNotReally: {
                        showFirstPrayerRating = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showFeedbackSheet = true
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet(text: $feedbackText) {
                    showFeedbackSheet = false
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

    private func triggerFirstPrayerRatingIfNeeded() {
        let defaults = UserDefaults.standard
        let countKey = "nafs_prayerCompletionCount"
        let promptedKey = "nafs_firstPrayerRatingShown"
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)
        let alreadyPrompted = defaults.bool(forKey: promptedKey)
        let alreadyRated = RatingService.shared.hasRated
        guard count == 1, !alreadyPrompted, !alreadyRated else { return }
        defaults.set(true, forKey: promptedKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showFirstPrayerRating = true
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

    // MARK: - Toggle card
    private var toggleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $prayerLockEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("Enable Prayer Lock", "تفعيل قفل الصلاة"))
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(L10n.text("Selected apps will be blocked during prayer times until you pray.", "ستُحجب التطبيقات المختارة في أوقات الصلاة حتى تصلي."))
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(NafsTheme.gold)
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Status
    private var statusCard: some View {
        let activePrayer = screenTimeService.activePrayerLock
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Prayer Lock", "قفل الصلاة"))
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(statusText)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(activePrayer != nil ? NafsTheme.gold : Color(hex: "4CAF50"))
                        .frame(width: 8, height: 8)
                    Text(activePrayer != nil ? L10n.text("Locked", "مقفل") : L10n.text("Standby", "استعداد"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(activePrayer != nil ? NafsTheme.gold : Color(hex: "4CAF50"))
                }
            }

            if let activePrayer {
                Button {
                    showPrayConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(L10n.text("I’ve Prayed", "لقد صليت"))
                    }
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .confirmationDialog(
                    L10n.text("Confirm Prayer", "تأكيد الصلاة"),
                    isPresented: $showPrayConfirm,
                    titleVisibility: .visible
                ) {
                    Button(L10n.text("Yes, I’ve prayed", "نعم، لقد صليت")) {
                        let prayerJustDone = screenTimeService.activePrayerLock
                        screenTimeService.markPrayerComplete(prayerTimes: viewModel.prayerTimes)
                        unlockSuccess.toggle()
                        if let prayerJustDone {
                            lastCompletedPrayer = prayerJustDone
                            lastCompletedCount = screenTimeService.completedPrayersToday()
                            lastCompletedStreak = screenTimeService.currentStreakDays()
                            showPrayerSuccess = true
                        }
                        triggerFirstPrayerRatingIfNeeded()
                    }
                    Button(L10n.text("Not yet", "ليس بعد"), role: .cancel) {}
                } message: {
                    Text(L10n.text("Did you complete your \(NafsStrings.prayerName(activePrayer)) prayer?", "هل أتممت صلاة \(NafsStrings.prayerName(activePrayer))؟"))
                }
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

    // MARK: - Today card
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("Today", "اليوم"))
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(todayDateString)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                if let next = viewModel.nextPrayer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.text("Next", "القادمة"))
                            .font(.system(.caption2, weight: .bold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .tracking(0.8)
                        Text("\(NafsStrings.prayerName(next.name)) · \(viewModel.nextPrayerCountdown)")
                            .font(.system(.subheadline, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                }
            }

            if !viewModel.prayerTimes.isEmpty {
                prayerTimesList
                progressSummary
            }

            if let nextLock = nextLockText {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                    Text(nextLock)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                    Spacer()
                }
                .padding(10)
                .background(NafsTheme.gold.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    private var prayerTimesList: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.prayerTimes) { prayer in
                let done = PrayerCompletionStore.isCompleted(prayer.name, on: .now)
                HStack(spacing: 12) {
                    Image(systemName: prayer.name.icon)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(done ? NafsTheme.gold : (prayer.isNext ? NafsTheme.gold : NafsTheme.subtleText))
                        .frame(width: 20)
                    Text(NafsStrings.prayerName(prayer.name))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                    Spacer()
                    Text(prayer.timeString)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(done ? NafsTheme.gold : NafsTheme.subtleText.opacity(0.4))
                }
                .padding(12)
                .background(NafsTheme.background)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    private var progressSummary: some View {
        let completed = PrayerCompletionStore.completedCount(on: .now)
        let total = PrayerName.allCases.count
        return HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
            Text(L10n.text("\(completed)/\(total) prayers completed", "\(completed)/\(total) صلوات مكتملة"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Spacer()
            ProgressView(value: Double(completed), total: Double(total))
                .progressViewStyle(.linear)
                .tint(NafsTheme.gold)
                .frame(width: 90)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Streak
    private var streakCard: some View {
        let streak = PrayerCompletionStore.currentStreakDays()
        let cal = Calendar.current
        let days = PrayerCompletionStore.recentDays(7, calendar: cal)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Consistency", "الانتظام"))
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
                        Text(streak == 1 ? L10n.text("Day Streak", "يوم متتالٍ") : L10n.text("Day Streak", "أيام متتالية"))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                    }
                }
                Spacer()
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
                                    Circle()
                                        .strokeBorder(NafsTheme.gold, lineWidth: 1.5)
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
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        }
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: .now)
    }

    private func weekdayLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EE"
        return f.string(from: date)
    }

    private var nextLockText: String? {
        guard let next = viewModel.nextPrayer else { return nil }
        return L10n.text(
            "\(NafsStrings.prayerName(next.name)) locks at \(next.timeString)",
            "يقفل عند \(NafsStrings.prayerName(next.name)) الساعة \(next.timeString)"
        )
    }

    // MARK: - App selection
    private var appSelectionCard: some View {
        VStack(spacing: 14) {
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

    private var statusText: String {
        if let activePrayer = screenTimeService.activePrayerLock {
            return L10n.text("Locked for \(NafsStrings.prayerName(activePrayer)). Complete your prayer to unlock.", "مقفل من أجل \(NafsStrings.prayerName(activePrayer)). أكمل صلاتك للفتح.")
        }
        return L10n.text("Apps lock automatically at every prayer.", "تُقفل التطبيقات تلقائياً عند كل صلاة.")
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

nonisolated enum FocusMode: String, Sendable {
    case auto
    case earn
}
