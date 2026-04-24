import SwiftUI

struct InsightScreen1View: View {
    let vm: OnboardingViewModel
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    VStack(spacing: 16) {
                        Text(NafsStrings.insight1Title.localized)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)

                        Text(NafsStrings.insight1Body.localized)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        Rectangle()
                            .fill(NafsTheme.gold.opacity(0.3))
                            .frame(width: 40, height: 1)

                        Text(NafsStrings.insight1Card.localized)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(NafsTheme.gold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 16))

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            NafsButton(title: NafsStrings.thatEndsToday.localized) {
                vm.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct InsightScreen2View: View {
    let vm: OnboardingViewModel

    var body: some View {
        InsightCardLayout(
            stat: NafsStrings.insight2Stat.localized,
            statLabel: NafsStrings.insight2Label.localized,
            statSubtext: NafsStrings.insight2Sub.localized,
            quote: NafsStrings.insight2Quote.localized,
            attribution: NafsStrings.insight2Attr.localized,
            ctaText: NafsStrings.iWantBetterSalah.localized,
            onContinue: { vm.goNext() }
        )
    }
}

struct InsightScreen3View: View {
    let vm: OnboardingViewModel

    var body: some View {
        InsightCardLayout(
            stat: NafsStrings.insight3Stat.localized,
            statLabel: NafsStrings.insight3Label.localized,
            statSubtext: NafsStrings.insight3Sub.localized,
            quote: NafsStrings.insight3Quote.localized,
            attribution: NafsStrings.insight3Attr.localized,
            ctaText: NafsStrings.iNeedThis.localized,
            onContinue: { vm.goNext() }
        )
    }
}

struct InsightCardLayout: View {
    let stat: String
    let statLabel: String
    let statSubtext: String
    let quote: String
    let attribution: String?
    let ctaText: String
    let onContinue: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    VStack(spacing: 4) {
                        Text(stat)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(NafsTheme.gold)
                        Text(statLabel)
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(NafsTheme.text)
                            .minimumScaleFactor(0.85)
                        Text(statSubtext)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        Rectangle()
                            .fill(NafsTheme.gold.opacity(0.3))
                            .frame(width: 40, height: 1)

                        Text("\"" + quote + "\"")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)

                        if let attr = attribution {
                            Text("— \(attr)")
                                .font(.system(.footnote, weight: .medium))
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
                    .padding(20)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 16))

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            NafsButton(title: ctaText) {
                onContinue()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct InsightBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(.title3))
                .foregroundStyle(NafsTheme.gold)
                .frame(width: 32)
            Text(text)
                .font(.system(.body))
                .foregroundStyle(NafsTheme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 16))
    }
}
