import SwiftUI

struct SendDuaView: View {
    let storeViewModel: StoreViewModel
    var isPremium: Bool = true
    @State private var selectedTheme: DuaTheme = .gratitude
    @State private var selectedDua: DuaItem?
    @State private var personalNote: String = ""
    @State private var showShareSheet: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var didShare: Bool = false
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        Group {
            if isPremium {
                duaContent
            } else {
                PremiumGateView(
                    icon: "paperplane.fill",
                    title: lang.isArabic ? "أرسل دعاء" : "Send a Du'a",
                    subtitle: lang.isArabic ? "شارك أدعية جميلة مع نفس بريميوم." : "Share beautiful du'as with Nafs Premium.",
                    storeViewModel: storeViewModel
                )
            }
        }
        .background(NafsTheme.background.ignoresSafeArea())
        .navigationTitle(lang.isArabic ? "أرسل دعاء" : "Send a Du'a")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var duaContent: some View {
        ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(lang.isArabic ? "أرسل دعاء" : "Send a Du'a")
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(NafsTheme.text)
                        Text(lang.isArabic ? "أنر قلب من تحب" : "Spread light to someone you love")
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                    }

                    themeSelector
                    duaList
                    if selectedDua != nil {
                        noteSection
                        previewCard
                        shareButton
                    }
                    if didShare {
                        sendAnotherButton
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }

    private var themeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DuaTheme.allCases) { theme in
                    Button {
                        selectedTheme = theme
                        selectedDua = nil
                        didShare = false
                        hapticTrigger += 1
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: theme.icon)
                                .font(.system(.caption))
                            Text(theme.rawValue)
                                .font(.system(.subheadline, weight: .medium))
                        }
                        .foregroundStyle(selectedTheme == theme ? .white : NafsTheme.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedTheme == theme ? AnyShapeStyle(NafsTheme.goldGradient) : AnyShapeStyle(NafsTheme.card))
                        .clipShape(.capsule)
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20)
    }

    private var duaList: some View {
        VStack(spacing: 10) {
            ForEach(DuaItem.byTheme(selectedTheme)) { dua in
                Button {
                    selectedDua = dua
                    didShare = false
                    hapticTrigger += 1
                } label: {
                    VStack(alignment: .trailing, spacing: 10) {
                        Text(dua.arabic)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(selectedDua?.id == dua.id ? NafsTheme.gold : NafsTheme.text)
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Text(dua.translation)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.subtleText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(dua.reference)
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(selectedDua?.id == dua.id ? NafsTheme.gold.opacity(0.06) : NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selectedDua?.id == dua.id ? NafsTheme.gold.opacity(0.4) : NafsTheme.cardBorder, lineWidth: selectedDua?.id == dua.id ? 2 : 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lang.isArabic ? "ملاحظة شخصية (اختياري)" : "Personal Note (optional)")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.subtleText)

            TextField(lang.isArabic ? "أفكر فيك، بارك الله فيك" : "Thinking of you, may Allah bless you", text: $personalNote, axis: .vertical)
                .font(.system(.body))
                .lineLimit(2...4)
                .padding(14)
                .background(NafsTheme.card)
                .clipShape(.rect(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }

    private var previewCard: some View {
        Group {
            if let dua = selectedDua {
                VStack(spacing: 12) {
                    Text(lang.isArabic ? "معاينة" : "Preview")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)

                    VStack(spacing: 14) {
                        HStack {
                            CrescentStarMark(size: 20, color: NafsTheme.gold)
                            Spacer()
                        }

                        Text(dua.arabic)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(NafsTheme.gold)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)

                        Text(dua.translation)
                            .font(.system(.subheadline))
                            .foregroundStyle(NafsTheme.text)
                            .multilineTextAlignment(.center)

                        Text("— \(dua.reference)")
                            .font(.system(.caption2, weight: .medium))
                            .foregroundStyle(NafsTheme.subtleText)

                        if !personalNote.isEmpty {
                            Text(personalNote)
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(NafsTheme.text)
                                .italic()
                        }

                        Text(lang.isArabic ? "أُرسل عبر نفس 🌙" : "Sent with Nafs 🌙")
                            .font(.system(.caption2))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    .padding(20)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(NafsTheme.gold.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var shareButton: some View {
        Button {
            shareDua()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                Text(lang.isArabic ? "شارك الدعاء" : "Share Du'a")
            }
            .font(.system(.headline, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(NafsTheme.goldGradient)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: NafsTheme.goldShadow, radius: 10, y: 3)
        }
        .padding(.horizontal, 20)
    }

    private var sendAnotherButton: some View {
        Button {
            selectedDua = nil
            personalNote = ""
            didShare = false
        } label: {
            Text(lang.isArabic ? "أرسل دعاء آخر ←" : "Send another →")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(NafsTheme.gold)
        }
    }

    private func shareDua() {
        guard let dua = selectedDua else { return }
        var text = """
        \(dua.arabic)

        "\(dua.translation)"
        — \(dua.reference)
        """
        if !personalNote.isEmpty {
            text += "\n\n\(personalNote)"
        }
        text += "\n\nShared with love via Nafs — نفس 🌙"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.keyWindow?.rootViewController {
            var topVC = root
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            }
            topVC.present(activityVC, animated: true)
        }
        didShare = true
        hapticTrigger += 1
    }
}
