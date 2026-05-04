import SwiftUI
import UIKit

struct FirstPrayerRatingSheet: View {
    let onYes: () -> Void
    let onNotReally: () -> Void

    @Environment(LanguageManager.self) private var lang
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            ZStack {
                Circle()
                    .fill(NafsTheme.gold.opacity(0.10))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(NafsTheme.gold)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 10) {
                Text(lang.isArabic ? "هل يساعدك هذا على الصلاة في وقتها؟" : "Is this helping you pray on time?")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(NafsTheme.text)
                    .multilineTextAlignment(.center)

                Text(lang.isArabic
                     ? "أخبرنا برأيك. تقييمك الصادق يساعدنا على التحسين."
                     : "Let us know. Your honest feedback helps us improve.")
                    .font(.system(.subheadline))
                    .foregroundStyle(NafsTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 10) {
                NafsButton(title: lang.isArabic ? "نعم، يساعدني" : "Yes, it helps") {
                    onYes()
                }

                Button {
                    onNotReally()
                } label: {
                    Text(lang.isArabic ? "ليس فعلاً" : "Not really")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

struct FeedbackSheet: View {
    @Binding var text: String
    let onDismiss: () -> Void

    @Environment(LanguageManager.self) private var lang
    @FocusState private var isFocused: Bool
    @State private var sent: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(lang.isArabic ? "ساعدنا على التحسين" : "Help us improve")
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(lang.isArabic ? "ما الذي يمكننا تحسينه لنساعدك على الصلاة في وقتها؟" : "What could we improve to help you pray on time?")
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(lang.isArabic ? "اكتب ملاحظاتك هنا..." : "Type your feedback here...")
                            .foregroundStyle(NafsTheme.subtleText.opacity(0.6))
                            .padding(16)
                    }
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                }
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isFocused ? NafsTheme.gold : NafsTheme.cardBorder, lineWidth: isFocused ? 2 : 1)
                )
                .frame(minHeight: 160)
                .padding(.horizontal, 20)

                Spacer()

                NafsButton(
                    title: sent
                        ? (lang.isArabic ? "شكراً!" : "Thank you!")
                        : (lang.isArabic ? "إرسال" : "Send feedback"),
                    isEnabled: sent || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    sent = true
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        text = ""
                        sent = false
                        onDismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .background(NafsTheme.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}
