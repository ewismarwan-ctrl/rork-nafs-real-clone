import SwiftUI

struct PremiumGateModal: View {
    let feature: String
    let benefit: String
    let onDismiss: () -> Void
    let onStartTrial: () -> Void
    var onPurchase: (() async -> Bool)? = nil
    @State private var isPurchasing: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundStyle(NafsTheme.gold)
                .padding(16)
                .background(NafsTheme.gold.opacity(0.1))
                .clipShape(Circle())

            VStack(spacing: 8) {
                Text(feature)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(benefit)
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
            }

            NafsButton(title: L10n.text("Start Free Trial →", "ابدأ تجربتك المجانية →"), isLoading: isPurchasing) {
                guard !isPurchasing else { return }
                if let purchase = onPurchase {
                    isPurchasing = true
                    Task {
                        let success = await purchase()
                        isPurchasing = false
                        if success {
                            onStartTrial()
                        }
                    }
                } else {
                    onStartTrial()
                }
            }


            Button {
                onDismiss()
            } label: {
                Text(L10n.text("Not now", "ليس الآن"))
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }
}

struct PremiumLockedOverlay: View {
    let message: String
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(NafsTheme.gold)

            Text(message)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(NafsTheme.text)
                .multilineTextAlignment(.center)

            Button(action: onTap) {
                Text(L10n.text("Start Free Trial →", "ابدأ تجربتك المجانية →"))
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(NafsTheme.goldGradient)
                    .clipShape(.capsule)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
