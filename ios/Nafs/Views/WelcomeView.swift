import SwiftUI

struct WelcomeView: View {
    let userName: String
    let onGetStarted: () -> Void
    @Environment(LanguageManager.self) private var lang

    @State private var crescentScale: CGFloat = 0.3
    @State private var crescentOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var featuresOpacity: Double = 0
    @State private var featuresOffset: CGFloat = 25
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 30
    @State private var shimmerPhase: CGFloat = -1
    @State private var floatingOffset: CGFloat = 0
    @State private var glowOpacity: Double = 0.3

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()
            IslamicPatternView(opacity: 0.03)

            radialGlow
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                crescentSection
                    .padding(.bottom, 28)

                titleSection
                    .padding(.bottom, 8)

                subtitleSection
                    .padding(.bottom, 40)

                featureCards
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)

                Spacer()

                getStartedButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                Text(L10n.text("Bismillah, let's begin 🌙", "بسم الله، لنبدأ 🌙"))
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
                    .opacity(buttonOpacity)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            runEntrance()
            startFloating()
        }
    }

    private var radialGlow: some View {
        RadialGradient(
            colors: [
                NafsTheme.gold.opacity(glowOpacity * 0.15),
                NafsTheme.gold.opacity(glowOpacity * 0.05),
                Color.clear
            ],
            center: .center,
            startRadius: 20,
            endRadius: 300
        )
        .blur(radius: 60)
    }

    private var crescentSection: some View {
        ZStack {
            Circle()
                .fill(NafsTheme.gold.opacity(0.08))
                .frame(width: 160, height: 160)
                .blur(radius: 30)

            Circle()
                .fill(NafsTheme.gold.opacity(0.05))
                .frame(width: 120, height: 120)
                .blur(radius: 15)

            CrescentStarMark(size: 100, color: NafsTheme.gold)
                .shadow(color: NafsTheme.goldShadow, radius: 20, y: 8)
        }
        .scaleEffect(crescentScale)
        .opacity(crescentOpacity)
        .offset(y: floatingOffset)
    }

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(L10n.text("Welcome, \(displayName)", "أهلاً، \(displayName)"))
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(NafsTheme.text)

            HStack(spacing: 0) {
                Text("to ")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(NafsTheme.text)
                Text("Nafs")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(NafsTheme.gold)
            }
        }
        .multilineTextAlignment(.center)
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }

    private var subtitleSection: some View {
        Text(L10n.text("Your companion on the\npath to Allah", "رفيقك في\nالطريق إلى الله"))
            .font(.system(.body, weight: .regular))
            .foregroundStyle(NafsTheme.subtleText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .offset(y: subtitleOffset)
            .opacity(subtitleOpacity)
    }

    private var featureCards: some View {
        VStack(spacing: 12) {
            featureRow(icon: "moon.stars.fill", text: L10n.text("Prayer tracking & reminders", "متابعة الصلاة والتذكيرات"))
            featureRow(icon: "brain.head.profile", text: L10n.text("AI Islamic guidance", "إرشاد إسلامي بالذكاء الاصطناعي"))
            featureRow(icon: "chart.line.uptrend.xyaxis", text: L10n.text("Spiritual growth plan", "خطة النمو الروحي"))
        }
        .opacity(featuresOpacity)
        .offset(y: featuresOffset)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(NafsTheme.gold)
            }

            Text(text)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.text)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(NafsTheme.card)
                .shadow(color: NafsTheme.gold.opacity(0.06), radius: 8, y: 4)
        )
    }

    private var getStartedButton: some View {
        Button {
            onGetStarted()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(NafsTheme.goldGradient)
                    .shadow(color: NafsTheme.goldShadow.opacity(0.5), radius: 16, y: 8)

                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(shimmerPhase > -0.2 && shimmerPhase < 0.4 ? 0.3 : 0),
                                .white.opacity(shimmerPhase > 0.0 && shimmerPhase < 0.6 ? 0.15 : 0),
                                .clear
                            ],
                            startPoint: UnitPoint(x: shimmerPhase, y: 0),
                            endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 1)
                        )
                    )

                HStack(spacing: 10) {
                    Text(L10n.text("Get Started", "ابدأ الآن"))
                        .font(.system(.body, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(.body, weight: .bold))
                }
                .foregroundStyle(.white)
            }
            .frame(height: 58)
        }
        .opacity(buttonOpacity)
        .offset(y: buttonOffset)
        .sensoryFeedback(.impact(weight: .medium), trigger: buttonOpacity > 0.5)
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            crescentScale = 1.0
            crescentOpacity = 1.0
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4)) {
            glowOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7)) {
            subtitleOffset = 0
            subtitleOpacity = 1
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9)) {
            featuresOpacity = 1
            featuresOffset = 0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2)) {
            buttonOpacity = 1
            buttonOffset = 0
        }

        startShimmer()
    }

    private func startShimmer() {
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            runShimmerLoop()
        }
    }

    private func runShimmerLoop() {
        shimmerPhase = -1
        withAnimation(.easeInOut(duration: 1.5)) {
            shimmerPhase = 2.0
        }
        Task {
            try? await Task.sleep(for: .seconds(4))
            runShimmerLoop()
        }
    }

    private func startFloating() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatingOffset = -6
        }
    }
}
