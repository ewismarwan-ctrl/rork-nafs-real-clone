import SwiftUI

// MARK: - Shared Building Blocks

struct OnboardingHeadline: View {
    let blackText: String
    let goldText: String
    let goldFirst: Bool

    init(black: String, gold: String, goldFirst: Bool = false) {
        self.blackText = black
        self.goldText = gold
        self.goldFirst = goldFirst
    }

    var body: some View {
        VStack(spacing: 6) {
            if goldFirst {
                if !goldText.isEmpty {
                    Text(goldText)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.gold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !blackText.isEmpty {
                    Text(blackText)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                if !blackText.isEmpty {
                    Text(blackText)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !goldText.isEmpty {
                    Text(goldText)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.gold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct OnboardingSubtext: View {
    let lines: [String]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(NafsTheme.text.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lineSpacing(2)
    }
}

private struct OnboardingScaffold<Visual: View, Bottom: View>: View {
    let blackText: String
    let goldText: String
    var goldFirst: Bool = false
    let subtextLines: [String]
    @ViewBuilder let visual: () -> Visual
    @ViewBuilder let bottom: () -> Bottom

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    Spacer().frame(height: 24)

                    visual()
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    VStack(spacing: 18) {
                        OnboardingHeadline(black: blackText, gold: goldText, goldFirst: goldFirst)
                        OnboardingSubtext(lines: subtextLines)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
            }

            bottom()
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Visual Icons

private struct GoldGlowIcon: View {
    let systemName: String
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [NafsTheme.gold.opacity(0.22), NafsTheme.gold.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 1.1
                    )
                )
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: 14)

            Circle()
                .fill(NafsTheme.gold.opacity(0.10))
                .frame(width: size * 1.4, height: size * 1.4)

            Circle()
                .strokeBorder(NafsTheme.gold.opacity(0.35), lineWidth: 1)
                .frame(width: size * 1.4, height: size * 1.4)

            Image(systemName: systemName)
                .font(.system(size: size * 0.5, weight: .light))
                .foregroundStyle(NafsTheme.goldGradient)
                .shadow(color: NafsTheme.goldShadow, radius: 12, y: 4)
        }
        .frame(height: size * 2.2)
    }
}

// MARK: - Screen 1 — Problem

struct OBProblemView: View {
    let vm: OnboardingViewModel
    @State private var pulse = false

    var body: some View {
        OnboardingScaffold(
            blackText: "You don't delay",
            goldText: "Salah",
            subtextLines: [
                "You delay it without realizing.",
                "Just a few minutes turns into an hour."
            ],
            visual: {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [NafsTheme.gold.opacity(0.18), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 20)
                        .scaleEffect(pulse ? 1.06 : 0.94)

                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: "1A1A1F"), Color(hex: "0A0A0E")],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 130, height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1)
                        )
                        .overlay(
                            VStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(NafsTheme.gold.opacity(0.15 + Double(i) * 0.05))
                                        .frame(height: 18)
                                }
                            }
                            .padding(14)
                        )
                        .shadow(color: NafsTheme.gold.opacity(0.3), radius: 24, y: 8)
                }
                .frame(height: 240)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
            },
            bottom: {
                NafsButton(title: "Continue") { vm.goNext() }
            }
        )
    }
}

// MARK: - Screen 2 — Aha Moment

struct OBAhaView: View {
    let vm: OnboardingViewModel

    var body: some View {
        OnboardingScaffold(
            blackText: "It's not about",
            goldText: "motivation",
            subtextLines: [
                "You already want to pray.",
                "Distraction is the real problem."
            ],
            visual: { GoldGlowIcon(systemName: "brain.head.profile") },
            bottom: { NafsButton(title: "Makes sense") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 3 — Reflection (Interactive)

struct OBDistractionPickView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false

    private let options: [(id: String, label: String, icon: String)] = [
        ("tiktok", "TikTok", "music.note"),
        ("instagram", "Instagram", "camera"),
        ("youtube", "YouTube", "play.rectangle.fill"),
        ("other", "Other", "ellipsis")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 24)

                    VStack(spacing: 18) {
                        OnboardingHeadline(black: "What distracts you", gold: "the most?")
                        OnboardingSubtext(lines: ["Be honest. This is what we'll fix."])
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    VStack(spacing: 12) {
                        ForEach(options, id: \.id) { opt in
                            DistractionRow(
                                label: opt.label,
                                icon: opt.icon,
                                isSelected: vm.selectedDistraction == opt.id
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    vm.selectDistraction(opt.id)
                                }
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 28)
            }

            NafsButton(title: "Continue", isEnabled: !vm.selectedDistraction.isEmpty) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

private struct DistractionRow: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? NafsTheme.gold : NafsTheme.text.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isSelected ? NafsTheme.gold.opacity(0.12) : NafsTheme.card)
                    )

                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.text.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(NafsTheme.gold).frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(NafsTheme.card.opacity(isSelected ? 0.6 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Screen 4 — Reflection back

struct OBReflectionView: View {
    let vm: OnboardingViewModel

    private var appLabel: String {
        switch vm.selectedDistraction {
        case "tiktok": return "TikTok"
        case "instagram": return "Instagram"
        case "youtube": return "YouTube"
        case "other": return "Your distractions"
        default: return "Your distractions"
        }
    }

    private var appIcon: String {
        switch vm.selectedDistraction {
        case "tiktok": return "music.note"
        case "instagram": return "camera"
        case "youtube": return "play.rectangle.fill"
        default: return "ellipsis.circle"
        }
    }

    var body: some View {
        OnboardingScaffold(
            blackText: "You said",
            goldText: appLabel,
            subtextLines: [
                "This is what pulls you away from Salah.",
                "We'll take control of it."
            ],
            visual: {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.08))
                        .frame(width: 180, height: 180)
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(NafsTheme.goldGradient)
                        .frame(width: 96, height: 96)
                        .overlay(
                            Image(systemName: appIcon)
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: NafsTheme.goldShadow, radius: 18, y: 8)
                }
                .frame(height: 200)
            },
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 5 — Reframe

struct OBReframeView: View {
    let vm: OnboardingViewModel
    @State private var rotate = false

    var body: some View {
        OnboardingScaffold(
            blackText: "",
            goldText: "It's not your fault",
            goldFirst: true,
            subtextLines: [
                "Your phone is designed to keep you scrolling.",
                "That's why it's hard to stop."
            ],
            visual: {
                ZStack {
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                        .frame(width: 220, height: 220)
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [3, 5]))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(NafsTheme.goldGradient)
                }
                .frame(height: 220)
                .onAppear {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotate = true
                    }
                }
            },
            bottom: { NafsButton(title: "I get it") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 6 — Solution

struct OBSolutionView: View {
    let vm: OnboardingViewModel

    var body: some View {
        OnboardingScaffold(
            blackText: "So we built a",
            goldText: "system",
            subtextLines: [
                "Nafs removes distractions at the exact moment",
                "you need to pray."
            ],
            visual: { GoldGlowIcon(systemName: "shield.lefthalf.filled") },
            bottom: { NafsButton(title: "Show me") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 7 — Micro-Commitment

struct OBMicroCommitmentView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false

    private let options: [(id: String, label: String, icon: String)] = [
        ("tiktok", "TikTok", "music.note"),
        ("instagram", "Instagram", "camera"),
        ("youtube", "YouTube", "play.rectangle.fill"),
        ("twitter", "X / Twitter", "bird"),
        ("snapchat", "Snapchat", "bolt.fill"),
        ("other", "Other apps", "ellipsis")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 16)

                    VStack(spacing: 16) {
                        OnboardingHeadline(black: "Choose your", gold: "distractions")
                        OnboardingSubtext(lines: ["We'll block these at prayer time."])
                    }

                    VStack(spacing: 10) {
                        ForEach(options, id: \.id) { opt in
                            DistractionToggleRow(
                                label: opt.label,
                                icon: opt.icon,
                                isOn: Binding(
                                    get: { vm.blockedDistractions.contains(opt.id) },
                                    set: { _ in vm.toggleBlockedDistraction(opt.id) }
                                )
                            )
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
            }

            NafsButton(title: "Lock these", isEnabled: !vm.blockedDistractions.isEmpty) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

private struct DistractionToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? NafsTheme.gold : NafsTheme.text.opacity(0.6))
                .frame(width: 36, height: 36)
                .background(Circle().fill(isOn ? NafsTheme.gold.opacity(0.12) : NafsTheme.card))

            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(NafsTheme.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(NafsTheme.card.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isOn ? NafsTheme.gold.opacity(0.4) : NafsTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 14))
    }
}

// MARK: - Screen 8 — Automation

struct OBAutomationView: View {
    let vm: OnboardingViewModel
    @State private var spin = false

    var body: some View {
        OnboardingScaffold(
            blackText: "No reminders.",
            goldText: "No willpower.",
            subtextLines: [
                "It works automatically.",
                "You don't have to think about it."
            ],
            visual: {
                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.10))
                        .frame(width: 200, height: 200)
                        .blur(radius: 6)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 96, weight: .light))
                        .foregroundStyle(NafsTheme.goldGradient)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .shadow(color: NafsTheme.goldShadow, radius: 14, y: 6)
                }
                .frame(height: 200)
                .onAppear {
                    withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                        spin = true
                    }
                }
            },
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 9 — Live Demo (phone mockup)

struct OBLiveDemoView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false
    @State private var lockPulse = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 12)

                    Text("When it's time…")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)

                    PhoneMockupView(lockPulse: lockPulse)
                        .frame(width: 240, height: 480)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    Text("TikTok is locked until you've prayed")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(NafsTheme.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 24)
            }

            NafsButton(title: "Continue") { vm.goNext() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                lockPulse = true
            }
        }
    }
}

private struct PhoneMockupView: View {
    let lockPulse: Bool

    var body: some View {
        ZStack {
            // Phone outer frame
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color(hex: "0E0E10"))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 30, y: 14)

            // Screen
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "1C1B1F"), Color(hex: "0A0A0E")],
                    startPoint: .top, endPoint: .bottom
                ))
                .padding(8)

            VStack(spacing: 0) {
                // Dynamic island
                Capsule()
                    .fill(Color.black)
                    .frame(width: 90, height: 28)
                    .padding(.top, 18)

                Spacer().frame(height: 28)

                // Top text overlay
                VStack(spacing: 4) {
                    Text("It's time for")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Maghrib")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.gold)
                }

                Spacer().frame(height: 22)

                // Lock placeholder area (for video insertion)
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(NafsTheme.gold.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        )

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(NafsTheme.gold.opacity(0.18))
                                .frame(width: 76, height: 76)
                                .scaleEffect(lockPulse ? 1.08 : 0.92)
                            Circle()
                                .strokeBorder(NafsTheme.gold.opacity(0.4), lineWidth: 1)
                                .frame(width: 76, height: 76)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(NafsTheme.goldGradient)
                        }
                        Text("Locked")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .tracking(2)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 200)

                Spacer()

                // Visual-only Go Pray button
                Text("Go Pray")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 14))
                    .shadow(color: NafsTheme.goldShadow, radius: 10, y: 4)
                    .padding(.horizontal, 22)

                Spacer().frame(height: 22)
            }
            .padding(.horizontal, 14)
        }
    }
}

// MARK: - Screen 10 — Reward

struct OBRewardView: View {
    let vm: OnboardingViewModel
    @State private var checkAppeared = false
    @State private var ringScale: CGFloat = 0.6

    var body: some View {
        OnboardingScaffold(
            blackText: "",
            goldText: "You pray → it unlocks",
            goldFirst: true,
            subtextLines: ["Simple.", "Instant.", "Done."],
            visual: {
                ZStack {
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(ringScale)
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.4), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(ringScale)
                    Circle()
                        .fill(NafsTheme.goldGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: NafsTheme.goldShadow, radius: 20, y: 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkAppeared ? 1 : 0.3)
                        .opacity(checkAppeared ? 1 : 0)
                }
                .frame(height: 220)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                        ringScale = 1
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.4)) {
                        checkAppeared = true
                    }
                }
            },
            bottom: { NafsButton(title: "Beautiful") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 11 — Progress

struct OBProgressView: View {
    let vm: OnboardingViewModel
    @State private var fill: CGFloat = 0

    var body: some View {
        OnboardingScaffold(
            blackText: "Build real",
            goldText: "consistency",
            subtextLines: [
                "Track your prayers.",
                "Stay consistent every day."
            ],
            visual: {
                ZStack {
                    ForEach(0..<3) { i in
                        let inset = CGFloat(i) * 26
                        Circle()
                            .stroke(NafsTheme.card, lineWidth: 10)
                            .frame(width: 200 - inset, height: 200 - inset)
                        Circle()
                            .trim(from: 0, to: fill * (1.0 - Double(i) * 0.15))
                            .stroke(
                                NafsTheme.goldGradient,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 200 - inset, height: 200 - inset)
                            .rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 2) {
                        Text("7")
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundStyle(NafsTheme.gold)
                        Text("day streak")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(NafsTheme.text.opacity(0.6))
                            .tracking(2)
                    }
                }
                .frame(height: 220)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
                        fill = 0.85
                    }
                }
            },
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 12 — Identity Shift

struct OBIdentityShiftView: View {
    let vm: OnboardingViewModel

    var body: some View {
        OnboardingScaffold(
            blackText: "This is your",
            goldText: "system now",
            subtextLines: ["Not motivation.", "Discipline."],
            visual: {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [NafsTheme.gold.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 22)

                    VStack(spacing: 10) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(NafsTheme.goldGradient)
                        Rectangle()
                            .fill(NafsTheme.gold)
                            .frame(width: 40, height: 1)
                        Text("DISCIPLINE")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(6)
                            .foregroundStyle(NafsTheme.text.opacity(0.7))
                    }
                }
                .frame(height: 220)
            },
            bottom: { NafsButton(title: "Activate Nafs") { vm.goNext() } }
        )
    }
}
