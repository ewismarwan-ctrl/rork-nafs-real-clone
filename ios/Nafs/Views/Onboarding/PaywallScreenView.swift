import SwiftUI
import RevenueCat

enum PaywallConstants {
    static let privacyPolicyURL = NafsConstants.privacyPolicyURL
    static let termsOfUseURL = NafsConstants.termsOfUseURL
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

    var hasTrial: Bool {
        self == .yearly
    }
}

struct PaywallScreenView: View {
    let vm: OnboardingViewModel
    let storeViewModel: StoreViewModel
    @State private var appeared: Bool = false
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var hapticTrigger: Int = 0
    @State private var purchaseTrigger: Int = 0
    @State private var purchaseError: String?
    @State private var isRestoring: Bool = false
    @State private var showExitOffer: Bool = false

    private let benefits: [String] = [
        "Apps lock at prayer time",
        "Remove distractions instantly",
        "Build real consistency"
    ]

    var body: some View {
        if showExitOffer {
            OneTimeOfferView(
                storeViewModel: storeViewModel,
                onPurchase: { startPurchase(preferDiscount: true) },
                onRestore: { restorePurchases() },
                purchaseError: $purchaseError
            )
        } else {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                showExitOffer = true
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(NafsTheme.subtleText)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(NafsTheme.card))
                        }
                    }

                    VStack(spacing: 14) {
                        OnboardingHeadline(black: "Start protecting", gold: "your Salah")
                        OnboardingSubtext(lines: [
                            "Prayer Lock is the core of Nafs.",
                            "Start with 3 days free. No payment due now."
                        ])
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack(spacing: 14) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(NafsTheme.gold)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(NafsTheme.gold.opacity(0.12)))
                                Text(benefit)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        Text("No Payment Due Now")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(NafsTheme.gold)
                            .clipShape(.capsule)

                        PlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            isHighlighted: true,
                            displayPrice: dynamicPrice(for: .yearly),
                            dailyEquivalent: "3 days free, then \(dynamicPrice(for: .yearly))/year",
                            onSelect: { select(.yearly) }
                        )

                        CompactPlanCard(
                            plan: .weekly,
                            isSelected: selectedPlan == .weekly,
                            displayPrice: dynamicPrice(for: .weekly),
                            onSelect: { select(.weekly) }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                if storeViewModel.isLoading && !storeViewModel.hasPackages {
                    ProgressView()
                        .tint(NafsTheme.gold)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                } else {
                    NafsButton(
                        title: selectedPlan == .yearly ? "Start 3-Day Free Trial" : "Continue",
                        isLoading: storeViewModel.isPurchasing
                    ) {
                        startPurchase(preferDiscount: false)
                    }
                }

                Text(selectedPlan == .yearly ? "3 days free, then yearly price" : "Weekly option shown as anchor")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NafsTheme.gold.opacity(0.85))

                Text("Payment starts after the trial unless canceled.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 14) {
                    Button {
                        Task {
                            isRestoring = true
                            let success = await storeViewModel.restore()
                            isRestoring = false
                            if success { vm.completeOnboarding() }
                        }
                    } label: {
                        Text(isRestoring ? "Restoring…" : "Restore Purchases")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }
                    .disabled(isRestoring)

                    Text("·").font(.system(size: 11)).foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        if let url = URL(string: PaywallConstants.privacyPolicyURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Privacy Policy")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }

                    Text("·").font(.system(size: 11)).foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        if let url = URL(string: PaywallConstants.termsOfUseURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Terms of Use")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }
                }

            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NafsTheme.background)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .sensoryFeedback(.success, trigger: purchaseTrigger)
        .alert("Error", isPresented: .init(
            get: { storeViewModel.error != nil || purchaseError != nil },
            set: { if !$0 { storeViewModel.error = nil; purchaseError = nil } }
        )) {
            Button("OK") { storeViewModel.error = nil; purchaseError = nil }
        } message: {
            Text(purchaseError ?? storeViewModel.error ?? "")
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
        }
    }

    private func select(_ plan: SubscriptionPlan) {
        withAnimation(.spring(response: 0.3)) {
            selectedPlan = plan
            hapticTrigger += 1
        }
    }

    private func startPurchase(preferDiscount: Bool) {
        guard !storeViewModel.isPurchasing else { return }
        Task {
            var package = preferDiscount ? (storeViewModel.discountedYearlyPackage ?? storeViewModel.yearlyPackage) : packageForPlan(selectedPlan)
            if package == nil {
                await storeViewModel.fetchOfferings()
                try? await Task.sleep(for: .seconds(1))
                package = preferDiscount ? (storeViewModel.discountedYearlyPackage ?? storeViewModel.yearlyPackage) : packageForPlan(selectedPlan)
            }
            if package == nil {
                await storeViewModel.fetchOfferings()
                try? await Task.sleep(for: .seconds(2))
                package = preferDiscount ? (storeViewModel.discountedYearlyPackage ?? storeViewModel.yearlyPackage) : packageForPlan(selectedPlan)
            }
            guard let package else {
                purchaseError = "Unable to load subscriptions from the App Store. Please check your connection and try again."
                return
            }
            let success = await storeViewModel.purchase(package: package)
            if success {
                purchaseTrigger += 1
                await storeViewModel.checkStatus()
                vm.completeOnboarding()
            }
        }
    }

    private func restorePurchases() {
        Task {
            isRestoring = true
            let success = await storeViewModel.restore()
            isRestoring = false
            if success { vm.completeOnboarding() }
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

    private func dailyPrice(for plan: SubscriptionPlan) -> String {
        let pkg: RevenueCat.Package? = {
            switch plan {
            case .weekly: return storeViewModel.weeklyPackage
            case .monthly: return storeViewModel.monthlyPackage
            case .yearly: return storeViewModel.yearlyPackage
            }
        }()
        let priceDecimal: Decimal
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        if let product = pkg?.storeProduct {
            priceDecimal = product.price
            formatter.currencyCode = product.currencyCode ?? "USD"
        } else {
            priceDecimal = 39.99
            formatter.currencyCode = "USD"
        }
        let divisor: Decimal = plan == .yearly ? 365 : (plan == .monthly ? 30 : 7)
        let perDay = priceDecimal / divisor
        let rounded = NSDecimalNumber(decimal: perDay).doubleValue
        let bumped = (ceil(rounded * 100) / 100)
        let display = formatter.string(from: NSNumber(value: bumped)) ?? "$0.11"
        return "Less than \(display)/day"
    }
}

private struct OneTimeOfferView: View {
    let storeViewModel: StoreViewModel
    let onPurchase: () -> Void
    let onRestore: () -> Void
    @Binding var purchaseError: String?
    @State private var secondsRemaining = 10 * 60
    @State private var appeared = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            VStack(spacing: 12) {
                Text("One Time Offer")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(NafsTheme.gold)
                Text("70% OFF")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text("Lowest price. Billed yearly.")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            ZStack {
                Circle()
                    .stroke(NafsTheme.card, lineWidth: 12)
                    .frame(width: 154, height: 154)
                Circle()
                    .trim(from: 0, to: CGFloat(secondsRemaining) / 600)
                    .stroke(NafsTheme.goldGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 154, height: 154)
                    .rotationEffect(.degrees(-90))
                Text(timeString)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }

            VStack(spacing: 12) {
                NafsButton(title: "Claim your one time offer", isLoading: storeViewModel.isPurchasing) {
                    onPurchase()
                }

                Button(action: onRestore) {
                    Text("Restore Purchases")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .underline()
                }
            }

            Text("Discounted RevenueCat product ID is optional for now. If no discount product exists, Nafs falls back to the yearly package.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.black.ignoresSafeArea())
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.spring(response: 0.5)) { appeared = true } }
        .onReceive(timer) { _ in
            if secondsRemaining > 0 { secondsRemaining -= 1 }
        }
    }

    private var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    var isHighlighted: Bool = false
    var displayPrice: String = ""
    var dailyEquivalent: String? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if isSelected {
                            Circle().fill(NafsTheme.gold).frame(width: 12, height: 12)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        if isHighlighted {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(NafsTheme.goldGradient)
                                .clipShape(.capsule)
                        }
                    }
                    if plan.hasTrial {
                        Text("7-day free trial")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    if let daily = dailyEquivalent {
                        Text(daily)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(displayPrice.isEmpty ? plan.price : displayPrice)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.text)
                    Text(plan.period)
                        .font(.system(size: 11))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .padding(16)
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    var displayPrice: String = ""
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Text(plan.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NafsTheme.subtleText)
                Text(displayPrice.isEmpty ? plan.price : displayPrice)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.text)
                Text(plan.period)
                    .font(.system(size: 10))
                    .foregroundStyle(NafsTheme.subtleText.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
