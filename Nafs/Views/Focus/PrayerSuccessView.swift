import SwiftUI

struct PrayerSuccessView: View {
    let prayer: PrayerName
    let completedCount: Int
    let totalCount: Int
    let streak: Int
    let onContinue: () -> Void

    @Environment(LanguageManager.self) private var lang
    @Environment(\.colorScheme) private var colorScheme

    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var ringProgress: CGFloat = 0
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [NafsTheme.gold.opacity(0.18), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()
            .opacity(glowPulse ? 1 : 0.6)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glowPulse)

            VStack(spacing: 32) {
                Spacer(minLength: 20)

                checkmark

                VStack(spacing: 10) {
                    headline
                    subtext
                }
                .opacity(contentOpacity)

                progressSection
                    .opacity(contentOpacity)

                Spacer()

                continueButton
                    .opacity(contentOpacity)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .padding(.top, 40)
        }
        .sensoryFeedback(.success, trigger: checkOpacity > 0)
        .onAppear { animateIn() }
    }

    // MARK: - Pieces

    private var checkmark: some View {
        ZStack {
            Circle()
                .stroke(NafsTheme.gold.opacity(0.18), lineWidth: 1)
                .frame(width: 168, height: 168)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    NafsTheme.goldGradient,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 168, height: 168)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [NafsTheme.gold.opacity(0.22), NafsTheme.gold.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 132, height: 132)
                .blur(radius: 0.5)

            Image(systemName: "checkmark")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(NafsTheme.goldGradient)
                .scaleEffect(checkScale)
                .opacity(checkOpacity)
                .shadow(color: NafsTheme.goldShadow, radius: 16, x: 0, y: 0)
        }
    }

    private var headline: some View {
        VStack(spacing: 4) {
            Text(L10n.text("Alhamdulillah,", "الحمد لله،"))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(NafsTheme.gold)
            Text(L10n.text("you’ve prayed", "لقد صلّيت"))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(NafsTheme.text)
        }
        .multilineTextAlignment(.center)
    }

    private var subtext: some View {
        VStack(spacing: 4) {
            Text(L10n.text("Apps are now unlocked", "تم فتح التطبيقات الآن"))
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
            Text(L10n.text("You stayed consistent today", "بقيتَ على الالتزام اليوم"))
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText.opacity(0.85))
        }
        .multilineTextAlignment(.center)
    }

    private var progressSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(PrayerName.allCases, id: \.self) { p in
                    let done = prayerIndex(p) < completedCount
                    Capsule()
                        .fill(done ? NafsTheme.gold : NafsTheme.subtleText.opacity(0.18))
                        .frame(height: 6)
                        .overlay {
                            if done {
                                Capsule()
                                    .fill(NafsTheme.gold.opacity(0.5))
                                    .blur(radius: 6)
                            }
                        }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
                Text(L10n.text(
                    "\(completedCount)/\(totalCount) prayers completed today",
                    "\(completedCount)/\(totalCount) صلاة أُتمت اليوم"
                ))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)

                if streak > 0 {
                    Text("·")
                        .foregroundStyle(NafsTheme.subtleText)
                    Image(systemName: "flame.fill")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                    Text(L10n.text("\(streak)-day streak", "سلسلة \(streak) يوم"))
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(NafsTheme.text)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text(L10n.text("Continue", "متابعة"))
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(NafsTheme.goldGradient)
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: NafsTheme.goldShadow, radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func prayerIndex(_ p: PrayerName) -> Int {
        PrayerName.allCases.firstIndex(of: p) ?? 0
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.9)) {
            ringProgress = 1
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.15)) {
            checkScale = 1
            checkOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
            contentOpacity = 1
        }
        glowPulse = true
    }
}
