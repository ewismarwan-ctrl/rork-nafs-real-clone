import SwiftUI

struct GoldParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var speed: CGFloat
}

struct GoldParticleBurst: View {
    @State private var particles: [GoldParticle] = []
    @State private var isAnimating: Bool = false
    let trigger: Bool

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(NafsTheme.gold)
                    .frame(width: 6 * particle.scale, height: 6 * particle.scale)
                    .offset(x: isAnimating ? particle.x * 40 : 0, y: isAnimating ? particle.y * 40 : 0)
                    .opacity(isAnimating ? 0 : particle.opacity)
            }
        }
        .onChange(of: trigger) { _, _ in
            burst()
        }
    }

    private func burst() {
        particles = (0..<12).map { _ in
            GoldParticle(
                x: CGFloat.random(in: -1...1),
                y: CGFloat.random(in: -1...1),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.6...1.0),
                speed: CGFloat.random(in: 0.5...1.0)
            )
        }
        isAnimating = false
        withAnimation(.easeOut(duration: 0.6)) {
            isAnimating = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            particles = []
            isAnimating = false
        }
    }
}

struct PremiumGateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let storeViewModel: StoreViewModel
    @State private var showUpgradeSheet: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(NafsTheme.gold)
                .symbolEffect(.pulse)

            Text(title)
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(.body))
                .foregroundStyle(NafsTheme.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NafsButton(title: "Unlock Premium →") {
                showUpgradeSheet = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NafsTheme.background)
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePaywallSheet(
                storeViewModel: storeViewModel,
                feature: title,
                benefit: subtitle,
                onDismiss: { showUpgradeSheet = false },
                onSuccess: { showUpgradeSheet = false }
            )
        }
    }
}

struct FreePlanBanner: View {
    var onUpgrade: (() -> Void)? = nil

    var body: some View {
        Button {
            onUpgrade?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(NafsTheme.gold)
                Text("You're on the free plan. Unlock prayer-time app locking with Premium.")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(NafsTheme.gold.opacity(0.12))
            .clipShape(.rect(cornerRadius: 12))
        }
    }
}

struct QuickLogButton: View {
    let icon: String
    let label: String
    let tokens: Int
    let isLogged: Bool
    @State private var burstTrigger: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            if !isLogged {
                burstTrigger.toggle()
                action()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isLogged ? NafsTheme.gold.opacity(0.2) : NafsTheme.card)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(.title3))
                        .foregroundStyle(isLogged ? NafsTheme.gold : NafsTheme.subtleText)
                        .symbolEffect(.bounce, value: burstTrigger)
                    GoldParticleBurst(trigger: burstTrigger)
                }
                Text(label)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(NafsTheme.text)
                Text("+\(tokens)")
                    .font(.system(.caption2, weight: .bold))
                    .foregroundStyle(NafsTheme.gold)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: burstTrigger)
        .disabled(isLogged)
        .opacity(isLogged ? 0.6 : 1)
    }
}
