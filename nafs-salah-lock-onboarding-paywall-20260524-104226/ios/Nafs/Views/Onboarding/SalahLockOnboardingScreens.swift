import SwiftUI
import FamilyControls

struct SalahPainHookView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 34) {
                SalahAppCloud(locked: false)
                    .frame(height: 230)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.92)

                VStack(spacing: 14) {
                    SalahTitle("Your phone is making you delay Salah.")
                    SalahBody("The scroll is designed to win your attention before prayer does.")
                }
            }
            .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) { appeared = true } }
        }
    }
}

struct SalahSolutionIntroView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 28) {
                CrescentStarMark(size: 92, color: NafsTheme.gold)
                    .shadow(color: NafsTheme.gold.opacity(0.45), radius: 24)

                VStack(spacing: 14) {
                    SalahTitle("Nafs helps you choose Salah before scrolling.")
                    SalahBody("During prayer times, distracting apps lock until you pray.")
                }

                SalahPremiumCard(icon: "lock.shield.fill", title: "Prayer Lock", text: "A calm barrier between you and the apps that pull you away.")
            }
        }
    }
}

struct SalahLockAnimationView: View {
    let vm: OnboardingViewModel
    @State private var step = 0

    private var message: String {
        switch step {
        case 0: return "Distractions appear."
        case 1: return "Prayer time begins."
        case 2: return "Nafs locks the noise."
        default: return "Once you pray, your apps unlock."
        }
    }

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: step >= 3) {
            VStack(spacing: 30) {
                ZStack {
                    SalahAppCloud(locked: step >= 2)
                        .opacity(step == 0 ? 0.72 : 1)
                        .blur(radius: step >= 2 ? 0 : 1.5)

                    if step >= 1 {
                        Circle()
                            .strokeBorder(NafsTheme.gold.opacity(0.28), lineWidth: 1)
                            .frame(width: 190, height: 190)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if step >= 2 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(NafsTheme.gold)
                            .frame(width: 92, height: 92)
                            .background(Circle().fill(Color.black.opacity(0.86)))
                            .overlay(Circle().strokeBorder(NafsTheme.gold.opacity(0.45), lineWidth: 1))
                            .shadow(color: NafsTheme.gold.opacity(0.35), radius: 28)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 280)

                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 33, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                    SalahBody("Your apps stay blocked until you come back to what matters.")
                        .opacity(step >= 3 ? 1 : 0)
                }
            }
            .onAppear { runAnimation() }
        }
    }

    private func runAnimation() {
        Task {
            for value in 1...3 {
                try? await Task.sleep(for: .milliseconds(700))
                await MainActor.run {
                    withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) { step = value }
                }
            }
        }
    }
}

struct SalahHonestyIntroView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 22) {
                SalahTitle("\(vm.displayName), answer honestly.")
                SalahBody("Your answers personalize the discipline plan Nafs builds around your Salah.")
                SalahPremiumCard(icon: "checkmark.seal.fill", title: "No judgment.", text: "Just clarity, structure, and a stronger barrier against distraction.")
            }
        }
    }
}

struct SalahPhoneHoursView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 30) {
                SalahTitle("How many hours are you on your phone daily?")
                Text("\(Int(vm.dailyPhoneHours)) hours")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                Slider(value: Bindable(vm).dailyPhoneHours, in: 1...10, step: 1)
                    .tint(NafsTheme.gold)
                HStack {
                    Text("1").foregroundStyle(NafsTheme.subtleText)
                    Spacer()
                    Text("10").foregroundStyle(NafsTheme.subtleText)
                }
                .font(.system(.caption, weight: .semibold))
            }
        }
    }
}

struct SalahOnTimeView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 30) {
                SalahTitle("How often do you pray on time each week?")
                Text("\(Int(vm.onTimePrayersPerWeek))/7 days")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                Slider(value: Bindable(vm).onTimePrayersPerWeek, in: 0...7, step: 1)
                    .tint(NafsTheme.gold)
                    .onChange(of: vm.onTimePrayersPerWeek) { _, _ in vm.updateCatProgress() }
                HStack {
                    Text("Never").foregroundStyle(NafsTheme.subtleText)
                    Spacer()
                    Text("Consistent").foregroundStyle(NafsTheme.subtleText)
                }
                .font(.system(.caption, weight: .semibold))
            }
        }
    }
}

struct SalahObstacleView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            SalahMultiSelect(title: "What gets in the way of Salah?", options: OnboardingOptions.salahObstacles, selected: vm.selectedSalahObstacles) {
                vm.toggleSalahObstacle($0)
            }
        }
    }
}

struct SalahGoalsView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            SalahMultiSelect(title: "What do you want to achieve?", options: OnboardingOptions.salahGoals, selected: vm.selectedSalahGoals) {
                vm.toggleSalahGoal($0)
            }
        }
    }
}

struct SalahConsequenceView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 22) {
                SalahTitle("At this rate, you may spend years of your life on your phone.")
                Text("\(vm.projectedPhoneYears) years")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                SalahBody("That is time, attention, and prayer focus you can still protect.")
            }
        }
    }
}

struct SalahHopeView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 22) {
                SalahTitle("But you can take that time back.")
                SalahBody("Nafs helps you protect Salah first, then return to your phone with intention.")
                SalahPremiumCard(icon: "moon.stars.fill", title: "Protect the moment.", text: "When Salah enters, scrolling exits.")
            }
        }
    }
}

struct SalahCatCompanionView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 24) {
                NafsCatView(level: vm.catLevel, progress: vm.catStreakProgress)
                    .frame(height: 190)
                SalahTitle("Meet your Salah companion.")
                SalahBody("A calm companion that grows as you pray consistently. Premium, quiet, and built around discipline.")
            }
            .onAppear { vm.updateCatProgress() }
        }
    }
}

struct SalahCatNameView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            VStack(spacing: 24) {
                NafsCatView(level: vm.catLevel, progress: vm.catStreakProgress)
                    .frame(height: 170)
                SalahTitle("Name your companion.")
                TextField("Sabr", text: Bindable(vm).catName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                    .padding(18)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
            }
        }
    }
}

struct SalahCommitmentView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            VStack(spacing: 20) {
                SalahTitle("How committed are you to protecting your Salah?")
                ForEach(OnboardingOptions.commitmentLevels) { option in
                    SalahOptionRow(option: option, isSelected: vm.selectedCommitment == option.id) {
                        vm.selectedCommitment = option.id
                    }
                }
            }
        }
    }
}

struct SalahSignatureView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            VStack(alignment: .leading, spacing: 20) {
                SalahTitle("From today forward, I choose to:")
                VStack(alignment: .leading, spacing: 12) {
                    bullet("protect my Salah from distraction")
                    bullet("pray before scrolling")
                    bullet("reduce useless screen time")
                    bullet("build discipline through worship")
                }
                TextField("Sign your name", text: Bindable(vm).signatureText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .padding(18)
                    .frame(height: 88)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.gold.opacity(0.35), lineWidth: 1))
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•").foregroundStyle(NafsTheme.gold)
            Text(text).foregroundStyle(NafsTheme.text)
        }
        .font(.system(size: 17, weight: .semibold))
    }
}

struct SalahScreenTimePermissionView: View {
    let vm: OnboardingViewModel
    @State private var service = ScreenTimeService()
    @State private var isConnecting = false

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true, continueTitle: service.isAuthorized ? "Continue" : "Skip for now") {
            VStack(spacing: 24) {
                Image(systemName: "hourglass.badge.lock")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                SalahTitle("Connect Nafs to Screen Time")
                SalahBody("We use this to block distracting apps during Salah.")
                NafsButton(title: service.isAuthorized ? "Connected" : "Connect", isLoading: isConnecting) {
                    Task {
                        isConnecting = true
                        await service.requestAuthorization()
                        isConnecting = false
                    }
                }
            }
        }
    }
}

struct SalahNotificationPermissionView: View {
    let vm: OnboardingViewModel
    @State private var requested = false

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true, continueTitle: requested ? "Continue" : "Skip for now") {
            VStack(spacing: 24) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                SalahTitle("Allow Nafs to send prayer lock reminders")
                SalahBody("We’ll remind you when your apps lock for Salah.")
                NafsButton(title: requested ? "Allowed" : "Allow") {
                    NotificationService.shared.requestPermission()
                    requested = true
                }
            }
        }
    }
}

struct SalahAttributionView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: vm.canProceed) {
            VStack(spacing: 18) {
                SalahTitle("How did you hear about Nafs?")
                ForEach(OnboardingOptions.attributionSources) { option in
                    SalahOptionRow(option: option, isSelected: vm.sourcePlatform == option.id) {
                        vm.sourcePlatform = option.id
                    }
                }
                if vm.sourcePlatform == "influencer" {
                    TextField("Creator or code", text: Bindable(vm).sourceDetail)
                        .padding(14)
                        .background(NafsTheme.card)
                        .clipShape(.rect(cornerRadius: 14))
                        .foregroundStyle(NafsTheme.text)
                }
            }
        }
    }
}

struct SalahSocialProofView: View {
    let vm: OnboardingViewModel

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(spacing: 18) {
                SalahTitle("Nafs was built for Muslims like you.")
                SalahReviewCard(text: "I needed something that protected Salah without feeling noisy.")
                SalahReviewCard(text: "The idea is simple: when prayer enters, distractions leave.")
                SalahPremiumCard(icon: "person.3.fill", title: "Built with Muslim discipline in mind.", text: "Real reviews and live stats can connect here once available.")
            }
        }
    }
}

struct SalahRoadmapView: View {
    let vm: OnboardingViewModel
    private let days = [
        "Notice your distractions",
        "Feel the resistance",
        "Pray before scrolling",
        "Build momentum",
        "Strengthen discipline",
        "See progress",
        "Prove consistency is possible"
    ]

    var body: some View {
        SalahOnboardingShell(vm: vm, canContinue: true) {
            VStack(alignment: .leading, spacing: 18) {
                SalahTitle("Your next 7 days.")
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    HStack(spacing: 12) {
                        Text("Day \(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(NafsTheme.gold)
                            .clipShape(.capsule)
                        Text(day)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                    }
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 14))
                }
            }
        }
    }
}

private struct SalahOnboardingShell<Content: View>: View {
    let vm: OnboardingViewModel
    let canContinue: Bool
    var continueTitle: String = "Continue"
    let content: () -> Content
    @State private var bounce = false

    init(
        vm: OnboardingViewModel,
        canContinue: Bool,
        continueTitle: String = "Continue",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.vm = vm
        self.canContinue = canContinue
        self.continueTitle = continueTitle
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)
                    content()
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }

            NafsButton(title: continueTitle, isEnabled: canContinue) {
                guard canContinue else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                vm.persistAnswers()
                vm.goNext()
            }
            .scaleEffect(bounce ? 1.015 : 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { bounce = true }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct SalahTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(NafsTheme.text)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .minimumScaleFactor(0.75)
    }
}

private struct SalahBody: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(NafsTheme.subtleText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

private struct SalahPremiumCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
                .frame(width: 46, height: 46)
                .background(Circle().fill(NafsTheme.gold.opacity(0.12)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundStyle(NafsTheme.text)
                Text(text).font(.system(size: 13, weight: .medium)).foregroundStyle(NafsTheme.subtleText)
            }
            Spacer()
        }
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(NafsTheme.cardBorder, lineWidth: 1))
    }
}

private struct SalahMultiSelect: View {
    let title: String
    let options: [SelectionOption]
    let selected: Set<String>
    let toggle: (String) -> Void

    var body: some View {
        VStack(spacing: 18) {
            SalahTitle(title)
            ForEach(options) { option in
                SalahOptionRow(option: option, isSelected: selected.contains(option.id)) {
                    toggle(option.id)
                }
            }
        }
    }
}

private struct SalahOptionRow: View {
    let option: SelectionOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .foregroundStyle(isSelected ? .black : NafsTheme.gold)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(isSelected ? NafsTheme.gold : NafsTheme.gold.opacity(0.1)))
                Text(option.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.subtleText)
            }
            .padding(15)
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(isSelected ? NafsTheme.gold.opacity(0.55) : NafsTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct SalahAppCloud: View {
    let locked: Bool
    private let apps: [(String, String, Color)] = [
        ("Instagram", "camera.fill", Color(hex: "F15BB5")),
        ("TikTok", "music.note", Color(hex: "7EF9FF")),
        ("YouTube", "play.rectangle.fill", Color(hex: "FF3B30")),
        ("Snapchat", "bolt.fill", Color(hex: "FFE66D"))
    ]

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(apps.enumerated()), id: \.offset) { index, app in
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.055))
                            .frame(width: 66, height: 66)
                            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(app.2.opacity(0.35), lineWidth: 1))
                        Image(systemName: locked ? "lock.fill" : app.1)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(locked ? NafsTheme.gold : app.2)
                    }
                    Text(app.0)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(NafsTheme.subtleText)
                }
                .offset(y: index.isMultiple(of: 2) ? -18 : 18)
                .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(index) * 0.08), value: locked)
            }
        }
    }
}

private struct NafsCatView: View {
    let level: Int
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [NafsTheme.gold.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 230, height: 230)
                .blur(radius: 12)
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(hex: "171717")).frame(width: 112, height: 112)
                    HStack(spacing: 30) {
                        Circle().fill(NafsTheme.gold.opacity(0.85)).frame(width: 9, height: 9)
                        Circle().fill(NafsTheme.gold.opacity(0.85)).frame(width: 9, height: 9)
                    }
                    .offset(y: level <= 2 ? 4 : -2)
                    Capsule()
                        .fill(NafsTheme.gold.opacity(level <= 2 ? 0.28 : 0.65))
                        .frame(width: level <= 2 ? 22 : 34, height: 3)
                        .offset(y: 24)
                    Triangle()
                        .fill(Color(hex: "171717"))
                        .frame(width: 34, height: 30)
                        .offset(x: -38, y: -48)
                    Triangle()
                        .fill(Color(hex: "171717"))
                        .frame(width: 34, height: 30)
                        .offset(x: 38, y: -48)
                }
                Text(level <= 2 ? "Distracted" : level < 6 ? "Calmer" : "Peaceful")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
                ProgressView(value: progress)
                    .tint(NafsTheme.gold)
                    .frame(width: 150)
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SalahReviewCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(NafsTheme.gold)
                }
            }
            Text("\"\(text)\"")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
    }
}
