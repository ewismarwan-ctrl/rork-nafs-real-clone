import SwiftUI
import RevenueCat

struct UpgradePaywallSheet: View {
    let storeViewModel: StoreViewModel
    let feature: String
    let benefit: String
    let onDismiss: () -> Void
    let onSuccess: () -> Void
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var hapticTrigger: Int = 0
    @State private var isRestoring: Bool = false
    @State private var purchaseError: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer().frame(height: 8)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(NafsTheme.gold)
                        .padding(16)
                        .background(NafsTheme.gold.opacity(0.1))
                        .clipShape(Circle())

                    VStack(spacing: 8) {
                        Text(feature)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Text(benefit)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    VStack(spacing: 10) {
                        ForEach(SubscriptionPlan.allCases) { plan in
                            UpgradePlanCard(
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

            VStack(spacing: 10) {
                if storeViewModel.isLoading && !storeViewModel.hasPackages {
                    ProgressView()
                        .tint(NafsTheme.gold)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                } else {
                    if selectedPlan.hasTrial {
                        Text("7-day free trial, then \(dynamicPrice(for: .yearly))/year. Auto-renews unless canceled at least 24 hours before the end of the trial.")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                    }

                    NafsButton(
                        title: selectedPlan.hasTrial ? NafsStrings.startFreeTrial.localized : NafsStrings.subscribeNow.localized,
                        arabicSubtitle: selectedPlan.hasTrial ? "بسم الله" : nil,
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
                                purchaseError = "Unable to load subscriptions from the App Store. Please check your internet connection, close the app completely, and try again."
                                return
                            }
                            let success = await storeViewModel.purchase(package: package)
                            if success {
                                await storeViewModel.checkStatus()
                                onSuccess()
                            }
                        }
                    }
                }

                Text(selectedPlan.hasTrial ? NafsStrings.trialDisclosure.localized : NafsStrings.subscriptionTerms.localized)
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

                    Text("\u{00b7}")
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

                    Text("\u{00b7}")
                        .font(.system(.caption2))
                        .foregroundStyle(NafsTheme.subtleText.opacity(0.5))

                    Button {
                        Task {
                            isRestoring = true
                            let success = await storeViewModel.restore()
                            isRestoring = false
                            if success { onSuccess() }
                        }
                    } label: {
                        Text(isRestoring ? NafsStrings.restoringText.localized : NafsStrings.restorePurchases.localized)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                            .underline()
                    }
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Not now")
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .underline()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            if storeViewModel.offerings == nil || storeViewModel.weeklyPackage == nil {
                await storeViewModel.fetchOfferings()
            }
        }
        .alert("Error", isPresented: .init(
            get: { storeViewModel.error != nil || purchaseError != nil },
            set: { if !$0 { storeViewModel.error = nil; purchaseError = nil } }
        )) {
            Button("OK") { storeViewModel.error = nil; purchaseError = nil }
        } message: {
            Text(purchaseError ?? storeViewModel.error ?? "")
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

private struct UpgradePlanCard: View {
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
                        Text("7-day free trial")
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
