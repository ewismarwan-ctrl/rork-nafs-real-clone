import SwiftUI
import Combine
import FamilyControls

struct AppBlockerView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var screenTimeService = ScreenTimeService()
    @State private var showActivityPicker: Bool = false
    @State private var unlockSuccess: Bool = false
    @State private var unlockFailed: Bool = false
    @State private var tick: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var showResetConfirm: Bool = false
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        Group {
            if viewModel.isPremium {
                blockerContent
            } else {
                PremiumGateView(
                    icon: "lock.shield.fill",
                    title: L10n.text("App Blocker", "حاجب التطبيقات"),
                    subtitle: L10n.text("Block distracting apps with Nafs Premium.", "حجب التطبيقات المشتتة مع نفس بريميوم."),
                    storeViewModel: storeViewModel
                )
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("App Blocker", "حاجب التطبيقات"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var blockerContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !screenTimeService.isAuthorized {
                    authorizationCard
                } else {
                    shieldStatusCard

                    if screenTimeService.isUnlocked {
                        unlockCountdownCard
                    }

                    if screenTimeService.hasSelection && !screenTimeService.isUnlocked {
                        unlockOptionsSection
                    }

                    if screenTimeService.hasSelection {
                        manageSection
                    }
                }

                howItWorksCard

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
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
    }

    private var authorizationCard: some View {
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
                Text(L10n.text("Grant Screen Time access so Nafs can block distracting apps at the system level. You control which apps to block.", "امنح صلاحية مدة الاستخدام ليتمكن نفس من حجب التطبيقات المشتتة على مستوى النظام. أنت تتحكم في التطبيقات المحجوبة."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                authBenefitRow(icon: "lock.shield.fill", text: L10n.text("System-level blocking — apps are truly blocked", "حجب على مستوى النظام — التطبيقات محجوبة فعلاً"))
                authBenefitRow(icon: "clock.fill", text: L10n.text("Distractions are locked at prayer time, automatically", "تُقفل المشتتات عند وقت الصلاة تلقائياً"))
                authBenefitRow(icon: "clock.arrow.circlepath", text: L10n.text("Apps re-lock automatically when time expires", "يعاد قفل التطبيقات تلقائياً عند انتهاء الوقت"))
            }
            .padding(.vertical, 4)

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
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func authBenefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .frame(width: 20)
            Text(text)
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.text)
        }
    }

    private var shieldStatusCard: some View {
        VStack(spacing: 16) {
            if screenTimeService.hasSelection {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(screenTimeService.isUnlocked ? Color(hex: "4CAF50").opacity(0.12) : NafsTheme.gold.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: screenTimeService.isUnlocked ? "lock.open.fill" : "lock.shield.fill")
                            .font(.system(.title3, weight: .semibold))
                            .foregroundStyle(screenTimeService.isUnlocked ? Color(hex: "4CAF50") : NafsTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(screenTimeService.isUnlocked
                             ? L10n.text("Apps Temporarily Unlocked", "التطبيقات مفتوحة مؤقتاً")
                             : L10n.text("Apps Blocked", "التطبيقات محجوبة"))
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
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40))
                        .foregroundStyle(NafsTheme.gold.opacity(0.5))

                    VStack(spacing: 4) {
                        Text(L10n.text("No Apps Blocked Yet", "لا توجد تطبيقات محجوبة"))
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Text(L10n.text("Select the apps you want to block. They'll lock automatically at prayer time.", "اختر التطبيقات التي تريد حجبها. ستُقفل تلقائياً عند وقت الصلاة."))
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                    }

                    NafsButton(title: L10n.text("Select Apps to Block", "اختر التطبيقات للحجب")) {
                        showActivityPicker = true
                    }
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    screenTimeService.hasSelection
                    ? (screenTimeService.isUnlocked ? Color(hex: "4CAF50").opacity(0.2) : NafsTheme.gold.opacity(0.2))
                    : NafsTheme.cardBorder,
                    lineWidth: 1
                )
        )
    }

    private var unlockCountdownCard: some View {
        let _ = tick
        return VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(Color(hex: "4CAF50"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("Unlock Active", "الفتح نشط"))
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    if let remaining = screenTimeService.remainingUnlockTime {
                        Text(formatRemaining(remaining))
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(remaining < 300 ? .red : Color(hex: "4CAF50"))
                    }
                }

                Spacer()

                Button {
                    screenTimeService.relockNow()
                } label: {
                    Text(L10n.text("Re-lock Now", "أعد القفل"))
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.08))
                        .clipShape(.capsule)
                }
            }

            if let remaining = screenTimeService.remainingUnlockTime {
                let totalDuration: TimeInterval = {
                    guard let expiry = screenTimeService.unlockExpiresAt else { return 1 }
                    return max(expiry.timeIntervalSince(.now), 1)
                }()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(NafsTheme.card)
                            .frame(height: 6)
                        Capsule()
                            .fill(remaining < 300 ? Color.red : Color(hex: "4CAF50"))
                            .frame(width: geo.size.width * min(remaining / totalDuration, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(Color(hex: "4CAF50").opacity(0.06))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: "4CAF50").opacity(0.15), lineWidth: 1)
        )
    }

    private var unlockOptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "lock.open.fill")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text("Quick Unlock", "فتح سريع"))
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
            }

            Text(L10n.text("Temporarily unblock all shielded apps. They will re-lock automatically when the timer ends.", "افتح جميع التطبيقات المحجوبة مؤقتاً. ستُقفل تلقائياً عند انتهاء الوقت."))
                .font(.system(.caption))
                .foregroundStyle(NafsTheme.subtleText)

            ForEach(UnlockOption.options) { option in
                Button {
                    screenTimeService.temporaryUnlock(minutes: option.durationMinutes)
                    unlockSuccess = true
                } label: {
                    HStack {
                        Text(option.duration)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .padding(16)
                    .background(NafsTheme.gold.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
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
            .foregroundStyle(.red.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(.red.opacity(0.06))
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("How It Works", "كيف يعمل"))
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(NafsTheme.text)

            stepRow(number: "1", text: L10n.text("Enable Screen Time access above", "فعّل صلاحية مدة الاستخدام أعلاه"))
            stepRow(number: "2", text: L10n.text("Select the apps and categories you want to block", "اختر التطبيقات والفئات التي تريد حجبها"))
            stepRow(number: "3", text: L10n.text("Selected apps are instantly blocked at the system level", "التطبيقات المختارة تُحجب فوراً على مستوى النظام"))
            stepRow(number: "4", text: L10n.text("Apps lock automatically at prayer time", "تُقفل التطبيقات تلقائياً عند وقت الصلاة"))
            stepRow(number: "5", text: L10n.text("Use Quick Unlock for a temporary break when needed", "استخدم الفتح السريع للاستراحة المؤقتة عند الحاجة"))
            stepRow(number: "6", text: L10n.text("Apps re-lock automatically when the timer expires", "يُعاد قفل التطبيقات تلقائياً عند انتهاء المؤقت"))

            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text("This is between you and Allah. The goal is to build discipline and earn reward, not to trick the system.", "هذا بينك وبين الله. الهدف هو بناء الانضباط وكسب الأجر، وليس خداع النظام."))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .padding(12)
            .background(NafsTheme.gold.opacity(0.06))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(NafsTheme.gold.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        )
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            Text(text)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.text)
        }
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
}
