import SwiftUI

struct LanguageSelectionView: View {
    let languageManager: LanguageManager
    let onContinue: () -> Void
    @State private var selected: NafsLanguage = .english
    @State private var appeared: Bool = false
    @State private var cardsAppeared: Bool = false
    @State private var buttonAppeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(NafsTheme.gold.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "globe")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(NafsTheme.gold)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    }

                    Text("Choose your language")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(NafsTheme.text)

                    Text("اختر لغتك")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(NafsTheme.gold)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                HStack(spacing: 14) {
                    languageCard(
                        icon: "textformat.abc",
                        title: "English",
                        subtitle: "Continue in English",
                        language: .english
                    )

                    languageCard(
                        icon: "character.textbox",
                        title: "العربية",
                        subtitle: "تابع بالعربية",
                        language: .arabic
                    )
                }
                .padding(.horizontal, 24)
                .opacity(cardsAppeared ? 1 : 0)
                .offset(y: cardsAppeared ? 0 : 16)
            }

            Spacer()
            Spacer()

            NafsButton(title: selected == .arabic ? "تابع" : "Continue") {
                languageManager.switchTo(selected)
                onContinue()
            }
            .padding(.horizontal, 24)
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)

            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.35)) {
                cardsAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                buttonAppeared = true
            }
        }
    }

    private func languageCard(icon: String, title: String, subtitle: String, language: NafsLanguage) -> some View {
        let isSelected = selected == language
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selected = language
            }
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? NafsTheme.gold.opacity(0.15) : NafsTheme.gold.opacity(0.06))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(NafsTheme.gold)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: language == .arabic ? .default : .serif))
                        .foregroundStyle(NafsTheme.text)

                    Text(subtitle)
                        .font(.system(.caption))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(NafsTheme.gold)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .strokeBorder(NafsTheme.cardBorder, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .background(isSelected ? NafsTheme.gold.opacity(0.08) : NafsTheme.card)
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}
