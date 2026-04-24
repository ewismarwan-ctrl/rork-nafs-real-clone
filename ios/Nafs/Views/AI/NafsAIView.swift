import SwiftUI

struct NafsAIView: View {
    let appViewModel: AppViewModel
    let storeViewModel: StoreViewModel
    var initialMessage: String? = nil
    @State private var service = NafsAIService()
    @State private var inputText: String = ""
    @State private var didSendInitial: Bool = false
    @State private var showHistory: Bool = false
    @FocusState private var isInputFocused: Bool
    @Environment(LanguageManager.self) private var lang

    private var suggestions: [String] {
        lang.isArabic ? [
            "كيف أتوقف عن تأخير الصلاة؟",
            "نفسي تغلبني على المعاصي",
            "كيف أترك عادة سيئة؟",
            "أريد التقرب من الله أكثر",
            "كيف أبدأ قيام الليل؟",
        ] : [
            "How do I stop delaying salah?",
            "My nafs keeps pulling me to sin",
            "How do I break a bad habit?",
            "I want to get closer to Allah",
            "How do I start praying tahajjud?",
        ]
    }

    var body: some View {
        NavigationStack {
            Group {
                if appViewModel.isPremium {
                    aiContent
                } else {
                    PremiumGateView(
                        icon: "brain.head.profile",
                        title: lang.isArabic ? "نفس AI" : "Nafs AI",
                        subtitle: lang.isArabic ? "مساعدك في المعرفة الإسلامية متاح على نفس بريميوم." : "Your Islamic knowledge companion is available on Nafs Premium.",
                        storeViewModel: storeViewModel
                    )
                }
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(lang.isArabic ? "نفس AI" : "Nafs AI")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let msg = initialMessage, !msg.isEmpty, !didSendInitial {
                    didSendInitial = true
                    await service.sendMessage(msg, userName: appViewModel.userName)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if appViewModel.isPremium {
                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if appViewModel.isPremium {
                        Button {
                            service.startNewChat()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(NafsTheme.gold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                ChatHistorySheet(service: service, isPresented: $showHistory)
                    .environment(lang)
            }
        }
    }

    private var aiContent: some View {
        VStack(spacing: 0) {
            if service.messages.isEmpty {
                emptyState
            } else {
                messageList
            }
            inputBar
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                CrescentStarMark(size: 60, color: NafsTheme.gold)

                VStack(spacing: 8) {
                    Text("\(lang.isArabic ? "السلام عليكم" : "Assalamu Alaikum"), \(appViewModel.userName)")
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(NafsTheme.text)
                    Text(lang.isArabic ? "مساعدك في المعرفة الإسلامية" : "Your Islamic knowledge companion")
                        .font(.system(.subheadline))
                        .foregroundStyle(NafsTheme.subtleText)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(lang.isArabic ? "اسألني أي شيء" : "Ask me anything")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(NafsTheme.subtleText)
                        .textCase(.uppercase)
                        .tracking(1)
                        .padding(.leading, 4)

                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            sendSuggestion(suggestion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkle")
                                    .font(.system(.caption))
                                    .foregroundStyle(NafsTheme.gold)
                                Text(suggestion)
                                    .font(.system(.subheadline))
                                    .foregroundStyle(NafsTheme.text)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: lang.isArabic ? "chevron.left" : "chevron.right")
                                    .font(.system(.caption2))
                                    .foregroundStyle(NafsTheme.subtleText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(NafsTheme.card)
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)

                if !service.savedConversations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.isArabic ? "المحادثات السابقة" : "Recent Chats")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(NafsTheme.subtleText)
                            .textCase(.uppercase)
                            .tracking(1)
                            .padding(.leading, 4)

                        ForEach(service.savedConversations.prefix(3)) { convo in
                            Button {
                                service.loadConversation(convo)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(.caption))
                                        .foregroundStyle(NafsTheme.gold)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(convo.title)
                                            .font(.system(.subheadline))
                                            .foregroundStyle(NafsTheme.text)
                                            .lineLimit(1)
                                        Text(convo.updatedAt, format: .dateTime.month().day().hour().minute())
                                            .font(.system(.caption2))
                                            .foregroundStyle(NafsTheme.subtleText)
                                    }
                                    Spacer()
                                    Image(systemName: lang.isArabic ? "chevron.left" : "chevron.right")
                                        .font(.system(.caption2))
                                        .foregroundStyle(NafsTheme.subtleText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(NafsTheme.card)
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 80)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(service.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if service.isLoading {
                        if !service.streamingText.isEmpty {
                            StreamingBubble(text: service.streamingText)
                                .id("streaming")
                        } else {
                            HStack(spacing: 6) {
                                TypingDots()
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .id("loading")
                        }
                    }

                    if let error = service.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.system(.caption))
                                .foregroundStyle(NafsTheme.subtleText)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .onChange(of: service.messages.count) { _, _ in
                withAnimation {
                    if let last = service.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: service.streamingText) { _, _ in
                withAnimation {
                    if !service.streamingText.isEmpty {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField(lang.isArabic ? "اسأل عن الإسلام..." : "Ask about Islam...", text: $inputText, axis: .vertical)
                    .font(.system(.body))
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendCurrentMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(NafsTheme.cardBorder, lineWidth: 1)
                    )

                Button {
                    sendCurrentMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(canSend ? NafsTheme.gold : NafsTheme.subtleText.opacity(0.4))
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(NafsTheme.background)
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !service.isLoading
    }

    private func sendCurrentMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        isInputFocused = false
        Task {
            await service.sendMessage(text, userName: appViewModel.userName)
        }
    }

    private func sendSuggestion(_ text: String) {
        Task {
            await service.sendMessage(text, userName: appViewModel.userName)
        }
    }
}

private struct ChatHistorySheet: View {
    let service: NafsAIService
    @Binding var isPresented: Bool
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        NavigationStack {
            Group {
                if service.savedConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundStyle(NafsTheme.subtleText.opacity(0.4))
                        Text(lang.isArabic ? "لا توجد محادثات بعد" : "No conversations yet")
                            .font(.system(.body))
                            .foregroundStyle(NafsTheme.subtleText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(service.savedConversations) { convo in
                            Button {
                                service.loadConversation(convo)
                                isPresented = false
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(convo.title)
                                        .font(.system(.body, weight: .medium))
                                        .foregroundStyle(NafsTheme.text)
                                        .lineLimit(2)
                                    HStack(spacing: 8) {
                                        Text("\(convo.messages.count) \(lang.isArabic ? "رسائل" : "messages")")
                                            .font(.system(.caption))
                                            .foregroundStyle(NafsTheme.subtleText)
                                        Text("·")
                                            .foregroundStyle(NafsTheme.subtleText)
                                        Text(convo.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                            .font(.system(.caption))
                                            .foregroundStyle(NafsTheme.subtleText)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let convo = service.savedConversations[index]
                                service.deleteConversation(convo.id)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(NafsTheme.background.ignoresSafeArea())
            .navigationTitle(lang.isArabic ? "المحادثات" : "Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.isArabic ? "تم" : "Done") {
                        isPresented = false
                    }
                    .foregroundStyle(NafsTheme.gold)
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(.body))
                    .foregroundStyle(isUser ? .white : NafsTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isUser ? AnyShapeStyle(NafsTheme.goldGradient) : AnyShapeStyle(NafsTheme.card))
                    .clipShape(.rect(cornerRadius: 18, style: .continuous))

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.system(.caption2))
                    .foregroundStyle(NafsTheme.subtleText.opacity(0.6))
                    .padding(.horizontal, 4)
            }
            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

private struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(.body))
                    .foregroundStyle(NafsTheme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(NafsTheme.card)
                    .clipShape(.rect(cornerRadius: 18, style: .continuous))
            }
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
    }
}

private struct TypingDots: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(NafsTheme.gold)
                    .frame(width: 7, height: 7)
                    .opacity(phase == index ? 1.0 : 0.3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(NafsTheme.card)
        .clipShape(.rect(cornerRadius: 18))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
