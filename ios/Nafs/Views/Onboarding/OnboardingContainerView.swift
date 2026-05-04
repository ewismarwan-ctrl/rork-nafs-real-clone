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
                    case .problem: OBProblemView(vm: vm)
                    case .ahaMoment: OBAhaView(vm: vm)
                    case .distractionPick: OBDistractionPickView(vm: vm)
                    case .reflection: OBReflectionView(vm: vm)
                    case .reframe: OBReframeView(vm: vm)
                    case .solution: OBSolutionView(vm: vm)
                    case .microCommitment: OBMicroCommitmentView(vm: vm)
                    case .automation: OBAutomationView(vm: vm)
                    case .liveDemo: OBLiveDemoView(vm: vm)
                    case .reward: OBRewardView(vm: vm)
                    case .progressBuild: OBProgressView(vm: vm)
                    case .identityShift: OBIdentityShiftView(vm: vm)
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
