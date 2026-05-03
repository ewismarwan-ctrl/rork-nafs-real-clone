import SwiftUI
import MessageUI
import UIKit

struct PrayerRatingPromptSheet: View {
    let onDismiss: () -> Void
    @State private var appeared: Bool = false
    @State private var showFeedbackSheet: Bool = false
    @State private var feedbackText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(NafsTheme.goldGradient)
                    .scaleEffect(appeared ? 1 : 0.6)
            }

            Spacer().frame(height: 22)

            VStack(spacing: 12) {
                Text(L10n.text("Is this helping you pray on time?", "هل يساعدك هذا على الصلاة في وقتها؟"))
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(L10n.text("Your honest answer helps us improve Nafs for every Muslim.", "إجابتك الصادقة تساعدنا على تطوير نفس لكل مسلم."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            Spacer()

            VStack(spacing: 12) {
                NafsButton(title: L10n.text("Yes", "نعم")) {
                    RatingService.shared.requestReview()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onDismiss()
                    }
                }

                Button {
                    showFeedbackSheet = true
                } label: {
                    Text(L10n.text("Not really", "ليس فعلاً"))
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(NafsTheme.background)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackSheet(feedbackText: $feedbackText) {
                showFeedbackSheet = false
                onDismiss()
            }
            .presentationDetents([.medium])
        }
    }
}

private struct FeedbackSheet: View {
    @Binding var feedbackText: String
    let onDone: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(NafsTheme.cardBorder)
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text(L10n.text("What can we improve?", "ما الذي يمكننا تحسينه؟"))
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                Text(L10n.text("Tell us what isn’t working for you.", "أخبرنا بما لا يعمل بالنسبة لك."))
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
            }

            TextEditor(text: $feedbackText)
                .focused($focused)
                .frame(minHeight: 120)
                .padding(12)
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
                )

            NafsButton(title: L10n.text("Send Feedback", "إرسال الملاحظة")) {
                sendFeedback()
                onDone()
            }

            Button {
                onDone()
            } label: {
                Text(L10n.text("Cancel", "إلغاء"))
                    .font(.system(.footnote, weight: .medium))
                    .foregroundStyle(NafsTheme.subtleText)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(NafsTheme.background)
        .onAppear { focused = true }
    }

    private func sendFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let subject = "Nafs Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:hello@nafs.app?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }
}
