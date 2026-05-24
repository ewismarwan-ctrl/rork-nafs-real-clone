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
                    case .problemHook: OBAnimatedStoryView(vm: vm, icon: "iphone.gen3.radiowaves.left.and.right", black: "Your phone is making you", gold: "delay Salah", lines: ["One notification becomes a scroll.", "One scroll becomes another delay."], button: "Continue", floatingApps: true)
                    case .emotionalPain: OBAnimatedStoryView(vm: vm, icon: "clock.badge.exclamationmark", black: "One scroll becomes", gold: "another missed prayer", lines: ["Not because you don’t care.", "Because distractions are built to pull you back."], button: "I feel this")
                    case .solutionIntro: OBAnimatedStoryView(vm: vm, icon: "shield.lefthalf.filled", black: "Choose Salah", gold: "before scrolling", lines: ["Nafs protects the moment prayer begins.", "Pray first. Then continue your day."], button: "Show me how")
                    case .lockExplainer: OBLockExplainerView(vm: vm)
                    case .name: NameScreenView(vm: vm)
                    case .honestPersonalization: OBAnimatedStoryView(vm: vm, icon: "sparkles", black: "\(vm.displayName),", gold: "answer honestly", lines: ["No judgment. No shame.", "Just a setup that fits your real life."], button: "I'm ready")
                    case .ageRange: OBChoiceScreen(vm: vm, title: "What's your age range?", gold: "", options: OBData.ageRanges, selection: Bindable(vm).ageRange)
                    case .phoneHours: OBSliderScreen(vm: vm)
                    case .timeLoss: OBTimeLossView(vm: vm)
                    case .salahConsistency: OBChoiceScreen(vm: vm, title: "How often do you pray", gold: "on time?", options: OBData.salahConsistency, selection: Bindable(vm).salahConsistency)
                    case .salahRelationship: OBChoiceScreen(vm: vm, title: "Your relationship with", gold: "Salah", options: OBData.salahRelationship, selection: Bindable(vm).selectedSalahRelationship)
                    case .mainStruggle: OBMultiChoiceScreen(vm: vm, title: "What usually gets", gold: "in the way?", options: OBData.mainStruggles, selected: Bindable(vm).selectedStruggles)
                    case .deeperStruggle: OBChoiceScreen(vm: vm, title: "What feels deeper", gold: "than the habit?", options: OBData.deeperStruggles, selection: Bindable(vm).deeperStruggle)
                    case .goals: OBMultiChoiceScreen(vm: vm, title: "What are you", gold: "building?", options: OBData.goals, selected: Bindable(vm).selectedGoals)
                    case .identity: OBChoiceScreen(vm: vm, title: "Discipline means", gold: "for me…", options: OBData.identities, selection: Bindable(vm).disciplineIdentity)
                    case .reassurance: OBAnimatedStoryView(vm: vm, icon: "hand.raised.fill", black: "You're in the", gold: "right place", lines: ["Nafs is not about guilt.", "It's about removing friction when Salah calls."], button: "Continue")
                    case .hope: OBAnimatedStoryView(vm: vm, icon: "sunrise.fill", black: "You can take", gold: "your time back", lines: ["Less useless scrolling.", "More prayer on time. More control."], button: "Continue")
                    case .testimonials: OBTestimonialsView(vm: vm)
                    case .howItWorks: OBHowItWorksView(vm: vm)
                    case .appPreviewSelection: OBAppSelectionView(vm: vm)
                    case .appsLock: OBAnimatedStoryView(vm: vm, icon: "lock.fill", black: "Apps lock", gold: "during Salah", lines: ["At prayer time, your selected distractions are shielded automatically."], button: "Continue")
                    case .pray: OBAnimatedStoryView(vm: vm, icon: "figure.mind.and.body", black: "Step away", gold: "and pray", lines: ["No feed. No pressure.", "Just the space to answer the adhan."], button: "Continue")
                    case .tapPrayed: OBAnimatedStoryView(vm: vm, icon: "checkmark.circle.fill", black: "Tap", gold: "I prayed", lines: ["After Salah, confirm completion.", "Nafs tracks consistency locally."], button: "Continue")
                    case .appsUnlock: OBUnlockDemoView(vm: vm)
                    case .companionIntro: OBCatIntroView(vm: vm)
                    case .catName: OBCatNameView(vm: vm)
                    case .catProgression: OBCatProgressionView(vm: vm)
                    case .commitmentLevel: OBChoiceScreen(vm: vm, title: "Choose your", gold: "commitment", options: OBData.commitments, selection: Bindable(vm).commitmentLevel)
                    case .positiveReinforcement: OBAnimatedStoryView(vm: vm, icon: "leaf.fill", black: "Small wins become", gold: "discipline", lines: ["Every on-time prayer is a vote for who you're becoming."], button: "Continue")
                    case .covenant: OBCovenantView(vm: vm)
                    case .attribution: OBAttributionView(vm: vm)
                    case .appSelection: OBAppSelectionView(vm: vm)
                    case .prayerLockSetup: OBAnimatedStoryView(vm: vm, icon: "timer", black: "Prayer Lock", gold: "setup", lines: ["We'll prepare your app blocking windows around your prayer times."], button: "Continue")
                    case .screenTimePermission: OBScreenTimePermissionView(vm: vm)
                    case .notificationPermission: OBNotificationPermissionView(vm: vm)
                    case .location: LocationScreenView(vm: vm)
                    case .roadmap: OBRoadmapView(vm: vm)
                    case .finalReady: OBAnimatedStoryView(vm: vm, icon: "checkmark.shield.fill", black: "Your Prayer Lock", gold: "is ready", lines: ["You're one step from automatic Salah protection."], button: "Continue")
                    case .paywall: PaywallScreenView(vm: vm, storeViewModel: storeViewModel)
                    case .trialReassurance: OBTrialReassuranceView(vm: vm)
                    case .completion: OBCompletionView(vm: vm)
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
                vm.persistOnboardingData()
                hasCompletedOnboarding = true
            }
        }
    }
}
