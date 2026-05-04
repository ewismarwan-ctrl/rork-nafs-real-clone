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
        VStack(spacing: 4) {
            if goldFirst {
                if !goldText.isEmpty { goldLine }
                if !blackText.isEmpty { blackLine }
            } else {
                if !blackText.isEmpty { blackLine }
                if !goldText.isEmpty { goldLine }
            }
        }
    }

    private var blackLine: some View {
        Text(blackText)
            .font(.system(size: 38, weight: .bold, design: .serif))
            .foregroundStyle(NafsTheme.text)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var goldLine: some View {
        Text(goldText)
            .font(.system(size: 38, weight: .bold, design: .serif))
            .foregroundStyle(NafsTheme.gold)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct OnboardingSubtext: View {
    let lines: [String]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(NafsTheme.text.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct TextOnlyScaffold<Bottom: View>: View {
    let blackText: String
    let goldText: String
    var goldFirst: Bool = false
    let subtextLines: [String]
    @ViewBuilder let bottom: () -> Bottom

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                OnboardingHeadline(black: blackText, gold: goldText, goldFirst: goldFirst)
                OnboardingSubtext(lines: subtextLines)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer()
            Spacer()

            bottom()
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Screen 1 — Problem

struct OBProblemView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "Stop delaying",
            goldText: "Salah",
            subtextLines: [
                "Your phone is the biggest distraction.",
                "Even when you intend to pray."
            ],
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 2 — Discipline

struct OBDisciplineView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "You don't lack",
            goldText: "discipline",
            subtextLines: [
                "You're just constantly distracted.",
                "That's the real problem."
            ],
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 3 — One Scroll

struct OBOneScrollView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "It starts with",
            goldText: "one scroll",
            subtextLines: [
                "You open your phone for a second.",
                "And lose track of time."
            ],
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 4 — Not your fault

struct OBNotFaultView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "It's not your",
            goldText: "fault",
            subtextLines: [
                "Apps are designed to keep you scrolling.",
                "That's why it's hard to stop."
            ],
            bottom: { NafsButton(title: "I get it") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 5 — System

struct OBSystemView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "So we built a",
            goldText: "system",
            subtextLines: [
                "Nafs removes distractions.",
                "At the exact moment you need to pray."
            ],
            bottom: { NafsButton(title: "Show me") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 6 — When it's time

struct OBWhenSalahView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "When it's time for",
            goldText: "Salah",
            subtextLines: [
                "Your distracting apps are locked.",
                "No more \u{201C}just 5 minutes\u{201D}."
            ],
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 7 — Automation

struct OBAutomationView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "No reminders.",
            goldText: "No willpower.",
            subtextLines: [
                "It happens automatically.",
                "You don't have to think about it."
            ],
            bottom: { NafsButton(title: "Continue") { vm.goNext() } }
        )
    }
}

// MARK: - Screen 8 — App Selection (simple)

struct OBAppSelectionView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false

    private let options: [(id: String, label: String)] = [
        ("tiktok", "TikTok"),
        ("instagram", "Instagram"),
        ("youtube", "YouTube"),
        ("twitter", "X"),
        ("snapchat", "Snapchat"),
        ("other", "Other")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    Spacer().frame(height: 32)

                    VStack(spacing: 16) {
                        OnboardingHeadline(black: "Select apps", gold: "to block")
                        OnboardingSubtext(lines: ["Choose what distracts you most."])
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 10) {
                        ForEach(options, id: \.id) { opt in
                            AppSelectionRow(
                                label: opt.label,
                                isOn: Binding(
                                    get: { vm.blockedDistractions.contains(opt.id) },
                                    set: { _ in vm.toggleBlockedDistraction(opt.id) }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 24)
                }
                .opacity(appeared ? 1 : 0)
            }

            NafsButton(title: "Continue", isEnabled: !vm.blockedDistractions.isEmpty) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

private struct AppSelectionRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isOn ? NafsTheme.gold : NafsTheme.text.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isOn {
                        Circle()
                            .fill(NafsTheme.gold)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? NafsTheme.gold.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
    }
}

// MARK: - Screen 9 — Phone Mockup (empty placeholder)

struct OBPhoneMockupView: View {
    let vm: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 12)

                    VStack(spacing: 4) {
                        Text("When it's time…")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(NafsTheme.text)
                        Text("Salah")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(NafsTheme.gold)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)

                    EmptyPhoneMockup()
                        .frame(width: 230, height: 470)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    Text("Your apps are locked until you've prayed.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(NafsTheme.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }

            NafsButton(title: "Continue") { vm.goNext() }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
        }
    }
}

private struct EmptyPhoneMockup: View {
    var body: some View {
        ZStack {
            // Phone outer frame
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color(hex: "0E0E10"))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 28, y: 14)

            // Empty screen — placeholder for video
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color(hex: "F2EFE8"))
                .padding(8)

            // Dynamic island indicator
            VStack {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 90, height: 28)
                    .padding(.top, 18)
                Spacer()
            }
        }
    }
}

// MARK: - Screen 10 — Reward

struct OBRewardView: View {
    let vm: OnboardingViewModel

    var body: some View {
        TextOnlyScaffold(
            blackText: "",
            goldText: "You pray \u{2192} it unlocks",
            goldFirst: true,
            subtextLines: ["Simple.", "Instant.", "Done."],
            bottom: { NafsButton(title: "Activate Nafs") { vm.goNext() } }
        )
    }
}
