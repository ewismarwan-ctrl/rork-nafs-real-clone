import SwiftUI
import AVFoundation
import UIKit

struct NafsOpeningSplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: SplashPhase = .black
    @State private var exitOpacity: Double = 1
    @State private var clearedAppIDs: Set<String> = []

    private let apps = DistractingAppIcon.defaultSet
    private let particles = GoldParticle.seed
    private let streaks = LightStreak.seed

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color(hex: "17130B").opacity(phase.energyOpacity * 0.9),
                        Color(hex: "080808").opacity(0.85),
                        .black
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )
                .ignoresSafeArea()

                distractionField(in: proxy.size)
                centerEnergy(in: proxy.size)
                logoLockup
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .opacity(exitOpacity)
            .onAppear {
                Task {
                    await runSequence()
                }
            }
        }
    }

    private func distractionField(in size: CGSize) -> some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(apps) { app in
                    let driftX = reduceMotion ? 0 : sin(time * app.speed + app.seed) * app.drift
                    let driftY = reduceMotion ? 0 : cos(time * (app.speed * 0.82) + app.seed) * app.drift
                    let flicker = reduceMotion ? 1 : 0.86 + sin(time * 2.1 + app.seed) * 0.08
                    let clearedOpacity = clearedAppIDs.contains(app.id) ? 0.08 : 1

                    DopamineAppGlyph(app: app)
                        .scaleEffect(phase.appScale * app.depth)
                        .opacity(phase.appOpacity * clearedOpacity * flicker)
                        .blur(radius: phase.appBlur + app.blur)
                        .rotationEffect(.degrees(reduceMotion ? 0 : sin(time + app.seed) * app.rotation))
                        .position(
                            x: size.width * app.position.x + driftX,
                            y: size.height * app.position.y + driftY
                        )
                }
            }
        }
    }

    private func centerEnergy(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            NafsTheme.gold.opacity(0.42),
                            NafsTheme.gold.opacity(0.13),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 138
                    )
                )
                .frame(width: 276, height: 276)
                .scaleEffect(phase.energyScale)
                .blur(radius: 28)
                .opacity(phase.energyOpacity)

            ForEach(streaks) { streak in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, NafsTheme.gold.opacity(0.52), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: streak.length, height: streak.thickness)
                    .rotationEffect(.degrees(streak.angle))
                    .offset(x: streak.offset.width * phase.energyScale, y: streak.offset.height * phase.energyScale)
                    .opacity(phase.streakOpacity * streak.opacity)
                    .blur(radius: 1.2)
            }

            ForEach(particles) { particle in
                Circle()
                    .fill(NafsTheme.gold.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(
                        x: particle.offset.width * phase.particleSpread,
                        y: particle.offset.height * phase.particleSpread
                    )
                    .opacity(phase.particleOpacity)
                    .blur(radius: particle.blur)
            }
        }
        .position(x: size.width / 2, y: size.height / 2 - 26)
    }

    private var logoLockup: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .strokeBorder(NafsTheme.gold.opacity(0.16), lineWidth: 1)
                    .frame(width: 126, height: 126)
                    .scaleEffect(phase.logoScale + 0.12)
                    .opacity(phase.logoOpacity)
                    .blur(radius: 0.4)

                Circle()
                    .fill(NafsTheme.gold.opacity(0.1))
                    .frame(width: 114, height: 114)
                    .blur(radius: 18)
                    .opacity(phase.logoOpacity)

                CrescentStarMark(size: 72, color: NafsTheme.gold)
                    .shadow(color: NafsTheme.gold.opacity(0.62), radius: 28, y: 10)
                    .scaleEffect(phase.logoScale)
                    .opacity(phase.logoOpacity)
            }

            Text("Stop delaying Salah.")
                .font(.system(size: 31, weight: .bold, design: .default))
                .tracking(0.4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "F7F2E8"))
                .opacity(phase.textOpacity)
                .offset(y: phase.textOffset)
                .shadow(color: .black.opacity(0.32), radius: 18, y: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
    }

    @MainActor
    private func runSequence() async {
        let base = reduceMotion ? 0.55 : 1

        withAnimation(.easeOut(duration: 0.42 * base)) {
            phase = .apps
        }

        try? await Task.sleep(for: .milliseconds(Int(720 * base)))
        withAnimation(.timingCurve(0.18, 0.9, 0.22, 1, duration: 0.76 * base)) {
            phase = .energy
        }

        for app in apps {
            try? await Task.sleep(for: .milliseconds(Int(70 * base)))
            withAnimation(.easeOut(duration: 0.34 * base)) {
                clearedAppIDs.insert(app.id)
            }
        }

        try? await Task.sleep(for: .milliseconds(Int(350 * base)))
        NafsLaunchSound.shared.playImpact()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.78)
        withAnimation(.spring(response: 0.72 * base, dampingFraction: 0.82)) {
            phase = .logo
        }

        try? await Task.sleep(for: .milliseconds(Int(440 * base)))
        withAnimation(.easeOut(duration: 0.56 * base)) {
            phase = .message
        }

        try? await Task.sleep(for: .milliseconds(Int(860 * base)))
        withAnimation(.easeInOut(duration: 0.42 * base)) {
            exitOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(Int(460 * base)))
        onFinished()
    }
}

private enum SplashPhase {
    case black
    case apps
    case energy
    case logo
    case message

    var appOpacity: Double {
        switch self {
        case .black: return 0
        case .apps: return 0.72
        case .energy: return 0.22
        case .logo, .message: return 0
        }
    }

    var appScale: CGFloat {
        switch self {
        case .black: return 0.94
        case .apps: return 1
        case .energy: return 0.92
        case .logo, .message: return 0.84
        }
    }

    var appBlur: CGFloat {
        switch self {
        case .black: return 7
        case .apps: return 1.4
        case .energy: return 6
        case .logo, .message: return 12
        }
    }

    var energyOpacity: Double {
        switch self {
        case .black, .apps: return 0
        case .energy: return 0.92
        case .logo, .message: return 0.48
        }
    }

    var energyScale: CGFloat {
        switch self {
        case .black, .apps: return 0.36
        case .energy: return 1.08
        case .logo, .message: return 0.78
        }
    }

    var streakOpacity: Double {
        switch self {
        case .energy: return 0.64
        case .logo: return 0.2
        default: return 0
        }
    }

    var particleOpacity: Double {
        switch self {
        case .energy: return 0.82
        case .logo, .message: return 0.28
        default: return 0
        }
    }

    var particleSpread: CGFloat {
        switch self {
        case .black, .apps: return 0.2
        case .energy: return 1
        case .logo, .message: return 0.68
        }
    }

    var logoOpacity: Double {
        switch self {
        case .logo, .message: return 1
        default: return 0
        }
    }

    var logoScale: CGFloat {
        switch self {
        case .logo, .message: return 1
        default: return 0.72
        }
    }

    var textOpacity: Double {
        self == .message ? 1 : 0
    }

    var textOffset: CGFloat {
        self == .message ? 0 : 10
    }
}

private struct DistractingAppIcon: Identifiable {
    let id: String
    let symbol: String
    let tint: Color
    let position: CGPoint
    let depth: CGFloat
    let blur: CGFloat
    let drift: CGFloat
    let speed: Double
    let seed: Double
    let rotation: Double

    static let defaultSet: [DistractingAppIcon] = [
        .init(id: "TikTok", symbol: "music.note", tint: Color(hex: "7EF9FF"), position: CGPoint(x: 0.2, y: 0.23), depth: 0.86, blur: 1.8, drift: 18, speed: 0.9, seed: 0.2, rotation: 4),
        .init(id: "Instagram", symbol: "camera.fill", tint: Color(hex: "F15BB5"), position: CGPoint(x: 0.78, y: 0.29), depth: 1.0, blur: 0.8, drift: 14, speed: 1.1, seed: 1.9, rotation: 5),
        .init(id: "YouTube", symbol: "play.rectangle.fill", tint: Color(hex: "FF3B30"), position: CGPoint(x: 0.18, y: 0.62), depth: 1.08, blur: 1.1, drift: 16, speed: 1.0, seed: 3.1, rotation: 3),
        .init(id: "Snapchat", symbol: "bolt.fill", tint: Color(hex: "FFE66D"), position: CGPoint(x: 0.82, y: 0.66), depth: 0.92, blur: 1.6, drift: 19, speed: 0.85, seed: 4.4, rotation: 4),
        .init(id: "X", symbol: "xmark", tint: Color(hex: "E9EEF4"), position: CGPoint(x: 0.58, y: 0.16), depth: 0.72, blur: 2.4, drift: 12, speed: 1.2, seed: 5.8, rotation: 6)
    ]
}

private struct DopamineAppGlyph: View {
    let app: DistractingAppIcon

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.055))
                .frame(width: 58, height: 58)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(app.tint.opacity(0.26), lineWidth: 1)
                )
                .shadow(color: app.tint.opacity(0.2), radius: 18)

            Image(systemName: app.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(app.tint.opacity(0.86))
        }
        .accessibilityHidden(true)
    }
}

private struct GoldParticle: Identifiable {
    let id = UUID()
    let offset: CGSize
    let size: CGFloat
    let blur: CGFloat
    let opacity: Double

    static let seed: [GoldParticle] = [
        .init(offset: CGSize(width: -82, height: -22), size: 3.2, blur: 1.2, opacity: 0.5),
        .init(offset: CGSize(width: 74, height: 18), size: 2.6, blur: 1.0, opacity: 0.42),
        .init(offset: CGSize(width: -38, height: 74), size: 2.0, blur: 1.4, opacity: 0.36),
        .init(offset: CGSize(width: 42, height: -76), size: 2.4, blur: 1.1, opacity: 0.4),
        .init(offset: CGSize(width: 116, height: -38), size: 1.8, blur: 1.2, opacity: 0.28),
        .init(offset: CGSize(width: -120, height: 40), size: 1.7, blur: 1.4, opacity: 0.26)
    ]
}

private struct LightStreak: Identifiable {
    let id = UUID()
    let angle: Double
    let length: CGFloat
    let thickness: CGFloat
    let offset: CGSize
    let opacity: Double

    static let seed: [LightStreak] = [
        .init(angle: -12, length: 176, thickness: 1.2, offset: CGSize(width: -8, height: -18), opacity: 0.8),
        .init(angle: 24, length: 132, thickness: 0.9, offset: CGSize(width: 18, height: 32), opacity: 0.58),
        .init(angle: -46, length: 108, thickness: 0.8, offset: CGSize(width: 46, height: -8), opacity: 0.42)
    ]
}

@MainActor
private final class NafsLaunchSound {
    static let shared = NafsLaunchSound()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isPrepared = false

    func playImpact() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        prepareIfNeeded()

        guard let buffer = makeImpactBuffer() else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)

        if !engine.isRunning {
            try? engine.start()
        }

        player.play()
    }

    private func prepareIfNeeded() {
        guard !isPrepared else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: impactFormat)
        engine.mainMixerNode.outputVolume = 0.32
        isPrepared = true
    }

    private var impactFormat: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    private func makeImpactBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = impactFormat.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * 0.42)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: impactFormat, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let falloff = exp(-8.2 * t)
            let bass = sin(2 * Double.pi * 74 * t) * falloff
            let softOvertone = sin(2 * Double.pi * 148 * t) * exp(-12 * t) * 0.28
            channel[frame] = Float((bass + softOvertone) * 0.28)
        }

        return buffer
    }
}
