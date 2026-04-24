import SwiftUI

struct OnboardingContainerView: View {
    let storeViewModel: StoreViewModel
    let languageManager: LanguageManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var vm = OnboardingViewModel()
    @State private var hapticTrigger: Bool = false

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()
            IslamicPatternView(opacity: 0.04)

            VStack(spacing: 0) {
                if vm.showProgressBar {
                    HStack(spacing: 12) {
                        if vm.showBackButton {
                            NafsBackButton {
                                hapticTrigger.toggle()
                                vm.goBack()
                            }
                        }
                        NafsProgressBar(progress: vm.progress)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                Group {
                    switch vm.currentScreen {
                    case .splash: SplashScreenView(vm: vm)
                    case .languageSelection: LanguageSelectionView(languageManager: languageManager) { vm.goNext() }
                    case .hook: HookScreenView(vm: vm)
                    case .insight1: InsightScreen1View(vm: vm)
                    case .deenAreas: DeenAreasScreenView(vm: vm)
                    case .salahRelationship: SalahRelationshipScreenView(vm: vm)
                    case .insight2: InsightScreen2View(vm: vm)
                    case .quranRelationship: QuranRelationshipScreenView(vm: vm)
                    case .knowledgeAreas: KnowledgeAreasScreenView(vm: vm)
                    case .insight3: InsightScreen3View(vm: vm)
                    case .phoneEffect: PhoneEffectScreenView(vm: vm)
                    case .spiritualChallenge: SpiritualChallengeScreenView(vm: vm)
                    case .excitingFeatures: ExcitingFeaturesScreenView(vm: vm)
                    case .strictness: StrictnessScreenView(vm: vm)
                    case .name: NameScreenView(vm: vm)
                    case .location: LocationScreenView(vm: vm)
                    case .personalized: PersonalizedScreenView(vm: vm)
                    case .loading: LoadingScreenView(vm: vm)
                    case .score: ScoreScreenView(vm: vm)
                    case .ratingPrompt: RatingPromptScreenView(vm: vm)
                    case .paywall: PaywallScreenView(vm: vm, storeViewModel: storeViewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: vm.direction > 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: vm.direction > 0 ? .leading : .trailing).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.currentScreen)
                .gesture(vm.requiresAnswer ? DragGesture() : nil)
            }
        }
        .preferredColorScheme(.light)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onChange(of: vm.hasCompletedOnboarding) { _, newValue in
            if newValue {
                UserDefaults.standard.set(vm.userName, forKey: "nafs_userName")
                hasCompletedOnboarding = true
            }
        }
    }
}
