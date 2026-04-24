import Foundation

nonisolated struct MuhasabahEntry: Identifiable, Codable, Sendable {
    let id: String
    let date: Date
    let gratitude: String
    let struggle: String
    let tomorrow: String
    let mood: MuhasabahMood

    init(gratitude: String, struggle: String, tomorrow: String, mood: MuhasabahMood) {
        self.id = UUID().uuidString
        self.date = Date()
        self.gratitude = gratitude
        self.struggle = struggle
        self.tomorrow = tomorrow
        self.mood = mood
    }
}

nonisolated enum MuhasabahMood: String, Codable, CaseIterable, Sendable {
    case peaceful = "Peaceful"
    case grateful = "Grateful"
    case struggling = "Struggling"
    case heavy = "Heavy"
    case hopeful = "Hopeful"

    var arabic: String {
        switch self {
        case .peaceful: return "مطمئنة"
        case .grateful: return "شاكرة"
        case .struggling: return "مجاهدة"
        case .heavy: return "ثقيلة"
        case .hopeful: return "راجية"
        }
    }
}
