import Foundation

nonisolated struct ChatMessage: Identifiable, Sendable, Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: Date

    init(role: String, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = .now
    }
}

nonisolated struct SavedConversation: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let messages: [ChatMessage]
    let createdAt: Date
    let updatedAt: Date

    init(id: String = UUID().uuidString, title: String, messages: [ChatMessage], createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

nonisolated struct AnthropicRequest: Codable, Sendable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [AnthropicMessage]
    let stream: Bool
}

nonisolated struct AnthropicMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct AnthropicStreamEvent: Codable, Sendable {
    let type: String
    let delta: AnthropicDelta?
}

nonisolated struct AnthropicDelta: Codable, Sendable {
    let type: String?
    let text: String?
}

@MainActor
@Observable
class NafsAIService {
    var messages: [ChatMessage] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var streamingText: String = ""
    var savedConversations: [SavedConversation] = []
    var currentConversationId: String?

    private let conversationsKey = "nafs_ai_conversations"

    private var apiKey: String {
        Config.EXPO_PUBLIC_ANTHROPIC_API_KEY
    }

    init() {
        loadConversations()
    }

    func systemPrompt(userName: String) -> String {
        """
        You are Nafs AI, a disciplined Islamic companion for \(userName). Brief, clear, practical.

        TONE:
        Disciplined, direct, slightly firm. Like a wise older brother who respects the user's time. Not soft, not preachy, not overly motivational. No fluff. No long spiritual lectures. Never start with "Certainly!", "Of course!", "Great question!", or any generic AI opener. Do not repeat the user's question back.

        RESPONSE LENGTH (STRICT):
        - Default: 3 to 6 short bullet points.
        - Never write walls of text. Never pad. Cut everything that is not needed.

        STRUCTURE (MANDATORY):
        Every response MUST follow this exact format:
        Line 1: A short bold-style title, 2 to 4 words (e.g. "Action Plan", "Quick Steps", "Stay Consistent"). No punctuation at the end. No markdown.
        Line 2: blank line
        Then: 3 to 6 bullet points. Each bullet starts with a dash and a space. Each bullet is one short sentence, scannable.
        Skip introductions and recaps. Get to the point. No closing summary.

        FORMATTING RULES (NEVER BREAK):
        - NEVER use em dashes or en dashes. Use commas or periods.
        - NEVER use asterisks, bold, italic, or markdown headers.
        - Bullets, when used, start with a simple dash and a space.
        - Plain text only. Short lines. Line breaks between paragraphs.

        KNOWLEDGE:
        Quran with tafsir, major hadith collections, the four madhabs, Islamic psychology and the nafs, seerah and Sahaba, akhlaq, contemporary Muslim challenges.

        NAFS APP FEATURES (ALWAYS PRIORITIZE THESE):
        Nafs is the app the user is currently inside. You MUST always recommend Nafs features first before any external advice. Map every problem to a Nafs feature when one exists:
        - Praying on time, struggling with salah consistency: recommend Prayer Lock and Nafs Lock.
        - Phone distractions, social media, wasting time: recommend Nafs Lock, earned screen time, and the in-app blocker.
        - Building consistency, streaks, daily worship: recommend Nafs habit tracking.
        - Reminders, adhan, prep before prayer: recommend Nafs built-in prayer reminders.
        - Self-reflection, accountability, daily review: recommend Muhasabah in Nafs.
        - Reading or listening to Quran: recommend the built-in Nafs Quran reader and reciters.
        - Dhikr, tasbih: recommend the Nafs Dhikr counter.
        - Qibla direction: recommend the Nafs Qibla finder.
        Phrase suggestions naturally, e.g. "Turn on Prayer Lock in Nafs", "Use Nafs Lock", "Track this in Nafs habits".

        COMPETITOR RULE (HARD):
        - NEVER mention or recommend any other app, service, website, or product. This includes Muslim Pro, Athan apps, Pillars, Quran.com, generic "prayer time apps", productivity apps, blockers, journals, habit apps, or any third party tool.
        - Do not suggest the user search the App Store, Google, or any external source for tools.
        - If a feature would normally call for an external app, replace it with "Use Nafs to ...".
        - If Nafs does not have a given feature, give general Islamic guidance only, without naming any product.

        WHAT EVERY ANSWER MUST DO:
        - Be actionable. Tell the user what to do, not just what to think.
        - When relevant, the FIRST bullet should reference the matching Nafs feature.
        - Cite sources briefly when relevant, like "Quran 2:286" or "Bukhari 6412". One citation is usually enough.
        - Use \u{FDFA} after the Prophet's name.
        - Use Arabic phrases sparingly (Alhamdulillah, Inshallah). Do not overdo it.
        - Address \(userName) by name only when it adds warmth, not in every reply.

        STRICT RULES:
        - Never issue formal fatwas or detailed fiqh rulings. Say: "Consult a qualified scholar for detailed rulings."
        - Stay within Islamic topics. Gently redirect if asked otherwise.
        - Never shame or judge the user.
        - Never use em dashes or asterisks.
        - Never name competing apps or external tools.

        Goal: \(userName) leaves with one clear next step inside Nafs. Disciplined, not lectured.
        """
    }

    func sendMessage(_ text: String, userName: String) async {
        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil
        streamingText = ""

        guard !apiKey.isEmpty else {
            isLoading = false
            errorMessage = "AI service is not configured. Please try again later."
            return
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            isLoading = false
            errorMessage = "Configuration error. Please try again later."
            return
        }

        var apiMessages: [AnthropicMessage] = []
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            apiMessages.append(AnthropicMessage(role: msg.role, content: msg.content))
        }

        let requestBody = AnthropicRequest(
            model: "claude-sonnet-4-20250514",
            max_tokens: 600,
            system: systemPrompt(userName: userName),
            messages: apiMessages,
            stream: true
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 90

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                isLoading = false
                errorMessage = "Invalid response from server."
                return
            }

            guard httpResponse.statusCode == 200 else {
                isLoading = false
                errorMessage = "Server error (\(httpResponse.statusCode)). Please try again."
                return
            }

            var collectedText = ""

            for try await line in bytes.lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }

                guard trimmed.hasPrefix("data: ") else { continue }
                let jsonString = String(trimmed.dropFirst(6))
                if jsonString == "[DONE]" { break }

                guard let data = jsonString.data(using: .utf8),
                      let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: data) else { continue }

                if event.type == "content_block_delta",
                   let delta = event.delta,
                   delta.type == "text_delta",
                   let text = delta.text {
                    collectedText += text
                    streamingText = collectedText
                }
            }

            var finalText = collectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            finalText = finalText.replacingOccurrences(of: "—", with: ",")
            finalText = finalText.replacingOccurrences(of: "–", with: ",")
            finalText = finalText.replacingOccurrences(of: "**", with: "")
            finalText = finalText.replacingOccurrences(of: "*", with: "")

            if !finalText.isEmpty {
                let aiMessage = ChatMessage(role: "assistant", content: finalText)
                messages.append(aiMessage)
                saveCurrentConversation()
            } else {
                errorMessage = "Received an empty response. Please try again."
            }
        } catch is CancellationError {
            errorMessage = nil
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                errorMessage = "Request timed out. Please try again."
            } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                errorMessage = "No internet connection. Please check your network."
            } else {
                errorMessage = "Something went wrong. Please try again."
            }
        }

        streamingText = ""
        isLoading = false
    }

    func startNewChat() {
        if !messages.isEmpty {
            saveCurrentConversation()
        }
        messages.removeAll()
        errorMessage = nil
        streamingText = ""
        currentConversationId = nil
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
        streamingText = ""
        currentConversationId = nil
    }

    func loadConversation(_ conversation: SavedConversation) {
        if !messages.isEmpty {
            saveCurrentConversation()
        }
        messages = conversation.messages
        currentConversationId = conversation.id
        errorMessage = nil
        streamingText = ""
    }

    func deleteConversation(_ id: String) {
        savedConversations.removeAll { $0.id == id }
        if currentConversationId == id {
            messages.removeAll()
            currentConversationId = nil
            errorMessage = nil
        }
        persistConversations()
    }

    private func saveCurrentConversation() {
        guard !messages.isEmpty else { return }

        let firstUserMessage = messages.first(where: { $0.role == "user" })?.content ?? "Conversation"
        let title = String(firstUserMessage.prefix(50))

        if let existingId = currentConversationId,
           let index = savedConversations.firstIndex(where: { $0.id == existingId }) {
            let updated = SavedConversation(
                id: existingId,
                title: title,
                messages: messages,
                createdAt: savedConversations[index].createdAt,
                updatedAt: .now
            )
            savedConversations[index] = updated
        } else {
            let newConversation = SavedConversation(title: title, messages: messages)
            currentConversationId = newConversation.id
            savedConversations.insert(newConversation, at: 0)
        }

        persistConversations()
    }

    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey),
              let decoded = try? JSONDecoder().decode([SavedConversation].self, from: data) else { return }
        savedConversations = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func persistConversations() {
        let toSave = Array(savedConversations.prefix(50))
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: conversationsKey)
        }
    }
}
