import SwiftUI

// MARK: - Shared narrative scaffold

private struct PLNarrativeScreen<Visual: View>: View {
    let headline: String
    let subtext: String
    let cta: String
    let visual: Visual
    let onContinue: () -> Void
    @State private var appeared: Bool = false

    init(
        headline: String,
        subtext: String,
        cta: String = "Continue",
        @ViewBuilder visual: () -> Visual,
        onContinue: @escaping () -> Void
    ) {
        self.headline = headline
        self.subtext = subtext
        self.cta = cta
        self.visual = visual()
        self.onContinue = onContinue
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    visual
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    VStack(spacing: 14) {
                        Text(headline)
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtext)
                            .font(.system(.body))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }

            NafsButton(title: cta, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// Centered glyph inside a glowing gold circle.
private struct PLGlyph: View {
    let symbol: String
    var size: CGFloat = 140
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [NafsTheme.gold.opacity(0.18), NafsTheme.gold.opacity(0.04), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(pulse ? 1.06 : 0.96)
                .blur(radius: 18)

            Circle()
                .strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1)
                .frame(width: size, height: size)

            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(NafsTheme.goldGradient)
        }
        .frame(height: size * 1.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - 1. Identity

struct PLIdentityScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("You don’t miss Salah… you delay it.", "أنت لا تترك الصلاة… أنت تؤخّرها."),
            subtext: L10n.text("Just a few minutes turns into an hour.", "بضع دقائق تتحول إلى ساعة."),
            cta: L10n.text("I feel that", "أشعر بذلك"),
            visual: { PLGlyph(symbol: "hourglass") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 2. Behavior

struct PLBehaviorScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("You open your phone for a second…", "تفتح هاتفك للحظة…"),
            subtext: L10n.text("Then Salah gets pushed back.", "ثم تتأخر الصلاة."),
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "iphone.gen3") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 3. Pain

struct PLPainScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("It’s not a motivation problem.", "ليست مشكلة دافع."),
            subtext: L10n.text("It’s your environment.", "إنّها بيئتك."),
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "heart.slash") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 4. Shift blame

struct PLShiftBlameScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("Your phone is designed to keep you scrolling.", "هاتفك مُصمّم لإبقائك تتصفّح."),
            subtext: L10n.text("That’s why it’s hard to stop.", "لذلك يصعب أن تتوقف."),
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "infinity") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 5. Solution

struct PLSolutionScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("So we changed the system.", "لذلك غيّرنا النظام."),
            subtext: L10n.text("Nafs blocks distractions at prayer time.", "نفس يحجب المشتتات في وقت الصلاة."),
            cta: L10n.text("Show me", "أرني"),
            visual: { PLGlyph(symbol: "lock.shield.fill") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 6. Core feature

struct PLCoreFeatureScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("When Salah starts…", "عندما يحين وقت الصلاة…"),
            subtext: L10n.text("Your apps are locked.", "تُقفل تطبيقاتك."),
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
                    Spacer(minLength: 24)

                    VStack(spacing: 10) {
                        Text(L10n.text("Choose what distracts you", "اختر ما يشتّتك"))
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)

                        Text(L10n.text("These are the apps Nafs will lock at prayer time.", "هذه التطبيقات سيقفلها نفس عند الصلاة."))
                            .font(.system(.subheadline))
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
            headline: L10n.text("We’ll handle the rest.", "سنتولّى الباقي."),
            subtext: L10n.text("No reminders. No willpower needed.", "بلا تذكيرات. بلا إرادة."),
            cta: L10n.text("Continue", "متابعة"),
            visual: { PLGlyph(symbol: "wand.and.stars") },
            onContinue: { vm.goNext() }
        )
    }
}

// MARK: - 9. Demo

struct PLDemoScreen: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var lockShake: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    Text(L10n.text("This is what it looks like", "هكذا يبدو الأمر"))
                        .font(.system(.subheadline, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(NafsTheme.gold)

                    MockLockScreenCard(shake: lockShake)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.9)

                    Spacer(minLength: 12)
                }
            }

            NafsButton(title: L10n.text("Go Pray", "اذهب للصلاة")) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeInOut(duration: 0.45)) { lockShake.toggle() }
            }
        }
    }
}

private struct MockLockScreenCard: View {
    let shake: Bool

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(.caption))
                Text(L10n.text("PRAYER LOCK ACTIVE", "قفل الصلاة مفعل"))
                    .font(.system(.caption2, weight: .heavy))
                    .tracking(2)
            }
            .foregroundStyle(NafsTheme.gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(NafsTheme.gold.opacity(0.12))
            .clipShape(.capsule)

            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "lock.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(NafsTheme.goldGradient)
                    .rotationEffect(.degrees(shake ? -6 : 6))
            }

            VStack(spacing: 6) {
                Text(L10n.text("It’s time for Maghrib", "حان وقت المغرب"))
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(.white)

                Text(L10n.text("TikTok is locked until you’ve prayed", "تيك توك مقفل حتى تصلّي"))
                    .font(.system(.subheadline))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text(L10n.text("Go Pray", "اذهب للصلاة"))
                    .font(.system(.subheadline, weight: .bold))
            }
            .foregroundStyle(.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 28)
            .background(NafsTheme.goldGradient)
            .clipShape(.capsule)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1612"), Color(hex: "0E0B08")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(.rect(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: NafsTheme.goldShadow, radius: 28, y: 12)
    }
}

// MARK: - 10. Reward + progress

struct PLRewardScreen: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false
    @State private var streakAppeared: Bool = false

    private let prayers: [(String, String, Bool)] = [
        ("Fajr", "5:14 AM", true),
        ("Dhuhr", "1:02 PM", true),
        ("Asr", "4:38 PM", true),
        ("Maghrib", "7:21 PM", false),
        ("Isha", "8:46 PM", false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    VStack(spacing: 10) {
                        Text(L10n.text("You pray → it unlocks", "تصلّي ← يُفتح القفل"))
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)

                        Text(L10n.text("Every prayer earns back your apps — and builds your streak.", "كل صلاة تستعيد بها تطبيقاتك — وتبني سلسلتك."))
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.text("MAGHRIB COMPLETED", "أُتمّت المغرب"))
                                    .font(.system(.caption2, weight: .heavy))
                                    .tracking(2)
                                    .foregroundStyle(NafsTheme.gold)
                                Text(L10n.text("3 of 5 prayers today", "٣ من ٥ صلوات اليوم"))
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(NafsTheme.text)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(.title))
                                .foregroundStyle(NafsTheme.goldGradient)
                        }

                        ProgressBar(progress: streakAppeared ? 0.6 : 0)

                        VStack(spacing: 8) {
                            ForEach(prayers, id: \.0) { name, time, done in
                                MockPrayerRow(name: name, time: time, completed: done)
                            }
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text(L10n.text("12-day streak", "سلسلة ١٢ يوماً"))
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(NafsTheme.text)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(NafsTheme.card)
                        .clipShape(.capsule)
                    }
                    .padding(20)
                    .background(NafsTheme.card.opacity(0.6))
                    .clipShape(.rect(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(NafsTheme.gold.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

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
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.25)) {
                streakAppeared = true
            }
        }
    }
}

private struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(NafsTheme.cardBorder.opacity(0.4)).frame(height: 8)
                Capsule().fill(NafsTheme.goldGradient)
                    .frame(width: geo.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }
}

private struct MockPrayerRow: View {
    let name: String
    let time: String
    let completed: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(completed ? NafsTheme.gold : NafsTheme.subtleText.opacity(0.5))
            Text(name)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.text)
            Spacer()
            Text(time)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }
}

// MARK: - 11. Identity shift

struct PLIdentityShiftScreen: View {
    let vm: OnboardingViewModel
    var body: some View {
        PLNarrativeScreen(
            headline: L10n.text("This is how consistency starts.", "هكذا تبدأ المداومة."),
            subtext: L10n.text("One prayer at a time.", "صلاة بعد صلاة."),
            cta: L10n.text("Start my journey", "ابدأ رحلتي"),
            visual: { PLGlyph(symbol: "sparkles") },
            onContinue: { vm.goNext() }
        )
    }
}
