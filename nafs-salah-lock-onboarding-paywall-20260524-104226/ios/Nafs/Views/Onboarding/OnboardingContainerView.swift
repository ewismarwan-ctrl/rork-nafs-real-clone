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
                    case .painHook: SalahPainHookView(vm: vm)
                    case .solutionIntro: SalahSolutionIntroView(vm: vm)
                    case .lockAnimation: SalahLockAnimationView(vm: vm)
                    case .name: NameScreenView(vm: vm)
                    case .honestyIntro: SalahHonestyIntroView(vm: vm)
                    case .phoneHours: SalahPhoneHoursView(vm: vm)
                    case .salahOnTime: SalahOnTimeView(vm: vm)
                    case .salahObstacles: SalahObstacleView(vm: vm)
                    case .goals: SalahGoalsView(vm: vm)
                    case .consequence: SalahConsequenceView(vm: vm)
                    case .hope: SalahHopeView(vm: vm)
                    case .catCompanion: SalahCatCompanionView(vm: vm)
                    case .catName: SalahCatNameView(vm: vm)
                    case .commitment: SalahCommitmentView(vm: vm)
                    case .signatureCommitment: SalahSignatureView(vm: vm)
                    case .screenTimePermission: SalahScreenTimePermissionView(vm: vm)
                    case .notificationPermission: SalahNotificationPermissionView(vm: vm)
                    case .attribution: SalahAttributionView(vm: vm)
                    case .socialProof: SalahSocialProofView(vm: vm)
                    case .roadmap: SalahRoadmapView(vm: vm)
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
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onChange(of: vm.hasCompletedOnboarding) { _, newValue in
            if newValue {
                UserDefaults.standard.set(vm.userName, forKey: "nafs_userName")
                hasCompletedOnboarding = true
            }
        }
    }
}
