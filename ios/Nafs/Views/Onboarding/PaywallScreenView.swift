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
    @State private var hapticTrigger: Int = 0
    @State private var purchaseError: String?
    @State private var isRestoring: Bool = false

    private var benefits: [(String, String)] {
        [
            ("lock.shield.fill", L10n.text("Locks apps at prayer time", "يقفل التطبيقات وقت الصلاة")),
            ("checkmark.seal.fill", L10n.text("Builds real consistency", "يبني مداومة حقيقية")),
            ("sparkles", L10n.text("Keeps you focused when it matters", "يبقيك مركّزاً وقت الحاجة"))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer().frame(height: 12)

                    VStack(spacing: 10) {
                        Text(L10n.text("Stop delaying Salah.", "كفى تأخيراً للصلاة."))
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.8)

                        Text(L10n.text("Let Nafs handle your distractions.", "دع نفس يتولّى مشتتاتك."))
                            .font(.system(.title3, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(benefits, id: \.1) { icon, text in
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(NafsTheme.gold)
                                    .frame(width: 24)
                                Text(text)
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NafsTheme.gold.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    PaywallTrialCard(yearlyPrice: yearlyPrice, dailyPrice: dailyPrice)
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(NafsTheme.gold)
                        Text(L10n.text("Cancel anytime", "إلغاء في أي وقت"))
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                    }
                }
                .padding(.bottom, 8)
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                if storeViewModel.isLoading && !storeViewModel.hasPackages {
                    ProgressView().tint(NafsTheme.gold).frame(height: 56).frame(maxWidth: .infinity)
                } else {
                    NafsButton(
                        title: L10n.text("Start Free Trial", "ابدأ التجربة المجانية"),
                        arabicSubtitle: nil,
                        isLoading: storeViewModel.isPurchasing
                    ) {
                        guard !storeViewModel.isPurchasing else { return }
                        hapticTrigger += 1
                        Task { await purchase() }
                    }
                }

                Text(L10n.text(
                    "7-day free trial, then \(yearlyPrice)/year (\(dailyPrice)/day). Auto-renews unless canceled at least 24 hours before the end of the trial.",
                    "تجربة مجانية ٧ أيام، ثم \(yearlyPrice)/سنة (\(dailyPrice)/يوم). يتجدد تلقائياً ما لم يتم الإلغاء قبل ٢٤ ساعة من نهاية التجربة."
                ))
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    LinkButton(L10n.text("Privacy", "الخصوصية")) {
                        if let url = URL(string: PaywallConstants.privacyPolicyURL) { UIApplication.shared.open(url) }
                    }
                    Text("·").font(.caption2).foregroundStyle(NafsTheme.subtleText.opacity(0.5))
                    LinkButton(L10n.text("Terms", "الشروط")) {
                        if let url = URL(string: PaywallConstants.termsOfUseURL) { UIApplication.shared.open(url) }
                    }
                    Text("·").font(.caption2).foregroundStyle(NafsTheme.subtleText.opacity(0.5))
                    LinkButton(isRestoring ? L10n.text("Restoring…", "جارٍ الاستعادة…") : L10n.text("Restore Purchases", "استعادة المشتريات"), color: NafsTheme.gold) {
                        Task {
                            isRestoring = true
                            let success = await storeViewModel.restore()
                            isRestoring = false
                            if success { vm.completeOnboarding() }
                        }
                    }
                }

                Button {
                    vm.completeOnboarding()
                } label: {
                    Text(L10n.text("Continue with limited free version", "المتابعة بالنسخة المجانية"))
                        .font(.system(.footnote, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .underline()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .alert("Error", isPresented: .init(
                get: { storeViewModel.error != nil || purchaseError != nil },
                set: { if !$0 { storeViewModel.error = nil; purchaseError = nil } }
            )) {
                Button("OK") { storeViewModel.error = nil; purchaseError = nil }
            } message: {
                Text(purchaseError ?? storeViewModel.error ?? "")
            }
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var yearlyPrice: String {
        storeViewModel.yearlyPackage?.storeProduct.localizedPriceString ?? "$39.99"
    }

    private var dailyPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        if let product = storeViewModel.yearlyPackage?.storeProduct {
            formatter.currencyCode = product.currencyCode ?? "USD"
            let perDay = NSDecimalNumber(decimal: product.price).doubleValue / 365.0
            let bumped = ceil(perDay * 100) / 100
            return formatter.string(from: NSNumber(value: bumped)) ?? "$0.11"
        }
        formatter.currencyCode = "USD"
        return "$0.11"
    }

    private func purchase() async {
        var package = storeViewModel.yearlyPackage
        if package == nil {
            await storeViewModel.fetchOfferings()
            try? await Task.sleep(for: .seconds(1))
            package = storeViewModel.yearlyPackage
        }
        guard let package else {
            purchaseError = L10n.text(
                "Unable to load subscriptions. Please check your internet connection and try again.",
                "تعذر تحميل الاشتراكات. تحقق من اتصالك وحاول مجدداً."
            )
            return
        }
        let success = await storeViewModel.purchase(package: package)
        if success {
            await storeViewModel.checkStatus()
            vm.completeOnboarding()
        }
    }
}

private struct PaywallTrialCard: View {
    let yearlyPrice: String
    let dailyPrice: String

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill").foregroundStyle(NafsTheme.gold)
                Text(L10n.text("7-day free trial", "تجربة مجانية ٧ أيام"))
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(L10n.text("then", "ثم"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                Text(yearlyPrice)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(NafsTheme.text)
                Text(L10n.text("/year", "/سنة"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Text(L10n.text("≈ \(dailyPrice)/day", "≈ \(dailyPrice)/يوم"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(NafsTheme.gold, lineWidth: 1.5)
        )
    }
}

private struct LinkButton: View {
    let title: String
    var color: Color = NafsTheme.subtleText
    let action: () -> Void

    init(_ title: String, color: Color = NafsTheme.subtleText, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption2, weight: .medium))
                .foregroundStyle(color)
                .underline()
        }
    }
}
