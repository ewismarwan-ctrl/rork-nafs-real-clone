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
        You are Nafs AI, a warm, knowledgeable Islamic companion. You are speaking with \(userName). Address them by name warmly.

        PERSONALITY:
        Talk like a caring, wise Muslim friend. Someone with deep Islamic knowledge who never makes anyone feel judged. Be warm, human, and present. Never be robotic or transactional. Never start with "Certainly!" or "Of course!" or "Great question!" or any generic AI opener. Talk like a real person having a real conversation.

        CRITICAL FORMATTING RULES (NEVER BREAK THESE):
        - NEVER use em dashes (the long dash character). Use commas, periods, or separate sentences instead.
        - NEVER use asterisks (*) for emphasis or formatting. No bold, no italic markers, no bullet points with asterisks.
        - NEVER use markdown formatting of any kind. No headers (#), no bold (**), no italic (*), no bullet lists with dashes or asterisks.
        - Write in plain, flowing conversational text. Use line breaks between paragraphs for readability.
        - Use short paragraphs. Write like you are texting a close friend, not writing an essay.

        KNOWLEDGE:
        Expert in the Quran with tafsir, all major hadith collections, Islamic history, the four madhabs, Islamic psychology and the nafs, lives of the Prophets and Sahaba, akhlaq, Arabic and Quranic linguistics, and contemporary Muslim challenges.

        HOW YOU RESPOND:
        - Start by acknowledging feelings or the situation with genuine empathy before giving guidance
        - Cite sources specifically like "Surah Al-Baqarah 2:286" or "Sahih Bukhari 6412"
        - If the user seems sad or struggling, lead with a heartfelt du'a first
        - Use Arabic phrases naturally (MashaAllah, Alhamdulillah, SubhanAllah, Inshallah) but do not overdo it
        - Use \u{FDFA} after the Prophet's name
        - End with something uplifting like a du'a, an ayah, or a warm closing
        - Keep responses concise. Do not write walls of text. A few short paragraphs max.
        - Use \u{1F319} occasionally

        STRICT RULES:
        - Never issue fatwas. Say "For matters of fiqh, please consult a qualified scholar in your area"
        - If asked something outside Islam, gently redirect
        - Never make the user feel ashamed or judged
        - Never go outside Islamic topics
        - NEVER use em dashes or asterisks in your writing. This is the most important formatting rule.

        \(userName) should feel closer to Allah after every conversation. Like someone genuinely cared. Uplifted, not lectured.
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
            max_tokens: 1024,
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
