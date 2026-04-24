import SwiftUI
import StoreKit

struct SettingsView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showAbout: Bool = false
    @State private var editingName: String = ""
    @State private var showPaywall: Bool = false
    @State private var showLanguagePicker: Bool = false
    @State private var restoreAlert: RestoreAlert?
    @State private var isRestoring: Bool = false
    @Environment(LanguageManager.self) private var lang

    private struct RestoreAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private let appStoreURL = NafsConstants.appStoreURL

    var body: some View {
        List {
                profileSection
                prayerSection
                languageSection
                appSection
                accountSection
                legalSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(NafsStrings.settings.localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAbout) {
                AboutNafsSheet()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showPaywall) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: "Nafs Premium",
                    benefit: "Unlock all features and take full control of your screen time and spiritual growth.",
                    onDismiss: { showPaywall = false },
                    onSuccess: { showPaywall = false }
                )
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet(languageManager: lang)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert(item: $restoreAlert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        .onAppear {
            editingName = viewModel.userName
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(String(viewModel.userName.prefix(1)).uppercased())
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField(lang.isArabic ? "اسمك" : "Your name", text: $editingName)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                        .onSubmit {
                            viewModel.userName = editingName
                        }
                    Text(lang.isArabic ? "انضم مؤخراً" : "Joined recently")
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(NafsStrings.profile.localized)
        }
    }

    private var prayerSection: some View {
        Section {
            ForEach(PrayerName.allCases, id: \.rawValue) { prayer in
                Toggle(isOn: Binding(
                    get: { viewModel.prayerNotifications[prayer] ?? true },
                    set: { newValue in
                        viewModel.prayerNotifications[prayer] = newValue
                        NotificationService.shared.schedulePrayerNotifications(
                            prayerTimes: viewModel.prayerTimes,
                            enabledPrayers: viewModel.prayerNotifications
                        )
                    }
                )) {
                    Label(NafsStrings.prayerName(prayer), systemImage: prayer.icon)
                        .foregroundStyle(NafsTheme.text)
                }
                .tint(NafsTheme.gold)
            }

            HStack {
                Label(lang.isArabic ? "طريقة الحساب" : "Calculation Method", systemImage: "clock.badge.questionmark")
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Menu {
                    ForEach(PrayerCalculationMethod.allCases, id: \.rawValue) { method in
                        Button(method.rawValue) {
                            viewModel.calculationMethod = method
                        }
                    }
                } label: {
                    Text(viewModel.calculationMethod.rawValue)
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.gold)
                }
            }
        } header: {
            Text(NafsStrings.prayerTimes.localized)
        }
    }

    private var languageSection: some View {
        Section {
            Button {
                showLanguagePicker = true
            } label: {
                HStack {
                    Label {
                        Text(NafsStrings.language.localized)
                            .foregroundStyle(NafsTheme.text)
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(NafsTheme.gold)
                    }
                    Spacer()
                    Text(lang.isArabic ? "العربية 🇸🇦" : "English 🇬🇧")
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.gold)
                    Image(systemName: "chevron.right")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                }
            }
        } header: {
            Text(NafsStrings.language.localized)
        }
    }

    private var appSection: some View {
        Section {
            Button {
                requestAppReview()
            } label: {
                Label(NafsStrings.rateNafs.localized, systemImage: "star.fill")
                    .foregroundStyle(NafsTheme.text)
            }

            ShareLink(
                item: URL(string: appStoreURL)!,
                subject: Text("Check out Nafs"),
                message: Text("I've been using Nafs to discipline my screen time and strengthen my deen. Check it out: \(appStoreURL)")
            ) {
                Label(NafsStrings.shareNafs.localized, systemImage: "square.and.arrow.up")
                    .foregroundStyle(NafsTheme.text)
            }
        } header: {
            Text(NafsStrings.app.localized)
        }
    }

    private var accountSection: some View {
        Section {
            Button {
                if !viewModel.isPremium {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NafsStrings.subscription.localized)
                                .foregroundStyle(NafsTheme.text)
                            Text(viewModel.isPremium ? (lang.isArabic ? "نفس بريميوم — نشط" : "Nafs Premium — Active") : (lang.isArabic ? "خطة مجانية" : "Free Plan"))
                                .font(.system(.caption))
                                .foregroundStyle(viewModel.isPremium ? NafsTheme.gold : NafsTheme.subtleText)
                        }
                    } icon: {
                        Image(systemName: viewModel.isPremium ? "crown.fill" : "crown")
                            .foregroundStyle(NafsTheme.gold)
                    }
                    Spacer()
                    if !viewModel.isPremium {
                        Text(lang.isArabic ? "ترقية" : "Upgrade")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NafsTheme.goldGradient)
                            .clipShape(.capsule)
                    }
                }
            }

            Button {
                hasCompletedOnboarding = false
            } label: {
                Label(NafsStrings.replayOnboarding.localized, systemImage: "arrow.counterclockwise")
                    .foregroundStyle(NafsTheme.gold)
            }
        } header: {
            Text(NafsStrings.account.localized)
        }
    }

    private var legalSection: some View {
        Section {
            Button {
                if let url = URL(string: PaywallConstants.privacyPolicyURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(NafsStrings.privacyPolicy.localized, systemImage: "hand.raised.fill")
                    .foregroundStyle(NafsTheme.text)
            }

            Button {
                if let url = URL(string: PaywallConstants.termsOfUseURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(NafsStrings.termsOfUse.localized, systemImage: "doc.text.fill")
                    .foregroundStyle(NafsTheme.text)
            }

            Button {
                guard !isRestoring else { return }
                isRestoring = true
                Task {
                    let success = await storeViewModel.restore()
                    isRestoring = false
                    if success {
                        restoreAlert = RestoreAlert(
                            title: lang.isArabic ? "تم الاستعادة" : "Purchases Restored",
                            message: lang.isArabic ? "تم تفعيل نفس بريميوم." : "Your Nafs Premium has been restored."
                        )
                    } else {
                        restoreAlert = RestoreAlert(
                            title: lang.isArabic ? "لا توجد مشتريات" : "No Purchases Found",
                            message: storeViewModel.error ?? (lang.isArabic ? "لم نعثر على اشتراك نشط على هذا الحساب." : "We couldn't find an active subscription on this Apple ID.")
                        )
                        storeViewModel.error = nil
                    }
                }
            } label: {
                HStack {
                    Label(NafsStrings.restorePurchases.localized, systemImage: "arrow.clockwise")
                        .foregroundStyle(NafsTheme.gold)
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
        } header: {
            Text(lang.isArabic ? "قانوني" : "Legal")
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        } else if let url = URL(string: NafsConstants.rateAppURL) {
            UIApplication.shared.open(url)
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label(lang.isArabic ? "حول نفس" : "About Nafs", systemImage: "info.circle")
                    .foregroundStyle(NafsTheme.text)
            }

            HStack {
                Label(lang.isArabic ? "الإصدار" : "Version", systemImage: "gear")
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Text("1.0.0")
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            HStack {
                Spacer()
                Text(lang.isArabic ? "صُنع بحب للأمة 🌙" : "Built with love for the Ummah 🌙")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.gold)
                Spacer()
            }
        }
    }

}

struct LanguagePickerSheet: View {
    let languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selected: NafsLanguage = NafsLanguage.current

    var body: some View {
        VStack(spacing: 20) {
            Text(languageManager.isArabic ? "اختر لغتك" : "Choose Language")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)
                .padding(.top, 8)

            HStack(spacing: 16) {
                languageCard(
                    flag: "🇬🇧",
                    title: "English",
                    subtitle: "Continue in English",
                    language: .english
                )

                languageCard(
                    flag: "🇸🇦",
                    title: "العربية",
                    subtitle: "تابع بالعربية",
                    language: .arabic
                )
            }
            .padding(.horizontal, 24)

            NafsButton(title: languageManager.isArabic ? "حفظ" : "Save") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    languageManager.switchTo(selected)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func languageCard(flag: String, title: String, subtitle: String, language: NafsLanguage) -> some View {
        let isSelected = selected == language
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selected = language
            }
        } label: {
            VStack(spacing: 12) {
                Text(flag)
                    .font(.system(size: 36))

                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: language == .arabic ? .default : .serif))
                    .foregroundStyle(language == .arabic ? NafsTheme.gold : NafsTheme.text)

                Text(subtitle)
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
    }
}

struct AboutNafsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    CrescentStarMark(size: 64, color: NafsTheme.gold)

                    Text("NAFS")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundStyle(NafsTheme.text)
                        .tracking(14)

                    Text("نفس")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.gold)

                    Rectangle()
                        .fill(NafsTheme.gold.opacity(0.4))
                        .frame(width: 80, height: 1)

                    Text("YOUR COMPLETE ISLAMIC LIFE COMPANION \u{1F319}")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(NafsTheme.text.opacity(0.45))
                        .tracking(3)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Our Story")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(NafsTheme.text)

                    Text("Nafs was born from a simple observation: the same phone that can play the Quran also steals hours of our life every day. We built Nafs to flip that equation — to make your phone work for your deen, not against it.")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.text)
                        .lineSpacing(4)

                    Text("Every feature in Nafs is designed around one principle: your ibadah has real value. The Hasanat token system turns your daily worship into a currency that governs your screen time. Pray, read Quran, make dhikr — and your phone opens up. Skip your prayers — and your distracting apps stay locked.")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.text)
                        .lineSpacing(4)

                    Text("We don't sell your data. We don't show ads. We exist to help Muslims reclaim their time and strengthen their connection with Allah.")
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.text)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
        .background(NafsTheme.background)
    }
}
