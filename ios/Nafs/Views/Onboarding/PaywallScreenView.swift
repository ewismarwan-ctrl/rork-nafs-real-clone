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

    private let benefits: [String] = [
        "Apps lock at prayer time",
        "Pray without distractions",
        "Build real consistency"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 16)

                    VStack(spacing: 14) {
                        OnboardingHeadline(black: "Stop delaying", gold: "Salah")
                        OnboardingSubtext(lines: [
                            "Your apps will lock at prayer time.",
                            "So you can finally pray on time."
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

                    VStack(spacing: 10) {
                        PlanCard(
                            plan: .yearly,
                            isSelected: selectedPlan == .yearly,
                            isHighlighted: true,
                            displayPrice: dynamicPrice(for: .yearly),
                            dailyEquivalent: dailyPrice(for: .yearly),
                            onSelect: { select(.yearly) }
                        )

                        HStack(spacing: 10) {
                            CompactPlanCard(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                displayPrice: dynamicPrice(for: .monthly),
                                onSelect: { select(.monthly) }
                            )
                            CompactPlanCard(
                                plan: .weekly,
                                isSelected: selectedPlan == .weekly,
                                displayPrice: dynamicPrice(for: .weekly),
                                onSelect: { select(.weekly) }
                            )
                        }
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
                        title: "Start Free Trial",
                        isLoading: storeViewModel.isPurchasing
                    ) {
                        startPurchase()
                    }
                }

                Text("Cancel anytime")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)

                HStack(spacing: 14) {
                    Button {
                        Task {
                            isRestoring = true
                            let success = await storeViewModel.restore()
                            isRestoring = false
                            if success { vm.completeOnboarding() }
                        }
                    } label: {
                        Text(isRestoring ? "Restoring…" : "Restore")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }

                    Text("·").font(.system(size: 11)).foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        if let url = URL(string: PaywallConstants.privacyPolicyURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Privacy")
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
                        Text("Terms")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .underline()
                    }
                }

                Button {
                    vm.completeOnboarding()
                } label: {
                    Text("Continue with free plan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .underline()
                }
                .padding(.top, 2)
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

    private func select(_ plan: SubscriptionPlan) {
        withAnimation(.spring(response: 0.3)) {
            selectedPlan = plan
            hapticTrigger += 1
        }
    }

    private func startPurchase() {
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
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : Color.white)
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
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : Color.white)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
