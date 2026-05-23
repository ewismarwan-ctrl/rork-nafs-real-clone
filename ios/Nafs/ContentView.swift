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

    private var userName: String {
        UserDefaults.standard.string(forKey: "nafs_userName") ?? "Friend"
    }

    private func handleIncomingURL(_ url: URL) {
        // Reserved for future deep link handling.
        _ = url
    }

    var body: some View {
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

                Tab("Earn", systemImage: "plus.circle.fill", value: .earn) {
                    EarnScreenView(viewModel: viewModel, storeViewModel: storeViewModel)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }

                Tab("Lock", systemImage: "shield.checkered", value: .focus) {
                    FocusView(viewModel: viewModel, storeViewModel: storeViewModel)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }

                Tab("Progress", systemImage: "chart.bar.fill", value: .progress) {
                    ProgressStatsView(viewModel: viewModel, storeViewModel: storeViewModel)
                        .safeAreaPadding(.bottom, isMiniBarVisible ? miniBarHeight : 0)
                }

                Tab(NafsStrings.tabMore.value(for: languageManager.current), systemImage: "ellipsis.circle.fill", value: .more) {
                    MoreView(viewModel: viewModel, storeViewModel: storeViewModel)
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
            if newValue == .focus && !viewModel.isPremium {
                navigationState.selectedTab = previousTab == .focus ? .home : previousTab
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
    case home, earn, focus, progress, more
}

struct MoreView: View {
    let viewModel: AppViewModel
    let storeViewModel: StoreViewModel
    @State private var showPremiumGate: Bool = false
    @State private var gateFeature: String = ""
    @State private var gateBenefit: String = ""
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        NavigationStack {
            List {
                Section("Worship Tools") {
                    moreRow(icon: "book.fill", title: "Quran", subtitle: "Read and listen with intention", dest: .quran, premium: false)
                    moreRow(icon: "hands.sparkles.fill", title: NafsStrings.dhikr.localized, subtitle: "Full dhikr counter", dest: .dhikr, premium: false)
                    moreRow(icon: "moon.stars", title: NafsStrings.muhasabah.localized, subtitle: "Reflect and reset", dest: .muhasabah, premium: false)
                    moreRow(icon: "speaker.wave.2.fill", title: "Reciters", subtitle: "Quran audio and recitation", dest: .quran, premium: false)
                }

                Section("Settings") {
                    moreRow(icon: "lock.shield.fill", title: "App Blocking", subtitle: "Choose apps and lock rules", dest: .appBlocker, premium: true)
                    moreRow(icon: "clock.fill", title: "Prayer Settings", subtitle: "Times, method, and offsets", dest: .settings, premium: false)
                    moreRow(icon: "bell.fill", title: "Notifications", subtitle: "Prayer and discipline reminders", dest: .settings, premium: false)
                    moreRow(icon: "rectangle.stack.fill", title: "Widgets", subtitle: "Lock Screen and Home Screen", dest: .settings, premium: false)
                }

                Section("Account") {
                    moreRow(icon: "crown.fill", title: "Premium", subtitle: "Subscription and restore purchases", dest: .premium, premium: false)
                    moreRow(icon: "person.crop.circle.fill", title: "Account", subtitle: "Name and preferences", dest: .settings, premium: false)
                }

                Section("Support") {
                    moreRow(icon: "questionmark.circle.fill", title: "Help", subtitle: "Get support", dest: .settings, premium: false)
                    moreRow(icon: "bubble.left.and.bubble.right.fill", title: "Feedback", subtitle: "Tell us what to improve", dest: .settings, premium: false)
                    moreRow(icon: "info.circle.fill", title: "About", subtitle: "Nafs discipline OS", dest: .settings, premium: false)
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
                    QuranListView(appViewModel: viewModel, storeViewModel: storeViewModel, audioPlayer: QuranAudioPlayer())
                case .dhikr:
                    DhikrView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .muhasabah:
                    MuhasabahView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .guidedPlans:
                    GuidedPlansView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .sendDua:
                    SendDuaView(storeViewModel: storeViewModel, isPremium: viewModel.isPremium)
                case .qibla:
                    QiblaFinderView(storeViewModel: storeViewModel, isPremium: true)
                case .garden:
                    GardenOfDeedsView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .progress:
                    ProgressStatsView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .settings:
                    SettingsView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .disciplineCircle:
                    DisciplineCircleView(viewModel: viewModel)
                case .challenges:
                    WeeklyChallengesView(viewModel: viewModel)
                case .appBlocker:
                    AppBlockerView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .premium:
                    UpgradePaywallSheet(storeViewModel: storeViewModel, feature: "Nafs Premium", benefit: "Unlock advanced blocking and discipline tools.", onDismiss: {}, onSuccess: {})
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
}

enum MoreDestination: Hashable {
    case quran, dhikr, muhasabah, guidedPlans, sendDua, qibla, garden, progress, settings, disciplineCircle, challenges, appBlocker, premium
}
