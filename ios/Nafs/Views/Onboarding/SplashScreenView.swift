import SwiftUI

struct SplashScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var markScale: CGFloat = 0.6
    @State private var taglineAppeared: Bool = false
    @State private var glowPulse: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let markSize: CGFloat = min(proxy.size.width * 0.36, 140)
            let glowSize: CGFloat = markSize * 2.6

            VStack(spacing: 0) {
                Spacer(minLength: height * 0.12)

                VStack(spacing: 36) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [NafsTheme.gold.opacity(0.18), NafsTheme.gold.opacity(0.06), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: glowSize / 2
                                )
                            )
                            .frame(width: glowSize, height: glowSize)
                            .scaleEffect(glowPulse ? 1.12 : 0.88)
                            .blur(radius: 22)

                        CrescentStarMark(size: markSize, color: NafsTheme.gold)
                            .shadow(color: NafsTheme.goldShadow, radius: 22, y: 8)
                            .scaleEffect(markScale)
                    }
                    .frame(height: glowSize)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 14) {
                        Text("NAFS")
                            .font(.system(size: 42, weight: .medium, design: .serif))
                            .foregroundStyle(NafsTheme.text)
                            .tracking(18)
                            .opacity(appeared ? 1 : 0)

                        Text("\u{0646}\u{0641}\u{0633}")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(NafsTheme.gold)
                            .opacity(appeared ? 1 : 0)
                    }

                    VStack(spacing: 14) {
                        Rectangle()
                            .fill(NafsTheme.goldGradient)
                            .frame(width: 56, height: 1)
                            .opacity(taglineAppeared ? 1 : 0)

                        Text("STOP DELAYING SALAH")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NafsTheme.text.opacity(0.65))
                            .tracking(5)
                            .opacity(taglineAppeared ? 1 : 0)
                            .offset(y: taglineAppeared ? 0 : 8)
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                NafsButton(title: "Stop delaying Salah") {
                    vm.goNext()
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer().frame(height: max(40, height * 0.06))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
                markScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowPulse = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
                taglineAppeared = true
            }
        }
    }
}
