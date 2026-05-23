import SwiftUI
import StoreKit
import UIKit

struct RatingPromptScreenView: View {
    let vm: OnboardingViewModel
    @Environment(LanguageManager.self) private var lang
    @State private var appeared: Bool = false
    @State private var starAppeared: [Bool] = Array(repeating: false, count: 5)
    @State private var hapticTrigger: Int = 0

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer().frame(height: 12)

                ZStack {
                    Circle()
                        .fill(NafsTheme.gold.opacity(0.10))
                        .frame(width: 116, height: 116)
                    Image(systemName: "star.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                        .scaleEffect(appeared ? 1.0 : 0.6)
                        .opacity(appeared ? 1 : 0)
                }

                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(NafsTheme.goldGradient)
                            .scaleEffect(starAppeared[i] ? 1.0 : 0.4)
                            .opacity(starAppeared[i] ? 1 : 0)
                    }
                }

                VStack(spacing: 12) {
                    Text(lang.isArabic ? "هل تستمتع بنفس حتى الآن؟" : "Enjoying Nafs so far?")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                        .multilineTextAlignment(.center)

                    Text(lang.isArabic
                         ? "تقييمك يساعدنا على الوصول إلى المزيد من المسلمين وتحسين التطبيق."
                         : "Your rating helps us reach more Muslims and improve the app.")
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 28)
                }

                Spacer()

                VStack(spacing: 12) {
                    NafsButton(title: lang.isArabic ? "قيّم نفس" : "Rate Nafs") {
                        hapticTrigger += 1
                        RatingService.shared.requestReview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            vm.goNext()
                        }
                    }

                    Button {
                        vm.goNext()
                    } label: {
                        Text(lang.isArabic ? "ربما لاحقاً" : "Maybe Later")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .sensoryFeedback(.success, trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                appeared = true
            }
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.08) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        starAppeared[i] = true
                    }
                }
            }
        }
    }

}
