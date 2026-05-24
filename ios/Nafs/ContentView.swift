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

                Tab(NafsStrings.tabFocus.value(for: languageManager.current), systemImage: "shield.checkered", value: .focus) {
                    FocusView(viewModel: viewModel, storeViewModel: storeViewModel)
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
                viewModel.premiumGateFeature = languageManager.isArabic ? "التركيز" : "Focus"
                viewModel.premiumGateBenefit = languageManager.isArabic ? "افتح ميزة التركيز لحجب المشتتات أثناء الصلاة والانضباط مع نفس بريميوم." : "Unlock Focus to block distractions with Prayer Mode and Discipline Mode in Nafs Premium."
                viewModel.showPremiumGate = true
            } else {
                previousTab = newValue
            }
        }
    }
}

enum AppTab: Hashable {
    case home, focus, more
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
                Section(NafsStrings.features.localized) {
                    moreRow(icon: "book.fill", title: NafsStrings.tabQuran.localized, subtitle: "Read and listen to Quran", dest: .quran, premium: false)
                    moreRow(icon: "hands.sparkles.fill", title: NafsStrings.dhikr.localized, subtitle: lang.isArabic ? "عدّاد التسبيح للذكر اليومي" : "Tasbih counter for daily dhikr", dest: .dhikr, premium: false)
                    moreRow(icon: "brain.head.profile", title: NafsStrings.tabNafsAI.localized, subtitle: "Ask Islamic questions", dest: .nafsAI, premium: true)
                    moreRow(icon: "map.fill", title: NafsStrings.guidedPlans.localized, subtitle: lang.isArabic ? "خطط للنمو الروحي" : "Structured spiritual growth", dest: .guidedPlans, premium: true)
                    moreRow(icon: "rectangle.stack.badge.plus", title: "Widgets", subtitle: "Home and Lock Screen streak widgets", dest: .widgets, premium: false)
                    moreRow(icon: "gearshape.fill", title: NafsStrings.settings.localized, subtitle: lang.isArabic ? "مواقيت الصلاة، الإشعارات" : "Prayer times, notifications", dest: .settings, premium: false)
                    moreRow(icon: "crown.fill", title: "Subscription", subtitle: "Manage Nafs Premium", dest: .subscription, premium: false)
                    moreRow(icon: "questionmark.circle.fill", title: "Support", subtitle: "Help, feedback, and contact", dest: .support, premium: false)
                }

                Section(NafsStrings.growth.localized) {
                    moreRow(icon: "checkmark.seal.fill", title: NafsStrings.logHabits.localized, subtitle: lang.isArabic ? "سجّل عباداتك اليومية" : "Log your daily worship habits", dest: .habits, premium: true)
                    moreRow(icon: "moon.stars", title: NafsStrings.muhasabah.localized, subtitle: lang.isArabic ? "محاسبة النفس اليومية" : "Daily self reflection", dest: .muhasabah, premium: true)
                    moreRow(icon: "paperplane.fill", title: NafsStrings.sendDua.localized, subtitle: lang.isArabic ? "شارك أدعية جميلة" : "Share beautiful du'as", dest: .sendDua, premium: true)
                    moreRow(icon: "location.north.fill", title: NafsStrings.qiblaFinder.localized, subtitle: lang.isArabic ? "اعثر على اتجاه مكة" : "Find the direction of Mecca", dest: .qibla, premium: false)
                    moreRow(icon: "leaf.fill", title: NafsStrings.gardenOfDeeds.localized, subtitle: lang.isArabic ? "شاهد حديقتك تنمو" : "Watch your garden grow", dest: .garden, premium: true)
                    moreRow(icon: "chart.bar.fill", title: NafsStrings.progress.localized, subtitle: lang.isArabic ? "الإحصائيات والسلاسل" : "Stats & streaks", dest: .progress, premium: true)
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
                case .nafsAI:
                    NafsAIView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .widgets:
                    WidgetInfoView()
                case .subscription:
                    SubscriptionManagementView(storeViewModel: storeViewModel)
                case .support:
                    SupportInfoView()
                case .dhikr:
                    DhikrView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .muhasabah:
                    MuhasabahView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .guidedPlans:
                    GuidedPlansView(appViewModel: viewModel, storeViewModel: storeViewModel)
                case .sendDua:
                    SendDuaView(storeViewModel: storeViewModel, isPremium: viewModel.isPremium)
                case .habits:
                    HabitLoggingView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .qibla:
                    QiblaFinderView(storeViewModel: storeViewModel, isPremium: true)
                case .garden:
                    GardenOfDeedsView(viewModel: viewModel, storeViewModel: storeViewModel)
                case .progress:
                    ProgressStatsView(viewModel: viewModel, storeViewModel: storeViewModel)
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
    case quran, dhikr, nafsAI, guidedPlans, widgets, settings, subscription, support, habits, muhasabah, sendDua, qibla, garden, progress
}

private struct WidgetInfoView: View {
    var body: some View {
        List {
            Section("Widgets") {
                Text("Add Nafs widgets from your iPhone Home Screen or Lock Screen to see your prayer streak and today’s progress instantly.")
                    .foregroundStyle(NafsTheme.text)
            }
        }
        .navigationTitle("Widgets")
        .scrollContentBackground(.hidden)
        .background(NafsTheme.background)
    }
}

private struct SubscriptionManagementView: View {
    let storeViewModel: StoreViewModel
    var body: some View {
        UpgradePaywallSheet(storeViewModel: storeViewModel, feature: "Nafs Premium", benefit: "Manage or start your premium Prayer Lock plan.", onDismiss: {}, onSuccess: {})
            .navigationTitle("Subscription")
    }
}

private struct SupportInfoView: View {
    var body: some View {
        List {
            Section("Support") {
                Link("Privacy Policy", destination: URL(string: NafsConstants.privacyPolicyURL)!)
                Link("Terms of Use", destination: URL(string: NafsConstants.termsOfUseURL)!)
                Text("For help, feedback, or account questions, contact the Nafs support team through the App Store listing.")
                    .foregroundStyle(NafsTheme.text)
            }
        }
        .navigationTitle("Support")
        .scrollContentBackground(.hidden)
        .background(NafsTheme.background)
    }
}
