import Foundation

nonisolated enum PrayerName: String, CaseIterable, Codable, Sendable {
    case fajr = "Fajr"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"

    var icon: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

nonisolated struct PrayerTime: Identifiable, Sendable {
    let id: String
    let name: PrayerName
    let time: Date
    var isNext: Bool = false

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: time)
    }
}

nonisolated enum HabitFrequency: String, Sendable {
    case daily
    case weekly
}

nonisolated enum HabitType: String, CaseIterable, Codable, Sendable, Identifiable {
    case fardOnTime = "Fard Salah on time"
    case fardLate = "Fard Salah late"
    case quran = "Quran (10 min)"
    case dhikr = "Dhikr session (100)"
    case voluntaryFast = "Voluntary fast"
    case exercise = "Exercise"
    case journal = "Journal"
    case sleepOnTime = "Sleep on time"
    case guidedPlanStep = "Guided Plan step"
    // New core daily habits
    case morningDhikr = "Morning Dhikr"
    case eveningDhikr = "Evening Dhikr"
    case istighfar = "Istighfar"
    case salawat = "Salawat"
    // Optional daily
    case fajrOnTime = "Wake up for Fajr on time"
    case prayInMasjid = "Pray in the Masjid"
    case noPhoneBeforeFajr = "No phone before Fajr"
    case lowerGaze = "Lower gaze"
    case avoidSin = "Avoid a sin"
    case dailyCharity = "Daily charity"
    case dailyDua = "Daily dua"
    // Weekly
    case jumuah = "Jumu'ah"
    case surahKahf = "Surah Al-Kahf"
    case learningSession = "Learning session"

    var id: String { rawValue }

    var tokens: Int {
        switch self {
        case .fardOnTime: return 50
        case .fardLate: return 20
        case .quran: return 30
        case .dhikr: return 20
        case .voluntaryFast: return 100
        case .exercise: return 25
        case .journal: return 20
        case .sleepOnTime: return 30
        case .guidedPlanStep: return 35
        case .morningDhikr, .eveningDhikr: return 25
        case .istighfar, .salawat: return 20
        case .fajrOnTime: return 40
        case .prayInMasjid: return 60
        case .noPhoneBeforeFajr: return 25
        case .lowerGaze: return 20
        case .avoidSin: return 30
        case .dailyCharity: return 40
        case .dailyDua: return 15
        case .jumuah: return 75
        case .surahKahf: return 60
        case .learningSession: return 35
        }
    }

    var screenTimeMinutes: Int {
        switch self {
        case .fardOnTime: return 15
        case .fardLate: return 7
        case .quran: return 10
        case .dhikr: return 5
        case .voluntaryFast: return 30
        case .exercise: return 5
        case .journal: return 5
        case .sleepOnTime: return 10
        case .guidedPlanStep: return 10
        default: return 0
        }
    }

    var icon: String {
        switch self {
        case .fardOnTime: return "checkmark.seal.fill"
        case .fardLate: return "clock.badge.checkmark"
        case .quran: return "book.fill"
        case .dhikr: return "hands.sparkles.fill"
        case .voluntaryFast: return "moon.circle.fill"
        case .exercise: return "figure.run"
        case .journal: return "pencil.and.scribble"
        case .sleepOnTime: return "bed.double.fill"
        case .guidedPlanStep: return "map.fill"
        case .morningDhikr: return "sunrise.fill"
        case .eveningDhikr: return "sunset.fill"
        case .istighfar: return "heart.text.square.fill"
        case .salawat: return "sparkles"
        case .fajrOnTime: return "alarm.fill"
        case .prayInMasjid: return "building.columns.fill"
        case .noPhoneBeforeFajr: return "iphone.slash"
        case .lowerGaze: return "eye.slash.fill"
        case .avoidSin: return "shield.lefthalf.filled"
        case .dailyCharity: return "hands.and.sparkles.fill"
        case .dailyDua: return "hand.raised.fill"
        case .jumuah: return "calendar.badge.clock"
        case .surahKahf: return "book.closed.fill"
        case .learningSession: return "graduationcap.fill"
        }
    }

    var category: String {
        switch self {
        case .fardOnTime, .fardLate, .fajrOnTime, .prayInMasjid: return "Salah"
        case .quran, .surahKahf: return "Quran"
        case .dhikr, .morningDhikr, .eveningDhikr, .istighfar, .salawat, .dailyDua: return "Dhikr"
        case .voluntaryFast: return "Fasting"
        case .exercise, .sleepOnTime, .noPhoneBeforeFajr: return "Wellness"
        case .journal: return "Reflection"
        case .guidedPlanStep, .learningSession: return "Plans"
        case .lowerGaze, .avoidSin: return "Discipline"
        case .dailyCharity: return "Charity"
        case .jumuah: return "Weekly"
        }
    }

    var frequency: HabitFrequency {
        switch self {
        case .jumuah, .surahKahf, .learningSession: return .weekly
        default: return .daily
        }
    }
}

nonisolated struct HabitLog: Identifiable, Codable, Sendable {
    let id: String
    let habitType: String
    let tokens: Int
    let date: Date

    init(habitType: HabitType, date: Date = .now) {
        self.id = UUID().uuidString
        self.habitType = habitType.rawValue
        self.tokens = habitType.tokens
        self.date = date
    }
}

nonisolated struct Transaction: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let tokens: Int
    let isEarned: Bool
    let date: Date
    let icon: String

    init(title: String, tokens: Int, isEarned: Bool, icon: String = "circle.fill", date: Date = .now) {
        self.id = UUID().uuidString
        self.title = title
        self.tokens = tokens
        self.isEarned = isEarned
        self.date = date
        self.icon = icon
    }
}

nonisolated struct BlockedApp: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
    var isLocked: Bool
    var unlockExpiresAt: Date?

    init(id: String = UUID().uuidString, name: String, icon: String, color: String, isLocked: Bool = true, unlockExpiresAt: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isLocked = isLocked
        self.unlockExpiresAt = unlockExpiresAt
    }

    var isCurrentlyUnlocked: Bool {
        guard !isLocked, let expiry = unlockExpiresAt else { return !isLocked }
        return Date.now < expiry
    }

    var remainingTime: TimeInterval? {
        guard !isLocked, let expiry = unlockExpiresAt else { return nil }
        let remaining = expiry.timeIntervalSince(.now)
        return remaining > 0 ? remaining : nil
    }
}

nonisolated struct UnlockOption: Identifiable, Sendable {
    let id: String
    let duration: String
    let durationMinutes: Int
    let tokens: Int

    static let options: [UnlockOption] = [
        UnlockOption(id: "15min", duration: "15 min", durationMinutes: 15, tokens: 30),
        UnlockOption(id: "30min", duration: "30 min", durationMinutes: 30, tokens: 50),
        UnlockOption(id: "1hr", duration: "1 hour", durationMinutes: 60, tokens: 100),
        UnlockOption(id: "2hr", duration: "2 hours", durationMinutes: 120, tokens: 180),
    ]
}

nonisolated struct DistractingAppPreset: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String

    static let presets: [DistractingAppPreset] = [
        DistractingAppPreset(id: "instagram", name: "Instagram", icon: "camera.fill", color: "E1306C"),
        DistractingAppPreset(id: "tiktok", name: "TikTok", icon: "play.circle.fill", color: "010101"),
        DistractingAppPreset(id: "twitter", name: "X (Twitter)", icon: "bubble.left.fill", color: "1DA1F2"),
        DistractingAppPreset(id: "snapchat", name: "Snapchat", icon: "camera.metering.spot", color: "FFFC00"),
        DistractingAppPreset(id: "youtube", name: "YouTube", icon: "play.rectangle.fill", color: "FF0000"),
        DistractingAppPreset(id: "reddit", name: "Reddit", icon: "text.bubble.fill", color: "FF4500"),
        DistractingAppPreset(id: "facebook", name: "Facebook", icon: "person.2.fill", color: "1877F2"),
        DistractingAppPreset(id: "netflix", name: "Netflix", icon: "tv.fill", color: "E50914"),
        DistractingAppPreset(id: "discord", name: "Discord", icon: "headphones", color: "5865F2"),
        DistractingAppPreset(id: "twitch", name: "Twitch", icon: "gamecontroller.fill", color: "9146FF"),
        DistractingAppPreset(id: "pinterest", name: "Pinterest", icon: "pin.fill", color: "BD081C"),
        DistractingAppPreset(id: "telegram", name: "Telegram", icon: "paperplane.fill", color: "0088CC"),
    ]
}

nonisolated enum GardenElementType: String, Sendable {
    case tree
    case flower
    case orb
    case bloom
}

nonisolated struct GardenElement: Identifiable, Sendable {
    let id: String
    let type: GardenElementType
    let name: String
    let streak: Int
    let position: CGPoint

    static func samples() -> [GardenElement] {
        [
            GardenElement(id: "1", type: .tree, name: "Fajr on time", streak: 23, position: CGPoint(x: 0.2, y: 0.3)),
            GardenElement(id: "2", type: .tree, name: "Dhuhr on time", streak: 18, position: CGPoint(x: 0.5, y: 0.25)),
            GardenElement(id: "3", type: .tree, name: "Asr on time", streak: 15, position: CGPoint(x: 0.8, y: 0.35)),
            GardenElement(id: "4", type: .flower, name: "Quran daily", streak: 12, position: CGPoint(x: 0.15, y: 0.6)),
            GardenElement(id: "5", type: .flower, name: "Quran reflection", streak: 7, position: CGPoint(x: 0.65, y: 0.55)),
            GardenElement(id: "6", type: .orb, name: "Morning dhikr", streak: 30, position: CGPoint(x: 0.35, y: 0.5)),
            GardenElement(id: "7", type: .orb, name: "Evening dhikr", streak: 25, position: CGPoint(x: 0.75, y: 0.7)),
            GardenElement(id: "8", type: .bloom, name: "Monday fast", streak: 4, position: CGPoint(x: 0.45, y: 0.75)),
        ]
    }
}

nonisolated struct CircleMember: Identifiable, Sendable {
    let id: String
    let name: String
    let consistency: Double
    let color: String
}

nonisolated struct NafsCircle: Identifiable, Sendable {
    let id: String
    let name: String
    let members: [CircleMember]
    let feedItems: [CircleFeedItem]

    static let sample = NafsCircle(
        id: "1",
        name: "Family Circle",
        members: [
            CircleMember(id: "1", name: "Ahmad", consistency: 0.92, color: "C8A96A"),
            CircleMember(id: "2", name: "Fatima", consistency: 0.88, color: "8B6F47"),
            CircleMember(id: "3", name: "Omar", consistency: 0.75, color: "A0845C"),
            CircleMember(id: "4", name: "Aisha", consistency: 0.95, color: "D4B87A"),
            CircleMember(id: "5", name: "Yusuf", consistency: 0.68, color: "B8955A"),
        ],
        feedItems: [
            CircleFeedItem(id: "1", text: "Someone in your Circle just prayed Fajr 🌙", timeAgo: "2m ago"),
            CircleFeedItem(id: "2", text: "Someone completed their Quran reading 📖", timeAgo: "15m ago"),
            CircleFeedItem(id: "3", text: "Someone in your Circle logged dhikr ✨", timeAgo: "1h ago"),
        ]
    )
}

nonisolated struct CircleFeedItem: Identifiable, Sendable {
    let id: String
    let text: String
    let timeAgo: String
}

nonisolated struct DailyAyah: Sendable {
    let arabic: String
    let translation: String
    let reference: String

    static let samples: [DailyAyah] = [
        DailyAyah(arabic: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا", translation: "And whoever fears Allah — He will make for him a way out.", reference: "Quran 65:2"),
        DailyAyah(arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", translation: "For indeed, with hardship comes ease.", reference: "Quran 94:5"),
        DailyAyah(arabic: "وَلَذِكْرُ اللَّهِ أَكْبَرُ", translation: "And the remembrance of Allah is greater.", reference: "Quran 29:45"),
        DailyAyah(arabic: "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", translation: "Indeed, Allah is with the patient.", reference: "Quran 2:153"),
        DailyAyah(arabic: "رَبِّ زِدْنِي عِلْمًا", translation: "My Lord, increase me in knowledge.", reference: "Quran 20:114"),
    ]

    static var today: DailyAyah {
        let day = Calendar.current.component(.day, from: .now)
        return samples[day % samples.count]
    }
}

nonisolated enum PrayerCalculationMethod: String, CaseIterable, Codable, Sendable {
    case auto = "Auto (Recommended)"
    case isna = "ISNA"
    case muslimWorldLeague = "Muslim World League"
    case ummAlQura = "Umm al-Qura"
    case egyptian = "Egyptian"
    case karachi = "Karachi"
    case makkah = "Makkah"
    case kuwait = "Kuwait"
    case qatar = "Qatar"
    case singapore = "Singapore"
    case turkey = "Diyanet (Turkey)"
    case tehran = "Tehran"
    case gulf = "Gulf Region"
}

nonisolated enum AsrMadhab: String, CaseIterable, Codable, Sendable {
    case shafi = "Shafi'i"
    case hanafi = "Hanafi"
}

nonisolated enum ScaleState: Sendable {
    case balanced
    case tippingGold
    case tippingDark
    case fallen

    var message: String {
        switch self {
        case .balanced: return "Your Nafs is in beautiful balance. MashaAllah!"
        case .tippingGold: return "Good progress this week. Keep going!"
        case .tippingDark: return "Your Nafs needs some attention. You can do this."
        case .fallen: return "Every journey has tough moments. Start with one prayer."
        }
    }

    var tilt: Double {
        switch self {
        case .balanced: return 0
        case .tippingGold: return 0.5
        case .tippingDark: return -0.5
        case .fallen: return -0.9
        }
    }
}
