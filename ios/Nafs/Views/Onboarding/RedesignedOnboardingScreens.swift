import SwiftUI
import AVFoundation
import UIKit

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
                "You don't usually miss prayer completely.",
                "But it keeps getting pushed back.",
                "And the day slips away."
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
                "You already want to pray on time.",
                "But your environment makes it difficult.",
                "Your phone is always within reach."
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
                "Just to check something small.",
                "And suddenly 20–30 minutes are gone."
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
                "Apps are designed to keep your attention.",
                "They're built to make you stay longer.",
                "That's why it feels hard to stop."
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
                "Instead of relying on willpower,",
                "we remove the distraction completely.",
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
                "No more \u{201C}just 5 minutes\u{201D}.",
                "No more pushing it back."
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
                "You don't need more notifications.",
                "You need fewer distractions.",
                "And this works automatically."
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
                        OnboardingSubtext(lines: [
                            "Choose what usually pulls your attention.",
                            "These will be locked at prayer time."
                        ])
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
            .background(NafsTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? NafsTheme.gold.opacity(0.5) : NafsTheme.cardBorder, lineWidth: 1)
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
                        .frame(width: 240, height: 240 * 1040.0 / 480.0)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    Text("Your apps stay locked until you've prayed.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(NafsTheme.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
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
        // Phone bezel + screen, clipped together so nothing bleeds outside the mockup.
        PlayOnceVideoPlayer(resourceName: "onboarding_lock", ext: "mov")
            .background(Color(hex: "0E0E10"))
            .clipShape(.rect(cornerRadius: 40, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.85), lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.2), radius: 28, y: 14)
    }
}

private struct PlayOnceVideoPlayer: UIViewRepresentable {
    let resourceName: String
    let ext: String

    func makeUIView(context: Context) -> PlayOnceVideoUIView {
        let view = PlayOnceVideoUIView()
        if let url = Bundle.main.url(forResource: resourceName, withExtension: ext) {
            view.configure(with: url)
        }
        return view
    }

    func updateUIView(_ uiView: PlayOnceVideoUIView, context: Context) {}
}

final class PlayOnceVideoUIView: UIView {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private let replayButton = UIButton(type: .system)
    private var hasPlayed = false

    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func configure(with url: URL) {
        clipsToBounds = true
        layer.masksToBounds = true
        backgroundColor = UIColor(red: 0x0E/255, green: 0x0E/255, blue: 0x10/255, alpha: 1)
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .pause
        player = p
        playerLayer.player = p
        playerLayer.videoGravity = .resizeAspect

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.showReplay()
        }

        setupReplayButton()
        p.play()
    }

    private func setupReplayButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.counterclockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.55)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        replayButton.configuration = config
        replayButton.alpha = 0
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.addTarget(self, action: #selector(replayTapped), for: .touchUpInside)
        addSubview(replayButton)
        NSLayoutConstraint.activate([
            replayButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            replayButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc private func replayTapped() {
        player?.seek(to: .zero)
        player?.play()
        UIView.animate(withDuration: 0.2) { self.replayButton.alpha = 0 }
    }

    private func showReplay() {
        UIView.animate(withDuration: 0.25) { self.replayButton.alpha = 1 }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    deinit {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
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
            subtextLines: [
                "No friction.",
                "No extra steps.",
                "Just pray, and continue your day."
            ],
            bottom: { NafsButton(title: "Activate Nafs") { vm.goNext() } }
        )
    }
}
