import SwiftUI
import Combine
import FamilyControls

struct FocusView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel

    @State private var screenTimeService: ScreenTimeService = ScreenTimeService()
    @State private var selectedMode: FocusMode = .prayer
    @State private var showActivityPicker: Bool = false
    @State private var unlockSuccess: Bool = false
    @State private var unlockFailed: Bool = false
    @State private var tick: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showResetConfirm: Bool = false
    @State private var showPremiumGate: Bool = false

    @Environment(LanguageManager.self) private var lang

    private var hasSetup: Bool {
        screenTimeService.isAuthorized && screenTimeService.hasSelection
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !viewModel.isPremium {
                        premiumPreview
                    } else if !screenTimeService.isAuthorized {
                        authorizationSection
                    } else {
                        modeSwitcher

                        if !screenTimeService.hasSelection {
                            entryState
                        } else {
                            overviewCard

                            if selectedMode == .prayer {
                                prayerModeCard
                            } else {
                                disciplineModeCard
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
                screenTimeService.evaluatePrayerLock(prayerTimes: viewModel.prayerTimes, focusMode: selectedMode)
            }
            .sensoryFeedback(.success, trigger: unlockSuccess)
            .sensoryFeedback(.error, trigger: unlockFailed)
            .alert(L10n.text("Reset Blocker", "إعادة تعيين الحاجب"), isPresented: $showResetConfirm) {
                Button(L10n.text("Cancel", "إلغاء"), role: .cancel) {}
                Button(L10n.text("Reset", "إعادة"), role: .destructive) {
                    screenTimeService.clearAll()
                }
            } message: {
                Text(L10n.text("This will remove all blocked apps and disable shielding.", "سيؤدي هذا إلى إزالة جميع التطبيقات المحجوبة وتعطيل الحماية."))
            }
            .sheet(isPresented: $showPremiumGate) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: L10n.text("Focus", "التركيز"),
                    benefit: L10n.text("Unlock Prayer Mode and Discipline Mode to block distractions with intention.", "افتح وضع الصلاة ووضع الانضباط لحجب المشتتات بنية واضحة."),
                    onDismiss: { showPremiumGate = false },
                    onSuccess: { showPremiumGate = false }
                )
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
                Text(L10n.text("Grant Screen Time access so Nafs can block distracting apps at the system level.", "امنح صلاحية مدة الاستخدام ليتمكن نفس من حجب التطبيقات المشتتة على مستوى النظام."))
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

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            modeButton(title: L10n.text("Prayer", "الصلاة"), icon: "moon.stars.fill", mode: .prayer)
            modeButton(title: L10n.text("Discipline", "الانضباط"), icon: "bolt.shield.fill", mode: .discipline)
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

                Text(L10n.text("Block distractions during prayer, protect your focus, and unlock access with intention.", "احجب المشتتات أثناء الصلاة، واحمِ تركيزك، وافتح الوصول بنية واضحة."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                previewRow(icon: "moon.stars.fill", title: L10n.text("Prayer Mode", "وضع الصلاة"), subtitle: L10n.text("Locks selected apps exactly at prayer time until you mark prayer complete.", "يقفل التطبيقات المختارة فور دخول وقت الصلاة حتى تؤكد إتمام الصلاة."))
                previewRow(icon: "bolt.shield.fill", title: L10n.text("Discipline Mode", "وضع الانضباط"), subtitle: L10n.text("Use Hasanat, prayer completion, or a timed session to unlock distractions.", "استخدم الحسنات أو إتمام الصلاة أو جلسة مؤقتة لفتح المشتتات."))
                previewRow(icon: "app.badge.checkmark", title: L10n.text("App selection", "اختيار التطبيقات"), subtitle: L10n.text("Choose exactly which apps and categories Nafs should shield.", "اختر التطبيقات والفئات التي يجب أن يحجبها نفس بدقة."))
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

    private var entryState: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: selectedMode == .prayer ? "moon.stars.fill" : "bolt.shield.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }

                Text(L10n.text("Take back control of your time", "استعد السيطرة على وقتك"))
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Block distractions during prayer and focus time", "احجب المشتتات أثناء الصلاة ووقت التركيز"))
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

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMode == .prayer ? L10n.text("Prayer Mode", "وضع الصلاة") : L10n.text("Discipline Mode", "وضع الانضباط"))
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(statusText)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(screenTimeService.activePrayerLock == nil && screenTimeService.isUnlocked ? Color(hex: "4CAF50") : NafsTheme.gold)
                        .frame(width: 8, height: 8)
                    Text(screenTimeService.activePrayerLock == nil && screenTimeService.isUnlocked ? L10n.text("Unlocked", "مفتوح") : L10n.text("Locked", "مقفل"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(screenTimeService.activePrayerLock == nil && screenTimeService.isUnlocked ? Color(hex: "4CAF50") : NafsTheme.gold)
                }
            }

            if let activePrayer = screenTimeService.activePrayerLock {
                activePrayerLockCard(activePrayer)
            } else if let remaining = screenTimeService.remainingUnlockTime {
                unlockCountdownCard(remaining)
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

    private var prayerModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: L10n.text("Prayer Mode", "وضع الصلاة"),
                subtitle: L10n.text("Selected apps automatically lock at every prayer time and stay locked until you mark the prayer complete in Nafs.", "تُقفل التطبيقات المختارة تلقائياً عند كل صلاة وتبقى مقفلة حتى تؤكد إتمام الصلاة داخل نفس."),
                icon: "moon.stars.fill"
            )

            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text("Automatic at every prayer time", "تلقائي عند كل صلاة"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
            }
            .padding(12)
            .background(NafsTheme.gold.opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))

            if !viewModel.prayerTimes.isEmpty {
                prayerTimesList
            }

            if let activePrayer = screenTimeService.activePrayerLock {
                Button {
                    screenTimeService.markPrayerComplete(prayerTimes: viewModel.prayerTimes)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(L10n.text("Mark Prayer Complete", "تأكيد إتمام الصلاة"))
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

    private func activePrayerLockCard(_ prayer: PrayerName) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("Stay Focused", "ابقَ مركزاً"))
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(L10n.text("This app is locked until you complete \(NafsStrings.prayerName(prayer)) in Nafs.", "هذا التطبيق مقفل حتى تؤكد إتمام \(NafsStrings.prayerName(prayer)) داخل نفس."))
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(NafsTheme.gold.opacity(0.08))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var disciplineModeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: L10n.text("Discipline Mode", "وضع الانضباط"),
                subtitle: L10n.text("Earn your access. Unlock distractions through prayer completion, focus, or Hasanat.", "اكسب وصولك. افتح المشتتات من خلال إتمام الصلاة أو التركيز أو الحسنات."),
                icon: "bolt.shield.fill"
            )

            disciplineUnlockRow(
                title: L10n.text("Complete prayer", "أتم الصلاة"),
                subtitle: L10n.text("Use prayer completion as your reset.", "اجعل إتمام الصلاة طريق عودتك."),
                icon: "moon.stars.fill"
            )

            disciplineUnlockRow(
                title: L10n.text("Spend Hasanat", "أنفق حسنات"),
                subtitle: L10n.text("Temporarily unlock your apps with earned Hasanat.", "افتح تطبيقاتك مؤقتاً بالحسنات المكتسبة."),
                icon: "sparkle"
            )

            disciplineUnlockRow(
                title: L10n.text("Timed focus session", "جلسة تركيز مؤقتة"),
                subtitle: L10n.text("Open access for a limited time, then re-lock automatically.", "افتح الوصول لفترة محدودة ثم أعد القفل تلقائياً."),
                icon: "timer"
            )

            if !screenTimeService.isUnlocked {
                unlockOptionsSection
            } else if let remaining = screenTimeService.remainingUnlockTime {
                unlockCountdownCard(remaining)
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

    private func disciplineUnlockRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Text(subtitle)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer()
        }
    }

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

    private var unlockOptionsSection: some View {
        VStack(spacing: 8) {
            ForEach(UnlockOption.options) { option in
                let canAfford = viewModel.hasanatBalance >= option.tokens
                Button {
                    if viewModel.spendHasanatForScreenTimeUnlock(option: option) {
                        screenTimeService.temporaryUnlock(minutes: option.durationMinutes)
                        unlockSuccess = true
                    } else {
                        unlockFailed = true
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.duration)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(canAfford ? NafsTheme.text : NafsTheme.subtleText)
                            Text(L10n.text("Unlock for a limited time", "فتح لفترة محدودة"))
                                .font(.system(.caption2))
                                .foregroundStyle(NafsTheme.subtleText)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(option.tokens)")
                                .font(.system(.body, weight: .bold))
                                .foregroundStyle(canAfford ? NafsTheme.gold : NafsTheme.subtleText)
                            Image(systemName: "sparkle")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundStyle(canAfford ? NafsTheme.gold : NafsTheme.subtleText)
                        }
                    }
                    .padding(16)
                    .background(canAfford ? NafsTheme.gold.opacity(0.06) : NafsTheme.background)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(canAfford ? NafsTheme.gold.opacity(0.2) : NafsTheme.cardBorder, lineWidth: 1)
                    }
                }
                .disabled(!canAfford)
            }
        }
    }

    private func unlockCountdownCard(_ remaining: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("Unlock Active", "الفتح نشط"))
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(NafsTheme.text)
            Text(formatRemaining(remaining))
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(Color(hex: "4CAF50"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: "4CAF50").opacity(0.08))
        .clipShape(.rect(cornerRadius: 16))
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
            }

            Spacer()
        }
    }

    private var statusText: String {
        if let activePrayer = screenTimeService.activePrayerLock {
            return L10n.text("Locked for \(NafsStrings.prayerName(activePrayer)) until you mark prayer complete.", "مقفل من أجل \(NafsStrings.prayerName(activePrayer)) حتى تؤكد إتمام الصلاة.")
        }
        if selectedMode == .prayer {
            return L10n.text("Exact prayer-time locking is active.", "القفل الدقيق مع وقت الصلاة نشط.")
        }
        return L10n.text("Discipline rules are active.", "قواعد الانضباط نشطة.")
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
        UserDefaults.standard.set(mode.rawValue, forKey: "nafs_focusMode")
    }

    private func loadFocusMode() {
        let saved = UserDefaults.standard.string(forKey: "nafs_focusMode") ?? FocusMode.prayer.rawValue
        selectedMode = FocusMode(rawValue: saved) ?? .prayer
    }
}

nonisolated enum FocusMode: String, Sendable {
    case prayer
    case discipline
}
