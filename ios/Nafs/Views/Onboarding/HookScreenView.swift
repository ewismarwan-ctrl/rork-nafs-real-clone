import SwiftUI

struct HookScreenView: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    VStack(spacing: 24) {
                        (Text(NafsStrings.onboardingHookTitle1.localized)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text) +
                        Text(NafsStrings.onboardingHookEveryPart.localized)
                            .font(.system(.title3, weight: .heavy))
                            .foregroundStyle(NafsTheme.gold) +
                        Text(NafsStrings.onboardingHookTitle2.localized)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text))
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                    Spacer(minLength: 24)

                    Text(NafsStrings.onboardingHookBody.localized)
                        .font(.system(.body))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }

            NafsButton(title: NafsStrings.showMe.localized) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
    }
}
