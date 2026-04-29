import SwiftUI
import Combine
import FamilyControls

struct FocusView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel

    @State private var screenTimeService: ScreenTimeService = ScreenTimeService()
    @State private var selectedMode: FocusMode = .auto
    @State private var showActivityPicker: Bool = false
    @State private var unlockSuccess: Bool = false
    @State private var unlockFailed: Bool = false
    @State private var tick: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showResetConfirm: Bool = false
    @State private var showPremiumGate: Bool = false
    @State private var showEarnPulse: Bool = false
    @State private var showEarnedAmount: Int = 0

    @Environment(LanguageManager.self) private var lang

    private let spendOptions: [Int] = [10, 30, 60]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !viewModel.isPremium {
                        premiumPreview
                    } else if !screenTimeService.isAuthorized {
                        authorizationSection
                    } else {
                        modeSwitcher

                        if !screenTimeService.hasSelection {
                            entryState
                        } else {
                            balanceCard
                            statusCard

                            if selectedMode == .auto {
                                autoModeCard
                            } else {
                                earnModeCard
                            }

                            appSelectionCard
                            manageSection
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(L10n.text("Discipline", "الانضباط"))
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
                screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: selectedMode)
            }
            .sensoryFeedback(.success, trigger: unlockSuccess)
            .sensoryFeedback(.error, trigger: unlockFailed)
            .sensoryFeedback(.increase, trigger: viewModel.focusEconomy.earnFeedbackTrigger)
            .sensoryFeedback(.warning, trigger: viewModel.focusEconomy.lowBalanceTrigger)
            .onChange(of: viewModel.focusEconomy.earnFeedbackTrigger) { _, _ in
                let amount = viewModel.focusEconomy.lastEarnedAmount
                guard amount > 0 else { return }
                showEarnedAmount = amount
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showEarnPulse = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showEarnPulse = false
                    }
                }
            }
            .alert(L10n.text("Reset Discipline", "إعادة تعيين الانضباط"), isPresented: $showResetConfirm) {
                Button(L10n.text("Cancel", "إلغاء"), role: .cancel) {}
                Button(L10n.text("Reset", "إعادة"), role: .destructive) {
                    screenTimeService.clearAll()
                }
            } message: {
                Text(L10n.text("This removes all blocked apps and disables shielding.", "سيؤدي هذا إلى إزالة جميع التطبيقات المحجوبة وتعطيل الحماية."))
            }
            .sheet(isPresented: $showPremiumGate) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: L10n.text("Discipline", "الانضباط"),
                    benefit: L10n.text("No worship, no access. Earn your screen time through prayer, dhikr and Quran.", "لا عبادة لا وصول. اكسب وقت شاشتك بالصلاة والذكر والقرآن."),
                    onDismiss: { showPremiumGate = false },
                    onSuccess: { showPremiumGate = false }
                )
            }
            .overlay(alignment: .top) {
                if showEarnPulse {
                    earnedToast
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .task {
            loadFocusMode()
            screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: selectedMode)
        }
        .onChange(of: viewModel.prayerTimes.map(\.id).joined(separator: "|")) { _, _ in
            screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: selectedMode)
        }
        .onChange(of: selectedMode) { _, newValue in
            saveFocusMode(newValue)
            screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: newValue)
        }
    }

    // MARK: - Earned toast
    private var earnedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.text("+\(showEarnedAmount) min earned", "+\(showEarnedAmount) د مكتسبة"))
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
                Text(L10n.text("Discipline rewarded.", "الانضباط مكافأ."))
                    .font(.system(.caption2))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(NafsTheme.goldGradient)
        .clipShape(.capsule)
        .shadow(color: NafsTheme.gold.opacity(0.4), radius: 12, x: 0, y: 4)
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
                Text(L10n.text("Grant Screen Time access. Discipline cannot work without it.", "امنح صلاحية مدة الاستخدام. لا يعمل الانضباط بدونها."))
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

    // MARK: - Mode switcher
    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            modeButton(title: L10n.text("Auto Mode", "وضع تلقائي"), icon: "moon.stars.fill", mode: .auto)
            modeButton(title: L10n.text("Earn Mode", "وضع الاكتساب"), icon: "bolt.shield.fill", mode: .earn)
        }
        .padding(4)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func modeButton(title: String, icon: String, mode: FocusMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
            }
            .foregroundStyle(selectedMode == mode ? .white : NafsTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(selectedMode == mode ? NafsTheme.goldGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
            .clipShape(.rect(cornerRadius: 12))
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

                Text(L10n.text("Discipline is part of Nafs Premium", "الانضباط ضمن نفس بريميوم"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("No worship, no access. Reclaim your time through prayer, dhikr and Quran.", "لا عبادة لا وصول. استعد وقتك بالصلاة والذكر والقرآن."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                previewRow(icon: "moon.stars.fill", title: L10n.text("Auto Mode", "وضع تلقائي"), subtitle: L10n.text("Apps lock at every prayer. Mark prayer complete to unlock.", "تُقفل التطبيقات عند كل صلاة. أكمل صلاتك لتفتح."))
                previewRow(icon: "bolt.shield.fill", title: L10n.text("Earn Mode", "وضع الاكتساب"), subtitle: L10n.text("All selected apps stay locked. Earn minutes through worship to unlock.", "تبقى جميع التطبيقات مقفلة. اكسب الدقائق بالعبادة لفتحها."))
                previewRow(icon: "app.badge.checkmark", title: L10n.text("Pick your distractions", "اختر مشتتاتك"), subtitle: L10n.text("Choose exactly which apps and categories to block.", "اختر التطبيقات والفئات التي ستُحجب."))
            }

            NafsButton(title: L10n.text("Unlock Discipline", "افتح الانضباط")) {
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
                    Image(systemName: selectedMode == .auto ? "moon.stars.fill" : "bolt.shield.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                Text(L10n.text("Discipline required", "الانضباط مطلوب"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Select the apps you keep wasting time on. Nafs will lock them.", "اختر التطبيقات التي تضيّع فيها وقتك. سيقفلها نفس."))
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

    // MARK: - Balance
    private var balanceCard: some View {
        let economy = viewModel.focusEconomy
        let cap = FocusEconomyService.dailyCap
        let pct = min(1.0, Double(economy.todayEarnedMinutes) / Double(cap))
        let isLow = economy.availableMinutes <= 5

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("SCREEN TIME AVAILABLE", "وقت الشاشة المتاح"))
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .tracking(1.2)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(economy.availableMinutes)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(isLow ? Color.red.opacity(0.85) : NafsTheme.gold)
                            .contentTransition(.numericText())
                        Text(L10n.text("min", "د"))
                            .font(.system(.title3, weight: .semibold))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    if isLow {
                        Text(L10n.text("You have \(economy.availableMinutes) minute\(economy.availableMinutes == 1 ? "" : "s") left. Earn more.", "تبقى لك \(economy.availableMinutes) دقيقة. اكسب المزيد."))
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.8))
                    } else {
                        Text(L10n.text("Earn it. Spend it. No shortcuts.", "اكسبه. أنفقه. لا اختصارات."))
                            .font(.system(.caption))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(.caption, weight: .bold))
                        Text("\(economy.streakDays)")
                            .font(.system(.subheadline, weight: .bold))
                    }
                    .foregroundStyle(NafsTheme.gold)
                    Text(L10n.text("\(economy.streakMultiplierLabel) multiplier", "مضاعف \(economy.streakMultiplierLabel)"))
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L10n.text("Daily cap", "الحد اليومي"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                    Spacer()
                    Text("\(economy.todayEarnedMinutes) / \(cap) \(L10n.text("min", "د"))")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NafsTheme.gold.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NafsTheme.goldGradient)
                            .frame(width: geo.size.width * pct)
                    }
                }
                .frame(height: 6)
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

    // MARK: - Status
    private var statusCard: some View {
        let unlocked = screenTimeService.activePrayerLock == nil && screenTimeService.isUnlocked
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedMode == .auto ? L10n.text("Auto Mode", "وضع تلقائي") : L10n.text("Earn Mode", "وضع الاكتساب"))
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
                        .fill(unlocked ? Color(hex: "4CAF50") : NafsTheme.gold)
                        .frame(width: 8, height: 8)
                    Text(unlocked ? L10n.text("Unlocked", "مفتوح") : L10n.text("Locked", "مقفل"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(unlocked ? Color(hex: "4CAF50") : NafsTheme.gold)
                }
            }

            if let remaining = screenTimeService.remainingUnlockTime {
                Text(formatRemaining(remaining))
                    .font(.system(.caption, weight: .bold))
                    .foregroundStyle(Color(hex: "4CAF50"))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "4CAF50").opacity(0.1))
                    .clipShape(.rect(cornerRadius: 12))
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

    // MARK: - Auto Mode
    private var autoModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: L10n.text("Apps lock at every prayer", "تُقفل التطبيقات عند كل صلاة"),
                subtitle: L10n.text("No worship, no access. Mark prayer complete to unlock.", "لا عبادة لا وصول. أكمل صلاتك لتفتح."),
                icon: "moon.stars.fill"
            )

            if !viewModel.prayerTimes.isEmpty {
                prayerTimesList
            }

            if let activePrayer = screenTimeService.activePrayerLock {
                Button {
                    screenTimeService.markPrayerComplete(prayerTimes: viewModel.prayerTimes)
                    viewModel.focusEconomy.earn(from: .fard)
                    unlockSuccess.toggle()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(L10n.text("Mark Prayer Complete (+15 min)", "تأكيد إتمام الصلاة (+15 د)"))
                    }
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 16))
                }
                .accessibilityLabel(Text("Mark \(NafsStrings.prayerName(activePrayer)) complete"))
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
                HStack(spacing: 12) {
                    Image(systemName: prayer.name.icon)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(prayer.isNext ? NafsTheme.gold : NafsTheme.subtleText)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NafsStrings.prayerName(prayer.name))
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                        Text(L10n.text("Locks at start time", "يقفل عند بداية الوقت"))
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    Spacer()
                    Text(prayer.timeString)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                .padding(12)
                .background(NafsTheme.background)
                .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    // MARK: - Earn Mode
    private var earnModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: L10n.text("Earn your access", "اكسب وصولك"),
                subtitle: L10n.text("All selected apps stay locked until you spend earned minutes.", "تبقى جميع التطبيقات مقفلة حتى تنفق الدقائق المكتسبة."),
                icon: "bolt.shield.fill"
            )

            earnRulesGrid

            spendOptionsSection
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        }
    }

    private var earnRulesGrid: some View {
        VStack(spacing: 8) {
            earnRule(icon: EarnSource.fard.icon, title: L10n.text("Fard salah", "صلاة فرض"), reward: "+15 \(L10n.text("min", "د"))")
            earnRule(icon: EarnSource.dhikr.icon, title: L10n.text("Dhikr session", "جلسة ذكر"), reward: "+5 \(L10n.text("min", "د"))")
            earnRule(icon: EarnSource.quran.icon, title: L10n.text("Quran reading", "قراءة القرآن"), reward: "+10 \(L10n.text("min", "د"))")
        }
    }

    private func earnRule(icon: String, title: String, reward: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }
            Text(title)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Spacer()
            Text(reward)
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(NafsTheme.background)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var spendOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("Spend minutes to unlock", "أنفق الدقائق لفتح التطبيقات"))
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(NafsTheme.subtleText)
                .tracking(0.8)

            VStack(spacing: 8) {
                ForEach(spendOptions, id: \.self) { minutes in
                    spendButton(minutes: minutes)
                }
            }
        }
    }

    private func spendButton(minutes: Int) -> some View {
        let canAfford = viewModel.focusEconomy.availableMinutes >= minutes
        return Button {
            if viewModel.focusEconomy.spend(minutes: minutes) {
                screenTimeService.temporaryUnlock(minutes: minutes)
                unlockSuccess.toggle()
            } else {
                unlockFailed.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Unlock \(minutes) min", "فتح \(minutes) د"))
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(canAfford ? NafsTheme.text : NafsTheme.subtleText)
                    Text(L10n.text("Costs \(minutes) earned minutes", "يكلف \(minutes) دقيقة مكتسبة"))
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
                Text("-\(minutes) \(L10n.text("min", "د"))")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(canAfford ? NafsTheme.gold : NafsTheme.subtleText)
            }
            .padding(14)
            .background(canAfford ? NafsTheme.gold.opacity(0.06) : NafsTheme.background)
            .clipShape(.rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(canAfford ? NafsTheme.gold.opacity(0.2) : NafsTheme.cardBorder, lineWidth: 1)
            }
        }
        .disabled(!canAfford)
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

    private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(subtitle)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private var statusText: String {
        if let activePrayer = screenTimeService.activePrayerLock {
            return L10n.text("Locked for \(NafsStrings.prayerName(activePrayer)). Complete your prayer to continue.", "مقفل من أجل \(NafsStrings.prayerName(activePrayer)). أكمل صلاتك للمتابعة.")
        }
        if selectedMode == .auto {
            return L10n.text("Apps lock automatically at every prayer.", "تُقفل التطبيقات تلقائياً عند كل صلاة.")
        }
        return L10n.text("All selected apps locked. Earn minutes to unlock.", "جميع التطبيقات المختارة مقفلة. اكسب الدقائق لفتحها.")
    }

    private func formatRemaining(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return L10n.text("\(hours)h \(minutes)m remaining", "متبقي \(hours) س \(minutes) د")
        }
        if minutes > 0 {
            return L10n.text("\(minutes)m \(seconds)s remaining", "متبقي \(minutes) د \(seconds) ث")
        }
        return L10n.text("\(seconds)s remaining", "متبقي \(seconds) ث")
    }

    private func saveFocusMode(_ mode: FocusMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: "nafs_focusMode_v2")
    }

    private func loadFocusMode() {
        let saved = UserDefaults.standard.string(forKey: "nafs_focusMode_v2") ?? FocusMode.auto.rawValue
        selectedMode = FocusMode(rawValue: saved) ?? .auto
    }
}

nonisolated enum FocusMode: String, Sendable {
    case auto
    case earn
}
