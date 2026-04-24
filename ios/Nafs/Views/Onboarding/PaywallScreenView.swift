import SwiftUI
import RevenueCat

enum PaywallConstants {
    static let privacyPolicyURL = NafsConstants.privacyPolicyURL
    static let termsOfUseURL = NafsConstants.termsOfUseURL
}

struct PaywallScreenView: View {
    let vm: OnboardingViewModel
    let storeViewModel: StoreViewModel
    @State private var appeared: Bool = false
    @State private var subScreen: Int = 0
    @State private var countdownMinutes: Int = 1440
    @State private var hapticTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= subScreen ? NafsTheme.gold : NafsTheme.card)
                        .frame(height: 3)
                        .animation(.spring(response: 0.3), value: subScreen)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            TabView(selection: $subScreen) {
                PaywallFeaturesSubscreen(vm: vm, onContinue: { advanceSubscreen() })
                    .tag(0)
                PaywallTrustSubscreen(vm: vm, onContinue: { advanceSubscreen() })
                    .tag(1)
                PaywallPricingSubscreen(
                    vm: vm,
                    storeViewModel: storeViewModel,
                    countdownMinutes: countdownMinutes,
                    onStartTrial: {
                        hapticTrigger += 1
                        vm.completeOnboarding()
                    },
                    onFreePlan: {
                        vm.completeOnboarding()
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: subScreen)
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func advanceSubscreen() {
        if subScreen < 2 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                subScreen += 1
            }
        }
    }
}

struct PaywallFeaturesSubscreen: View {
    let vm: OnboardingViewModel
    let onContinue: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(NafsStrings.paywallReady.localized)
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 8) {
                        ForEach(vm.personalizedOutcomes, id: \.self) { outcome in
                            HStack(spacing: 10) {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(NafsTheme.gold)
                                    .font(.system(.caption))
                                Text(outcome)
                                    .font(.system(.subheadline, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(NafsTheme.gold.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 16))

                    HStack(alignment: .top, spacing: 12) {
                        PaywallTierCard(
                            title: NafsStrings.freeTitle.localized,
                            subtitle: NafsStrings.justATaste.localized,
                            features: [
                                ("checkmark", NafsStrings.prayerTimes.localized),
                                ("checkmark", NafsStrings.hasanatBalance.localized),
                                ("checkmark", NafsStrings.tabQuran.localized),
                                ("xmark", NafsStrings.focusMode.localized),
                                ("xmark", NafsStrings.prayerLock.localized),
                                ("xmark", NafsStrings.disciplineMode.localized),
                                ("xmark", NafsStrings.quranAudioFull.localized),
                                ("xmark", NafsStrings.logHabits.localized),
                                ("xmark", NafsStrings.muhasabah.localized),
                                ("xmark", NafsStrings.panicMode.localized),
                                ("xmark", NafsStrings.circles.localized),
                                ("xmark", NafsStrings.widgetsFeature.localized),
                                ("xmark", NafsStrings.tabNafsAI.localized),
                            ],
                            isPremium: false
                        )

                        PaywallTierCard(
                            title: NafsStrings.premiumTitle.localized,
                            subtitle: NafsStrings.completeDeen.localized,
                            features: [
                                ("checkmark", NafsStrings.focusMode.localized),
                                ("checkmark", NafsStrings.prayerLock.localized),
                                ("checkmark", NafsStrings.disciplineMode.localized),
                                ("checkmark", NafsStrings.quranAudioFull.localized),
                                ("checkmark", NafsStrings.logHabits.localized),
                                ("checkmark", NafsStrings.muhasabah.localized),
                                ("checkmark", NafsStrings.panicMode.localized),
                                ("checkmark", NafsStrings.circles.localized),
                                ("checkmark", NafsStrings.widgetsFeature.localized),
                                ("checkmark", NafsStrings.tabNafsAI.localized),
                                ("checkmark", NafsStrings.dhikr.localized),
                                ("checkmark", NafsStrings.guidedPlans.localized),
                                ("checkmark", NafsStrings.gardenOfDeeds.localized),
                                ("checkmark", NafsStrings.qiblaFinder.localized),
                            ],
                            isPremium: true
                        )
                    }

                    Text(NafsStrings.masjidQuote.localized)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .italic()
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 8)

            NafsButton(title: NafsStrings.seePricing.localized) {
                onContinue()
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct PaywallTierCard: View {
    let title: String
    let subtitle: String
    let features: [(String, String)]
    let isPremium: Bool

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(isPremium ? NafsTheme.gold : NafsTheme.text)
                Text(subtitle)
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.1) { icon, text in
                    HStack(spacing: 6) {
                        Image(systemName: icon == "checkmark" ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(icon == "checkmark" ? (isPremium ? NafsTheme.gold : .green.opacity(0.6)) : .red.opacity(0.4))
                        Text(text)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(icon == "checkmark" ? NafsTheme.text : NafsTheme.subtleText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isPremium ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isPremium ? NafsTheme.gold.opacity(0.4) : NafsTheme.cardBorder, lineWidth: isPremium ? 2 : 1)
        )
    }
}

struct PaywallTrustSubscreen: View {
    let vm: OnboardingViewModel
    let onContinue: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        TrustBadge(icon: "lock.shield.fill", text: NafsStrings.trustNoData.localized)
                        TrustBadge(icon: "bell.badge", text: NafsStrings.trustReminder.localized)
                        TrustBadge(icon: "gearshape", text: NafsStrings.trustCancel.localized)
                        TrustBadge(icon: "person.3.fill", text: NafsStrings.trustJoin.localized)
                    }

                    Text(NafsStrings.trustBuilt.localized)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    HStack(spacing: 12) {
                        PaywallStatCard(value: "5", label: L10n.text("Daily prayers\nto protect", "صلوات يومية\nلحمايتها"))
                        PaywallStatCard(value: "1.8B", label: L10n.text("Muslims\nworldwide", "مسلم\nحول العالم"))
                        PaywallStatCard(value: "0", label: L10n.text("Ads.\nEver.", "إعلانات.\nأبداً."))
                    }

                    Text(NafsStrings.trustBeAmong.localized)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(NafsTheme.gold.opacity(0.3))
                            .frame(width: 40, height: 1)
                        Text(L10n.text("\"Verily, Allah loves that when one of you does a deed, he does it with excellence.\"", "\"إن الله يحب إذا عمل أحدكم عملاً أن يتقنه.\""))
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .italic()
                        Text(L10n.text("— Prophet Muhammad \u{FDFA}", "— النبي محمد \u{FDFA}"))
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .padding(16)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 8)

            NafsButton(title: NafsStrings.seeMyPlan.localized) {
                onContinue()
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct PaywallStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(NafsTheme.gold)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(.white)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(NafsTheme.gold)
                .frame(width: 24)
            Text(text)
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.text)
            Spacer()
        }
        .padding(14)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 12))
    }
}

nonisolated enum SubscriptionPlan: String, CaseIterable, Sendable, Identifiable {
    case weekly, monthly, yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return NafsStrings.weeklyTitle.localized
        case .monthly: return NafsStrings.monthlyTitle.localized
        case .yearly: return NafsStrings.yearlyTitle.localized
        }
    }

    var price: String {
        switch self {
        case .weekly: return "$1.99"
        case .monthly: return "$7.99"
        case .yearly: return "$39.99"
        }
    }

    var period: String {
        switch self {
        case .weekly: return NafsStrings.perWeek.localized
        case .monthly: return NafsStrings.perMonth.localized
        case .yearly: return NafsStrings.perYear.localized
        }
    }

    var badge: String? {
        switch self {
        case .weekly: return NafsStrings.tryItOut.localized
        case .monthly: return nil
        case .yearly: return NafsStrings.mostPopular.localized
        }
    }

    var hasTrial: Bool {
        self == .yearly
    }



    var subtitle: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return nil
        case .yearly: return NafsStrings.lessThanWeek.localized
        }
    }
}

struct PaywallPricingSubscreen: View {
    let vm: OnboardingViewModel
    let storeViewModel: StoreViewModel
    let countdownMinutes: Int
    let onStartTrial: () -> Void
    let onFreePlan: () -> Void
    @State private var appeared: Bool = false
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var hapticTrigger: Int = 0
    @State private var purchaseError: String?
    @State private var isRestoring: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text(NafsStrings.nafsPremium.localized)
                            .font(.system(.title2, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Text(L10n.text("Full access to your companion.", "وصول كامل إلى رفيقك."))
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    .padding(.top, 4)

                    VStack(spacing: 10) {
                        ForEach(SubscriptionPlan.allCases) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                displayPrice: dynamicPrice(for: plan),
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPlan = plan
                                        hapticTrigger += 1
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 12)

            VStack(spacing: 10) {
                if storeViewModel.isLoading && !storeViewModel.hasPackages {
                    ProgressView()
                        .tint(NafsTheme.gold)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                } else {
                    NafsButton(
                        title: selectedPlan.hasTrial ? NafsStrings.startFreeTrial.localized : NafsStrings.subscribeNow.localized,
                        arabicSubtitle: selectedPlan.hasTrial ? "\u{0628}\u{0633}\u{0645} \u{0627}\u{0644}\u{0644}\u{0647}" : nil,
                        isLoading: storeViewModel.isPurchasing
                    ) {
                        guard !storeViewModel.isPurchasing else { return }
                        Task {
                            var package = packageForPlan(selectedPlan)
                            if package == nil {
                                await storeViewModel.fetchOfferings()
                                try? await Task.sleep(for: .seconds(1))
                                package = packageForPlan(selectedPlan)
                            }
                            if package == nil {
                                await storeViewModel.fetchOfferings()
                                try? await Task.sleep(for: .seconds(2))
                                package = packageForPlan(selectedPlan)
                            }
                            guard let package else {
                                purchaseError = L10n.text("Unable to load subscriptions from the App Store. Please check your internet connection, close the app completely, and try again.", "تعذر تحميل الاشتراكات من المتجر. يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.")
                                return
                            }
                            let success = await storeViewModel.purchase(package: package)
                            if success {
                                await storeViewModel.checkStatus()
                                onStartTrial()
                            }
                        }
                    }
                }

                Text(selectedPlan.hasTrial
                     ? L10n.text(
                        "7-day free trial, then \(dynamicPrice(for: .yearly))/year. Auto-renews unless canceled at least 24 hours before the end of the trial.",
                        "تجربة مجانية ٧ أيام، ثم \(dynamicPrice(for: .yearly))/سنة. يتجدد تلقائياً ما لم يتم الإلغاء قبل ٢٤ ساعة من نهاية التجربة."
                     )
                     : NafsStrings.subscriptionTerms.localized)
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    Button {
                        if let url = URL(string: PaywallConstants.privacyPolicyURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(NafsStrings.privacyPolicy.localized)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }

                    Text("·")
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        if let url = URL(string: PaywallConstants.termsOfUseURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(NafsStrings.termsOfUse.localized)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }

                    Text("·")
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        Task {
                            isRestoring = true
                            let success = await storeViewModel.restore()
                            isRestoring = false
                            if success {
                                onStartTrial()
                            }
                        }
                    } label: {
                        Text(isRestoring ? NafsStrings.restoringText.localized : NafsStrings.restorePurchases.localized)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                            .underline()
                    }
                }

                Button {
                    onFreePlan()
                } label: {
                    Text(NafsStrings.continueFreePlan.localized)
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .underline()
                }
            }
            .padding(.horizontal, 24)
            .alert("Error", isPresented: .init(
                get: { storeViewModel.error != nil || purchaseError != nil },
                set: { if !$0 { storeViewModel.error = nil; purchaseError = nil } }
            )) {
                Button("OK") { storeViewModel.error = nil; purchaseError = nil }
            } message: {
                Text(purchaseError ?? storeViewModel.error ?? "")
            }

            Spacer().frame(height: 20)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func packageForPlan(_ plan: SubscriptionPlan) -> RevenueCat.Package? {
        switch plan {
        case .weekly: return storeViewModel.weeklyPackage
        case .monthly: return storeViewModel.monthlyPackage
        case .yearly: return storeViewModel.yearlyPackage
        }
    }

    private func dynamicPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .weekly: return storeViewModel.weeklyPackage?.storeProduct.localizedPriceString ?? plan.price
        case .monthly: return storeViewModel.monthlyPackage?.storeProduct.localizedPriceString ?? plan.price
        case .yearly: return storeViewModel.yearlyPackage?.storeProduct.localizedPriceString ?? plan.price
        }
    }
}

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    var displayPrice: String = ""
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(NafsTheme.gold)
                                .frame(width: 12, height: 12)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(plan == .yearly ? NafsTheme.goldGradient : LinearGradient(colors: [NafsTheme.subtleText], startPoint: .leading, endPoint: .trailing))
                                .clipShape(.capsule)
                        }
                    }
                    if let subtitle = plan.subtitle {
                        Text(subtitle)
                            .font(.system(.caption))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    if plan.hasTrial {
                        Text(NafsStrings.sevenDayTrial.localized)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(displayPrice.isEmpty ? plan.price : displayPrice)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.text)
                    Text(plan.period)
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .padding(16)
            .background(isSelected ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
