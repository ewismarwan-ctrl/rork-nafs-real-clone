import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var appViewModel = AppViewModel()
    @State private var storeViewModel = StoreViewModel()
    @State private var languageManager = LanguageManager()
    @State private var navigationState = AppNavigationState()
    @State private var appearance = AppearanceManager()
    @State private var showMainApp: Bool = false
    @State private var showOpeningSplash: Bool = true

    private var userName: String {
        UserDefaults.standard.string(forKey: "nafs_userName") ?? "Friend"
    }

    private func handleIncomingURL(_ url: URL) {
        // Reserved for future deep link handling.
        _ = url
    }

    var body: some View {
        ZStack {
            Group {
                if hasCompletedOnboarding && (hasSeenWelcome || showMainApp) {
                    MainTabView(viewModel: appViewModel, storeViewModel: storeViewModel, languageManager: languageManager)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else if hasCompletedOnboarding && !hasSeenWelcome {
                    WelcomeView(userName: userName) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            hasSeenWelcome = true
                            showMainApp = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    OnboardingContainerView(storeViewModel: storeViewModel, languageManager: languageManager)
                        .environment(appearance)
                }
            }

            if showOpeningSplash {
                NafsOpeningSplashView {
                    showOpeningSplash = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .environment(\.layoutDirection, languageManager.layoutDirection)
        .environment(languageManager)
        .environment(navigationState)
        .environment(appearance)
        .preferredColorScheme(appearance.appearance.colorScheme)
        .id(languageManager.current)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: hasCompletedOnboarding)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: showMainApp)
        .onChange(of: storeViewModel.isPremium) { _, newValue in
            appViewModel.isPremium = newValue
        }
        .task {
            appViewModel.storeViewModel = storeViewModel
            await storeViewModel.checkStatus()
            appViewModel.isPremium = storeViewModel.isPremium
        }
        .onOpenURL { url in
            handleIncomingURL(url)
        }
    }
}

struct MainTabView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    let languageManager: LanguageManager
    @Environment(AppNavigationState.self) private var navigationState
    @State private var previousTab: AppTab = .home
    @State private var audioPlayer = QuranAudioPlayer()

    private var isMiniBarVisible: Bool {
        audioPlayer.hasLoadedAudio || audioPlayer.isLoading
    }

    private let miniBarHeight: CGFloat = 60

    var body: some View {
        @Bindable var navigationState = navigationState

        ZStack(alignment: .bottom) {
            TabView(selection: $navigationState.selectedTab) {
                Tab(NafsStrings.tabHome.value(for: languageManager.current), systemImage: "house.fill", value: .home) {
                    HomeDashboardView(viewModel: viewModel, storeViewModel: storeViewModel)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }

                Tab("Focus", systemImage: "lock.shield.fill", value: .lock) {
                    FocusView(viewModel: viewModel, storeViewModel: storeViewModel)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }

                Tab(NafsStrings.tabMore.value(for: languageManager.current), systemImage: "ellipsis.circle.fill", value: .more) {
                    MoreView(viewModel: viewModel, storeViewModel: storeViewModel, audioPlayer: audioPlayer)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }
            }
            .tint(NafsTheme.gold)

            if isMiniBarVisible {
                GlobalMiniAudioBar(audioPlayer: audioPlayer, storeViewModel: storeViewModel)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 52)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isMiniBarVisible)
        .sheet(isPresented: Bindable(viewModel).showPremiumGate) {
            UpgradePaywallSheet(
                storeViewModel: storeViewModel,
                feature: viewModel.premiumGateFeature,
                benefit: viewModel.premiumGateBenefit,
                onDismiss: { viewModel.showPremiumGate = false },
                onSuccess: { viewModel.showPremiumGate = false }
            )
        }
        .onChange(of: navigationState.selectedTab) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue == .lock && !viewModel.isPremium {
                navigationState.selectedTab = previousTab == .lock ? .home : previousTab
                viewModel.premiumGateFeature = languageManager.isArabic ? "التركيز" : "Nafs Lock"
                viewModel.premiumGateBenefit = languageManager.isArabic ? "افتح ميزة التركيز لحجب المشتتات أثناء الصلاة والانضباط مع نفس بريميوم." : "Unlock Nafs Lock for advanced app blocking, earned screen time automation, and discipline protection."
                viewModel.showPremiumGate = true
            } else {
                previousTab = newValue
            }
        }
    }
}

enum AppTab: Hashable {
    case home, lock, more
}

struct MoreView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    let audioPlayer: QuranAudioPlayer
    @State private var showPremiumGate: Bool = false
    @State private var gateFeature: String = ""
    @State private var gateBenefit: String = ""
    @State private var showInfoAlert: Bool = false
    @State private var infoTitle: String = ""
    @State private var infoMessage: String = ""
    @State private var isRestoring: Bool = false
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        NavigationStack {
            List {
                Section("Worship Tools") {
                    moreRow(icon: "book.fill", title: NafsStrings.tabQuran.localized, subtitle: "Read, listen, and choose reciters.", dest: .quran, premium: false)
                    moreRow(icon: "hands.sparkles.fill", title: NafsStrings.dhikr.localized, subtitle: "Complete dhikr and build consistency.", dest: .dhikr, premium: false)
                    moreRow(icon: "brain.head.profile", title: NafsStrings.tabNafsAI.localized, subtitle: "Ask for focused Islamic guidance.", dest: .nafsAI, premium: true)
                    moreRow(icon: "map.fill", title: "Guided Plans", subtitle: "Structured plans live here, away from the core tabs.", dest: .guidedPlans, premium: true)
                }

                Section("Settings") {
                    moreRow(icon: "gearshape.fill", title: "Prayer & Lock Settings", subtitle: "Prayer times, notifications, and app blocking.", dest: .settings, premium: false)
                    actionRow(icon: "square.grid.2x2.fill", title: "Widgets", subtitle: "Configure widgets from iOS after adding them to your Home Screen.") {
                        showInfo(title: "Widgets", message: "Nafs widgets are available from the iOS widget picker. Long-press your Home Screen, tap Add Widget, then choose Nafs.")
                    }
                }

                Section("Account") {
                    actionRow(icon: "crown.fill", title: "Subscription", subtitle: "Manage Nafs Premium and Prayer Lock access.") {
                        gateFeature = "Nafs Premium"
                        gateBenefit = "Unlock Prayer Lock to block distracting apps during Salah."
                        showPremiumGate = true
                    }
                    actionRow(icon: "arrow.clockwise.circle.fill", title: isRestoring ? "Restoring..." : "Restore Purchases", subtitle: "Recover an existing subscription.") {
                        restorePurchases()
                    }
                    .disabled(isRestoring)
                }

                Section("Support") {
                    actionRow(icon: "questionmark.circle.fill", title: "Help", subtitle: "Learn the core loop.") {
                        showInfo(title: "Help", message: "Use Earn to complete worship actions, Lock to block distractions, and Progress to track discipline.")
                    }
                    actionRow(icon: "bubble.left.and.bubble.right.fill", title: "Feedback", subtitle: "Help make Nafs sharper.") {
                        showInfo(title: "Feedback", message: "Send feedback through the App Store page or your Nafs support channel.")
                    }
                    actionRow(icon: "info.circle.fill", title: "About", subtitle: "Stop delaying Salah.") {
                        showInfo(title: "About Nafs", message: "Nafs helps Muslims stop delaying Salah by locking distracting apps during prayer times until they pray.")
                    }
                    actionRow(icon: "doc.text.fill", title: "Legal", subtitle: "Privacy Policy and Terms of Use.") {
                        showInfo(title: "Legal", message: "Privacy Policy: \(NafsConstants.privacyPolicyURL)\n\nTerms of Use: \(NafsConstants.termsOfUseURL)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(NafsStrings.tabMore.localized)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: MoreDestination.self) { dest in
                switch dest {
                case .quran:
                    QuranListView(appViewModel: viewModel, storeViewModel: storeViewModel, audioPlayer: audioPlayer)
                case .dhikr:
                    DhikrView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .muhasabah:
                    MuhasabahView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .nafsAI:
                    NafsAIView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .guidedPlans:
                    GuidedPlansView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .settings:
                    SettingsView(viewModel: viewModel, storeViewModel: storeViewModel)
                }
            }
            .sheet(isPresented: $showPremiumGate) {
                UpgradePaywallSheet(
                    storeViewModel: storeViewModel,
                    feature: gateFeature,
                    benefit: gateBenefit,
                    onDismiss: { showPremiumGate = false },
                    onSuccess: { showPremiumGate = false }
                )
            }
            .alert(infoTitle, isPresented: $showInfoAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(infoMessage)
            }
        }
    }

    private func moreRow(icon: String, title: String, subtitle: String, dest: MoreDestination, premium: Bool) -> some View {
        Group {
            if premium && !viewModel.isPremium {
                Button {
                    gateFeature = title
                    gateBenefit = lang.isArabic ? "افتح \(title) وجميع الميزات المتقدمة مع نفس بريميوم." : "Unlock \(title) and all premium features with Nafs Premium."
                    showPremiumGate = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(NafsTheme.gold.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: icon)
                                .font(.system(.body))
                                .foregroundStyle(NafsTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(title)
                                    .font(.system(.body, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                Image(systemName: "lock.fill")
                                    .font(.system(.caption2))
                                    .foregroundStyle(NafsTheme.gold)
                            }
                            Text(subtitle)
                                .font(.system(.caption))
                                .foregroundStyle(NafsTheme.subtleText)
                        }
                        Spacer()
                        Text(lang.isArabic ? "PRO" : "PRO")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(NafsTheme.goldGradient)
                            .clipShape(.capsule)
                    }
                }
            } else {
                NavigationLink(value: dest) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(NafsTheme.gold.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: icon)
                                .font(.system(.body))
                                .foregroundStyle(NafsTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(NafsTheme.text)
                            Text(subtitle)
                                .font(.system(.caption))
                                .foregroundStyle(NafsTheme.subtleText)
                        }
                    }
                }
            }
        }
    }

    private func actionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let success = await storeViewModel.restore()
            await MainActor.run {
                isRestoring = false
                showInfo(
                    title: success ? "Purchases Restored" : "Nothing Found",
                    message: success ? "Your subscription is active on this device." : "No active subscription was found for this Apple ID."
                )
            }
        }
    }

    private func showInfo(title: String, message: String) {
        infoTitle = title
        infoMessage = message
        showInfoAlert = true
    }
}

enum MoreDestination: Hashable {
    case quran, dhikr, muhasabah, nafsAI, guidedPlans, settings
}
