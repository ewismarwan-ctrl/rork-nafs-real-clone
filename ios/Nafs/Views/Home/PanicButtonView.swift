import SwiftUI

struct PanicButtonView: View {
    let appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var lang
    @State private var phase: PanicPhase = .breathing
    @State private var breathCount: Int = 0
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathTimer: Int = 4
    @State private var dhikrCount: Int = 0
    @State private var showResult: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var breathScale: CGFloat = 0.6
    @State private var breathOpacity: Double = 0.4

    private let ayahs = [
        ("فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", "For indeed, with hardship comes ease.", "Quran 94:5"),
        ("وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", "And your Lord is going to give you, and you will be satisfied.", "Quran 93:5"),
        ("إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", "Indeed, Allah is with the patient.", "Quran 2:153"),
        ("وَاصْبِرْ فَإِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ", "And be patient, for indeed Allah does not allow to be lost the reward of those who do good.", "Quran 11:115"),
    ]

    private var currentAyah: (String, String, String) {
        ayahs[breathCount % ayahs.count]
    }

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            GeometricAnimationBackground()
                .opacity(0.06)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .frame(width: 36, height: 36)
                            .background(NafsTheme.card)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                if showResult {
                    resultView
                } else if phase == .breathing {
                    breathingView
                } else if phase == .ayah {
                    ayahView
                } else {
                    dhikrView
                }

                Spacer()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onAppear { startBreathCycle() }
    }

    private var breathingView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text(L10n.text("Your nafs is being tested right now, \(appViewModel.userName).", "نفسك تُختبر الآن، \(appViewModel.userName)."))
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)
                Text(L10n.text("This moment will pass. You are stronger than this urge.", "هذه اللحظة ستمر. أنت أقوى من هذه الرغبة."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(breathOpacity))
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathScale)
                    .animation(.easeInOut(duration: 4), value: breathScale)

                Circle()
                    .strokeBorder(NafsTheme.gold.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)

                VStack(spacing: 4) {
                    Text(breathPhase.label)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                    Text("\(breathTimer)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                        .contentTransition(.numericText())
                }
            }

            Text(L10n.text("Breathe with intention. Say 'Allah' on each exhale.", "تنفس بنية. قل 'الله' مع كل زفير."))
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }

    private var ayahView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.fill")
                .font(.system(size: 32))
                .foregroundStyle(NafsTheme.gold)

            Text(currentAyah.0)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(NafsTheme.gold)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, 32)

            Text(currentAyah.1)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(currentAyah.2)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)

            Button {
                phase = .dhikr
            } label: {
                Text(L10n.text("Continue to dhikr →", "تابع إلى الذكر ←"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .padding(.top, 12)
        }
    }

    private var dhikrView: some View {
        VStack(spacing: 28) {
            Text("سُبْحَانَ ٱللَّهِ")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(NafsTheme.gold)

            Text(L10n.text("Tap to make dhikr", "اضغط للذكر"))
                .font(.system(.subheadline))
                .foregroundStyle(NafsTheme.subtleText)

            ZStack {
                Circle()
                    .stroke(NafsTheme.card, lineWidth: 6)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: min(CGFloat(dhikrCount) / 10.0, 1.0))
                    .stroke(NafsTheme.goldGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: dhikrCount)

                Text("\(dhikrCount)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .contentTransition(.numericText())
            }

            Button {
                dhikrCount += 1
                hapticTrigger += 1
                if dhikrCount >= 10 {
                    showResult = true
                    awardTokens()
                }
            } label: {
                Circle()
                    .fill(NafsTheme.goldGradient)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(.title3))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: NafsTheme.goldShadow, radius: 10, y: 3)
            }

            Text(L10n.text("\(10 - dhikrCount) remaining", "\(10 - dhikrCount) متبقي"))
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(NafsTheme.subtleText)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(NafsTheme.gold)
                .symbolEffect(.bounce)

            Text(L10n.text("MashaAllah, \(appViewModel.userName). You just earned 15 Hasanat by staying strong.", "ما شاء الله، \(appViewModel.userName). لقد كسبت ١٥ حسنة بصبرك."))
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(L10n.text("+15 Hasanat earned", "+١٥ حسنة مكتسبة"))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)

            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Text(L10n.text("I stayed strong — alhamdulillah", "صبرت — الحمد لله"))
                        Image(systemName: "checkmark")
                    }
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    dismiss()
                } label: {
                    Text(L10n.text("I opened the app anyway", "فتحت التطبيق على أي حال"))
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                Text(L10n.text("JazakAllah for being honest with yourself. Tomorrow is a new day.", "جزاك الله خيراً على صدقك مع نفسك. غداً يوم جديد."))
                    .font(.system(.caption))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    private func startBreathCycle() {
        breathPhase = .inhale
        breathTimer = 4
        breathScale = 1.0
        breathOpacity = 0.7

        Task {
            for bp in BreathPhase.allCases {
                breathPhase = bp
                switch bp {
                case .inhale:
                    breathScale = 1.0
                    breathOpacity = 0.7
                case .hold:
                    break
                case .exhale:
                    breathScale = 0.6
                    breathOpacity = 0.3
                }

                for t in stride(from: 4, through: 1, by: -1) {
                    breathTimer = t
                    hapticTrigger += 1
                    try? await Task.sleep(for: .seconds(1))
                }
            }
            phase = .ayah
        }
    }

    private func awardTokens() {
        appViewModel.hasanatBalance += 15
        appViewModel.transactions.insert(
            Transaction(title: "Panic Button completed", tokens: 15, isEarned: true, icon: "moon.circle.fill"),
            at: 0
        )
    }
}

private enum PanicPhase {
    case breathing, ayah, dhikr
}

private enum BreathPhase: CaseIterable {
    case inhale, hold, exhale

    var label: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
}

private struct GeometricAnimationBackground: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .stroke(NafsTheme.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 60 + CGFloat(i) * 50, height: 60 + CGFloat(i) * 50)
                    .rotationEffect(.degrees(rotation + Double(i) * 15))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
