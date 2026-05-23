import SwiftUI

struct OnboardingContainerView: View {
    let storeViewModel: StoreViewModel
    let languageManager: LanguageManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page: Int = 0

    private let pages: [(title: String, subtitle: String)] = [
        ("You were never meant to scroll all day.", "Nafs is built for Muslims who want their attention back."),
        ("Worship first. Dopamine later.", "Salah, Quran, Dhikr, Reflection, and Focus become the path to intentional screen time."),
        ("Earn your screen time through discipline.", "Every completed action creates earned minutes you can spend intentionally."),
        ("Lock distractions until you earn them.", "Choose the apps that control you. Unlock them after discipline, not impulse."),
        ("Control your nafs before it controls you.", "Start earning freedom with a sharper system for your day.")
    ]

    var body: some View {
        ZStack {
            NafsTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                VStack(alignment: .leading, spacing: 18) {
                    Text("NAFS")
                        .font(.system(.caption, weight: .black))
                        .tracking(4)
                        .foregroundStyle(NafsTheme.gold)
                    Text(pages[page].title)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(NafsTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(pages[page].subtitle)
                        .font(.system(.title3, weight: .medium))
                        .foregroundStyle(NafsTheme.subtleText)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 30))
                .overlay { RoundedRectangle(cornerRadius: 30).strokeBorder(NafsTheme.gold.opacity(0.22), lineWidth: 1) }

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? NafsTheme.gold : NafsTheme.cardBorder)
                            .frame(width: index == page ? 28 : 8, height: 8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)

                Button {
                    if page < pages.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { page += 1 }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Start earning freedom" : "Continue")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(NafsTheme.goldGradient)
                        .clipShape(.rect(cornerRadius: 18))
                }
                Spacer()
            }
            .padding(20)
        }
    }
}
