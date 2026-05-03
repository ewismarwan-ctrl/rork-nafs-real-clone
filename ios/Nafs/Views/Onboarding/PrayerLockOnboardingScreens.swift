import SwiftUI

// MARK: - Shared narrative scaffold

private struct PLNarrativeScreen<Visual: View>: View {
    let headline: String
    let subtextLines: [String]
    let cta: String
    let visual: Visual
    let onContinue: () -> Void
    @State private var appeared: Bool = false

    init(
        headline: String,
        subtextLines: [String],
        cta: String = "Continue",
        @ViewBuilder visual: () -> Visual,
        onContinue: @escaping () -> Void
    ) {
        self.headline = headline
        self.subtextLines = subtextLines
        self.cta = cta
        self.visual = visual()
        self.onContinue = onContinue
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 24)

                    visual
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.9)
                        .offset(y: appeared ? 0 : 16)

                    VStack(spacing: 14) {
                        Text(headline)
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        VStack(spacing: 4) {
                            ForEach(Array(subtextLines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(.body))
                                    .foregroundStyle(NafsTheme.subtleText)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
            }

            NafsButton(title: cta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Premium glyph

private struct PLGlyph: View {
    let symbol: String
    var size: CGFloat = 150
    @State private var pulse: Bool = false
    @State private var rotate: Bool = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [NafsTheme.gold.opacity(0.22), NafsTheme.gold.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(pulse ? 1.08 : 0.94)
                .blur(radius: 22)

            // Rotating ornament ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            NafsTheme.gold.opacity(0.0),
                            NafsTheme.gold.opacity(0.55),
                            NafsTheme.gold.opacity(0.0),
                            NafsTheme.gold.opacity(0.55),
                            NafsTheme.gold.opacity(0.0),
                        ],
                        center: .center
                    ),
                    lineWidth: 1
                )
                .frame(width: size * 1.25, height: size * 1.25)
                .rotationEffect(.degrees(rotate ? 360 : 0))

            // Inner ring
            Circle()
                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)

            // Disc
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1A1612"), Color(hex: "0E0B08")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.86, height: size * 0.86)
                .overlay {
                    Circle()
                        .strokeBorder(NafsTheme.gold.opacity(0.18), lineWidth: 0.8)
                }

            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(NafsTheme.goldGradient)
                .shadow(color: NafsTheme.gold.opacity(0.4), radius: 14)
        }
        .frame(height: size * 1.45)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}

// MARK: - 1. Identity

struct PLIdentityScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("You don’t miss Salah…", "أنت لا تترك الصلاة…"),
            subtextLines: [
                L10n.text("You delay it.", "أنت تؤخّرها."),
                L10n.text("Just a few minutes turns into an hour.", "بضع دقائق تتحوّل إلى ساعة."),
            ],
            cta: L10n.text("I feel that", "أشعر بذلك"),
            visual: { PLGlyph(symbol: "moon.zzz.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 2. Behavior

struct PLBehaviorScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("It starts small", "تبدأ صغيرة"),
            subtextLines: [
                L10n.text("You open your phone for a second", "تفتح هاتفك للحظة"),
                L10n.text("Then Salah gets pushed back", "ثم تتأخّر الصلاة"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "clock.badge.exclamationmark.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 3. Pain

struct PLPainScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("It’s not a motivation problem", "ليست مشكلة دافع"),
            subtextLines: [
                L10n.text("It’s your environment", "إنّها بيئتك"),
                L10n.text("Your phone is the trigger", "هاتفك هو المُحفّز"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "iphone.gen3.radiowaves.left.and.right") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 4. Shift blame

struct PLShiftBlameScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("Your phone is designed to keep you scrolling", "هاتفك مُصمَّم ليُبقيك تتصفّح"),
            subtextLines: [
                L10n.text("That’s why it’s hard to stop", "لذلك يصعب التوقّف"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "arrow.triangle.2.circlepath") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 5. Solution

struct PLSolutionScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("So we changed the system", "لذلك غيّرنا النظام"),
            subtextLines: [
                L10n.text("Nafs removes distractions at the exact moment", "يُزيل نفس المشتّتات في اللحظة المحدّدة"),
                L10n.text("you need to pray", "التي تحتاج فيها أن تصلّي"),
            ],
            cta: L10n.text("Show me", "أرني"),
            visual: { PLGlyph(symbol: "shield.lefthalf.filled") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 6. Core feature

struct PLCoreFeatureScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("When Salah starts", "عندما يحين وقت الصلاة"),
            subtextLines: [
                L10n.text("Your distracting apps are locked", "تُقفل تطبيقاتك المشتّتة"),
                L10n.text("No more “just 5 minutes”", "لا مزيد من “خمس دقائق فقط”"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "lock.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 7. Distractions (interactive)

struct PLDistractionsScreen: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer(minLength: 16)

                    VStack(spacing: 10) {
                        Text(L10n.text("Choose your distractions", "اختر مشتّتاتك"))
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)

                        Text(L10n.text("Select the apps that waste your time.", "اختر التطبيقات التي تُضيّع وقتك."))
                            .font(.system(.body))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)

                    VStack(spacing: 10) {
                        ForEach(OnboardingDistractions.apps) { app in
                            DistractionToggleRow(
                                app: app,
                                isOn: vm.selectedDistractions.contains(app.id),
                                onToggle: { vm.toggleDistraction(app.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 12)
                }
            }
            .opacity(appeared ? 1 : 0)

            NafsButton(
                title: L10n.text("Continue", "متابعة"),
                isEnabled: vm.canProceed
            ) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }
}

private struct DistractionToggleRow: View {
    let app: DistractionApp
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: app.tint).opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: app.symbol)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(Color(hex: app.tint))
                }

                Text(app.name)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)

                Spacer()

                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? NafsTheme.gold : NafsTheme.cardBorder.opacity(0.6))
                        .frame(width: 50, height: 30)
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        .padding(2)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isOn ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isOn ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isOn ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
    }
}

// MARK: - 8. Automation

struct PLAutomationScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("We’ll handle the rest", "سنتولّى الباقي"),
            subtextLines: [
                L10n.text("It works automatically", "يعمل تلقائياً"),
                L10n.text("No willpower needed", "لا تحتاج إرادة"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "gearshape.2.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 9. Demo (Phone mockup)

struct PLDemoScreen: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 12)

                    VStack(spacing: 8) {
                        Text(L10n.text("It’s time for Maghrib", "حان وقت المغرب"))
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)

                        Text(L10n.text("TikTok is locked until you’ve prayed", "تيك توك مُقفل حتى تصلّي"))
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    PhoneMockupView()
                        .padding(.horizontal, 56)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    Spacer(minLength: 12)
                }
            }

            NafsButton(title: L10n.text("Continue", "متابعة")) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }
}

// Realistic iPhone mockup with empty inner area for video insertion later.
private struct PhoneMockupView: View {
    @State private var lockPulse: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = w * 2.05 // iPhone aspect

            ZStack {
                // Outer device body
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1C1A18"), Color(hex: "0A0908")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.5), radius: 26, y: 14)
                    .shadow(color: NafsTheme.goldShadow, radius: 30, y: 0)
                    .frame(width: w, height: h)

                // Side buttons
                HStack {
                    VStack(spacing: 12) {
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 2, height: h * 0.04)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 2, height: h * 0.06)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 2, height: h * 0.06)
                    }
                    .offset(x: -w * 0.005, y: -h * 0.05)
                    Spacer()
                    VStack {
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 2, height: h * 0.08)
                    }
                    .offset(x: w * 0.005, y: -h * 0.04)
                }
                .frame(width: w + 4, height: h)

                // Inner screen (PLACEHOLDER FOR VIDEO)
                ZStack {
                    RoundedRectangle(cornerRadius: w * 0.13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0F0D0A"), Color(hex: "1A1612")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Subtle pattern hint of empty video area
                    VStack(spacing: 16) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(NafsTheme.gold.opacity(0.14))
                                .frame(width: w * 0.32, height: w * 0.32)
                                .scaleEffect(lockPulse ? 1.08 : 0.94)
                                .blur(radius: 4)

                            Circle()
                                .strokeBorder(NafsTheme.gold.opacity(0.4), lineWidth: 1)
                                .frame(width: w * 0.28, height: w * 0.28)

                            Image(systemName: "lock.fill")
                                .font(.system(size: w * 0.12, weight: .semibold))
                                .foregroundStyle(NafsTheme.goldGradient)
                        }

                        VStack(spacing: 6) {
                            Text(L10n.text("PRAYER LOCK", "قفل الصلاة"))
                                .font(.system(size: w * 0.045, weight: .heavy))
                                .tracking(3)
                                .foregroundStyle(NafsTheme.gold)

                            Text(L10n.text("Maghrib", "المغرب"))
                                .font(.system(size: w * 0.07, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        // Bottom hint that this is placeholder
                        Text(L10n.text("Video placeholder", "مكان الفيديو"))
                            .font(.system(size: w * 0.03, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.18))
                            .padding(.bottom, h * 0.06)
                    }

                    // Dynamic island
                    Capsule()
                        .fill(.black)
                        .frame(width: w * 0.32, height: h * 0.038)
                        .offset(y: -h * 0.43)
                }
                .frame(width: w * 0.92, height: h * 0.96)
                .clipShape(RoundedRectangle(cornerRadius: w * 0.13, style: .continuous))
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(1.0 / 2.05, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                lockPulse = true
            }
        }
    }
}

// MARK: - 10. Reward (You pray → it unlocks)

struct PLRewardScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("You pray → it unlocks", "تصلّي ← يُفتح القفل"),
            subtextLines: [
                L10n.text("Simple", "بسيط"),
                L10n.text("Instant", "فوري"),
                L10n.text("Done", "تمّ"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "checkmark.seal.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 11. Identity shift (Build real consistency)

struct PLIdentityShiftScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("Build real consistency", "ابنِ مداومة حقيقية"),
            subtextLines: [
                L10n.text("Track your prayers", "تتبّع صلواتك"),
                L10n.text("Stay consistent every day", "حافظ كل يوم"),
            ],
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "chart.line.uptrend.xyaxis") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 12. System (final)

struct PLSystemScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("This is your system now", "هذا نظامك الآن"),
            subtextLines: [
                L10n.text("Not motivation", "ليست حماسة"),
                L10n.text("Discipline", "إنّه انضباط"),
            ],
            cta: L10n.text("Start my journey", "ابدأ رحلتي"),
            visual: { PLGlyph(symbol: "shield.checkered") },
            onContinue: { vm.goNext() }
        )
    }
}
