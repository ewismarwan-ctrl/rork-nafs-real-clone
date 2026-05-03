import SwiftUI

struct PersonalizedScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var crescentScale: CGFloat = 0.7
    @State private var glowPulse: Bool = false
    @State private var bulletAppeared: [Bool] = [false, false, false]
    @State private var floatingOffset: CGFloat = 0
    @State private var starRotation: Double = 0

    private var bulletPoints: [(icon: String, text: String)] {
        [
            ("moon.stars.fill", NafsStrings.personalizedBullet1.localized),
            ("sparkles", NafsStrings.personalizedBullet2.localized),
            ("hourglass", NafsStrings.personalizedBullet3.localized),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 16)

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        NafsTheme.gold.opacity(0.25),
                                        NafsTheme.gold.opacity(0.1),
                                        NafsTheme.gold.opacity(0.03),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(glowPulse ? 1.15 : 0.9)
                            .blur(radius: 15)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [NafsTheme.gold.opacity(0.12), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        CrescentStarMark(size: 90, color: NafsTheme.gold)
                            .shadow(color: NafsTheme.goldShadow, radius: 20, y: 6)
                            .scaleEffect(crescentScale)
                            .rotationEffect(.degrees(starRotation))
                    }
                    .offset(y: floatingOffset)

                    VStack(spacing: 10) {
                        Text(NafsStrings.jazakAllah.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                            .tracking(3)
                            .textCase(.uppercase)

                        Text(vm.displayName)
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(NafsTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Rectangle()
                            .fill(NafsTheme.goldGradient)
                            .frame(width: 50, height: 2)
                            .clipShape(.capsule)

                        Text(NafsStrings.personalizedReady.localized)
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                    }

                    VStack(spacing: 8) {
                        ForEach(Array(bulletPoints.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(NafsTheme.gold.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: item.icon)
                                        .font(.system(.caption, weight: .semibold))
                                        .foregroundStyle(NafsTheme.gold)
                                }
                                Text(item.text)
                                    .font(.system(.subheadline, weight: .medium))
                                    .foregroundStyle(NafsTheme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(.caption2, weight: .bold))
                                    .foregroundStyle(NafsTheme.gold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
                            )
                            .opacity(bulletAppeared.indices.contains(index) && bulletAppeared[index] ? 1 : 0)
                            .offset(y: bulletAppeared.indices.contains(index) && bulletAppeared[index] ? 0 : 12)
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            NafsButton(title: NafsStrings.buildMyPlan.localized) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
                crescentScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.3)) {
                floatingOffset = -6
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(0.5)) {
                starRotation = 5
            }
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5 + Double(i) * 0.18)) {
                    bulletAppeared[i] = true
                }
            }
        }
    }
}

struct LoadingScreenView: View {
    let vm: OnboardingViewModel
    @State private var crescentRotation: Double = 0

    private var loadingTexts: [String] {
        [
            NafsStrings.loadingText1.localized,
            NafsStrings.loadingText2.localized,
            NafsStrings.loadingText3.localized,
            NafsStrings.loadingText4.localized,
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                CrescentStarMark(size: 100, color: NafsTheme.gold)
                    .rotationEffect(.degrees(crescentRotation))

                VStack(spacing: 16) {
                    Text(loadingTexts[min(vm.loadingTextIndex, loadingTexts.count - 1)])
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(NafsTheme.text)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: vm.loadingTextIndex)
                        .id(vm.loadingTextIndex)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(NafsTheme.card)
                                .frame(height: 6)
                            Capsule()
                                .fill(NafsTheme.goldGradient)
                                .frame(width: geo.size.width * vm.loadingProgress, height: 6)
                                .animation(.linear(duration: 0.1), value: vm.loadingProgress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 40)
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
        .onAppear {
            vm.startLoading()
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                crescentRotation = 8
            }
        }
    }
}

struct ScoreScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var ringProgress: Double = 0
    @State private var showScore: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    Text(NafsStrings.scoreTitle.localized + vm.displayName)
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 16)

                    ZStack {
                        Circle()
                            .stroke(NafsTheme.card, lineWidth: 12)
                            .frame(width: 130, height: 130)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                NafsTheme.goldGradient,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            if showScore {
                                Text("\(vm.nafsScore)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(NafsTheme.gold)
                                    .transition(.scale.combined(with: .opacity))
                                Text("/ 100")
                                    .font(.system(.caption, weight: .medium))
                                    .foregroundStyle(NafsTheme.subtleText)
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 6)

                    Text(NafsStrings.deenStrength.localized)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                        .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 16)

                    VStack(spacing: 10) {
                        ForEach(vm.personalizedInsights, id: \.self) { insight in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NafsTheme.gold)
                                Text(insight)
                                    .font(.system(.subheadline))
                                    .foregroundStyle(NafsTheme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(14)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)

                    Text(vm.scoreMessage)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .italic()

                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            NafsButton(title: NafsStrings.continueBtn.localized) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                ringProgress = Double(vm.nafsScore) / 100.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.4)) {
                    showScore = true
                }
            }
        }
    }
}
