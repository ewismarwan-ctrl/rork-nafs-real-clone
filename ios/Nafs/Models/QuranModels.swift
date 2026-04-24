import Foundation

nonisolated struct SurahInfo: Identifiable, Sendable, Hashable {
    let id: Int
    let arabicName: String
    let englishName: String
    let meaning: String
    let ayahCount: Int
    let revelationType: String
}

nonisolated struct QuranAyah: Identifiable, Sendable {
    let id: Int
    let numberInSurah: Int
    let arabicText: String
    let translation: String
}

nonisolated struct QuranBookmark: Identifiable, Codable, Sendable {
    let id: String
    let surahNumber: Int
    let ayahNumberInSurah: Int
    let surahName: String
    let arabicSnippet: String
    let translationSnippet: String
    let date: Date

    init(surahNumber: Int, ayahNumberInSurah: Int, surahName: String, arabicSnippet: String, translationSnippet: String) {
        self.id = UUID().uuidString
        self.surahNumber = surahNumber
        self.ayahNumberInSurah = ayahNumberInSurah
        self.surahName = surahName
        self.arabicSnippet = String(arabicSnippet.prefix(80))
        self.translationSnippet = String(translationSnippet.prefix(120))
        self.date = .now
    }
}

nonisolated struct QuranEditionsResponse: Codable, Sendable {
    let code: Int
    let data: [QuranSurahResponse]
}

nonisolated struct QuranSurahResponse: Codable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let ayahs: [QuranAyahResponse]
}

nonisolated struct QuranAyahResponse: Codable, Sendable {
    let number: Int
    let text: String
    let numberInSurah: Int
}

extension SurahInfo {
    static let all: [SurahInfo] = [
        SurahInfo(id: 1, arabicName: "ٱلْفَاتِحَة", englishName: "Al-Fatihah", meaning: "The Opening", ayahCount: 7, revelationType: "Meccan"),
        SurahInfo(id: 2, arabicName: "ٱلْبَقَرَة", englishName: "Al-Baqarah", meaning: "The Cow", ayahCount: 286, revelationType: "Medinan"),
        SurahInfo(id: 3, arabicName: "آلِ عِمْرَان", englishName: "Ali 'Imran", meaning: "Family of Imran", ayahCount: 200, revelationType: "Medinan"),
        SurahInfo(id: 4, arabicName: "ٱلنِّسَاء", englishName: "An-Nisa", meaning: "The Women", ayahCount: 176, revelationType: "Medinan"),
        SurahInfo(id: 5, arabicName: "ٱلْمَائِدَة", englishName: "Al-Ma'idah", meaning: "The Table Spread", ayahCount: 120, revelationType: "Medinan"),
        SurahInfo(id: 6, arabicName: "ٱلْأَنْعَام", englishName: "Al-An'am", meaning: "The Cattle", ayahCount: 165, revelationType: "Meccan"),
        SurahInfo(id: 7, arabicName: "ٱلْأَعْرَاف", englishName: "Al-A'raf", meaning: "The Heights", ayahCount: 206, revelationType: "Meccan"),
        SurahInfo(id: 8, arabicName: "ٱلْأَنْفَال", englishName: "Al-Anfal", meaning: "The Spoils of War", ayahCount: 75, revelationType: "Medinan"),
        SurahInfo(id: 9, arabicName: "ٱلتَّوْبَة", englishName: "At-Tawbah", meaning: "The Repentance", ayahCount: 129, revelationType: "Medinan"),
        SurahInfo(id: 10, arabicName: "يُونُس", englishName: "Yunus", meaning: "Jonah", ayahCount: 109, revelationType: "Meccan"),
        SurahInfo(id: 11, arabicName: "هُود", englishName: "Hud", meaning: "Hud", ayahCount: 123, revelationType: "Meccan"),
        SurahInfo(id: 12, arabicName: "يُوسُف", englishName: "Yusuf", meaning: "Joseph", ayahCount: 111, revelationType: "Meccan"),
        SurahInfo(id: 13, arabicName: "ٱلرَّعْد", englishName: "Ar-Ra'd", meaning: "The Thunder", ayahCount: 43, revelationType: "Medinan"),
        SurahInfo(id: 14, arabicName: "إِبْرَاهِيم", englishName: "Ibrahim", meaning: "Abraham", ayahCount: 52, revelationType: "Meccan"),
        SurahInfo(id: 15, arabicName: "ٱلْحِجْر", englishName: "Al-Hijr", meaning: "The Rocky Tract", ayahCount: 99, revelationType: "Meccan"),
        SurahInfo(id: 16, arabicName: "ٱلنَّحْل", englishName: "An-Nahl", meaning: "The Bee", ayahCount: 128, revelationType: "Meccan"),
        SurahInfo(id: 17, arabicName: "ٱلْإِسْرَاء", englishName: "Al-Isra", meaning: "The Night Journey", ayahCount: 111, revelationType: "Meccan"),
        SurahInfo(id: 18, arabicName: "ٱلْكَهْف", englishName: "Al-Kahf", meaning: "The Cave", ayahCount: 110, revelationType: "Meccan"),
        SurahInfo(id: 19, arabicName: "مَرْيَم", englishName: "Maryam", meaning: "Mary", ayahCount: 98, revelationType: "Meccan"),
        SurahInfo(id: 20, arabicName: "طه", englishName: "Taha", meaning: "Ta-Ha", ayahCount: 135, revelationType: "Meccan"),
        SurahInfo(id: 21, arabicName: "ٱلْأَنْبِيَاء", englishName: "Al-Anbiya", meaning: "The Prophets", ayahCount: 112, revelationType: "Meccan"),
        SurahInfo(id: 22, arabicName: "ٱلْحَجّ", englishName: "Al-Hajj", meaning: "The Pilgrimage", ayahCount: 78, revelationType: "Medinan"),
        SurahInfo(id: 23, arabicName: "ٱلْمُؤْمِنُون", englishName: "Al-Mu'minun", meaning: "The Believers", ayahCount: 118, revelationType: "Meccan"),
        SurahInfo(id: 24, arabicName: "ٱلنُّور", englishName: "An-Nur", meaning: "The Light", ayahCount: 64, revelationType: "Medinan"),
        SurahInfo(id: 25, arabicName: "ٱلْفُرْقَان", englishName: "Al-Furqan", meaning: "The Criterion", ayahCount: 77, revelationType: "Meccan"),
        SurahInfo(id: 26, arabicName: "ٱلشُّعَرَاء", englishName: "Ash-Shu'ara", meaning: "The Poets", ayahCount: 227, revelationType: "Meccan"),
        SurahInfo(id: 27, arabicName: "ٱلنَّمْل", englishName: "An-Naml", meaning: "The Ant", ayahCount: 93, revelationType: "Meccan"),
        SurahInfo(id: 28, arabicName: "ٱلْقَصَص", englishName: "Al-Qasas", meaning: "The Stories", ayahCount: 88, revelationType: "Meccan"),
        SurahInfo(id: 29, arabicName: "ٱلْعَنْكَبُوت", englishName: "Al-Ankabut", meaning: "The Spider", ayahCount: 69, revelationType: "Meccan"),
        SurahInfo(id: 30, arabicName: "ٱلرُّوم", englishName: "Ar-Rum", meaning: "The Romans", ayahCount: 60, revelationType: "Meccan"),
        SurahInfo(id: 31, arabicName: "لُقْمَان", englishName: "Luqman", meaning: "Luqman", ayahCount: 34, revelationType: "Meccan"),
        SurahInfo(id: 32, arabicName: "ٱلسَّجْدَة", englishName: "As-Sajdah", meaning: "The Prostration", ayahCount: 30, revelationType: "Meccan"),
        SurahInfo(id: 33, arabicName: "ٱلْأَحْزَاب", englishName: "Al-Ahzab", meaning: "The Combined Forces", ayahCount: 73, revelationType: "Medinan"),
        SurahInfo(id: 34, arabicName: "سَبَأ", englishName: "Saba", meaning: "Sheba", ayahCount: 54, revelationType: "Meccan"),
        SurahInfo(id: 35, arabicName: "فَاطِر", englishName: "Fatir", meaning: "The Originator", ayahCount: 45, revelationType: "Meccan"),
        SurahInfo(id: 36, arabicName: "يسٓ", englishName: "Ya-Sin", meaning: "Ya-Sin", ayahCount: 83, revelationType: "Meccan"),
        SurahInfo(id: 37, arabicName: "ٱلصَّافَّات", englishName: "As-Saffat", meaning: "Those Ranged in Ranks", ayahCount: 182, revelationType: "Meccan"),
        SurahInfo(id: 38, arabicName: "صٓ", englishName: "Sad", meaning: "The Letter Sad", ayahCount: 88, revelationType: "Meccan"),
        SurahInfo(id: 39, arabicName: "ٱلزُّمَر", englishName: "Az-Zumar", meaning: "The Groups", ayahCount: 75, revelationType: "Meccan"),
        SurahInfo(id: 40, arabicName: "غَافِر", englishName: "Ghafir", meaning: "The Forgiver", ayahCount: 85, revelationType: "Meccan"),
        SurahInfo(id: 41, arabicName: "فُصِّلَت", englishName: "Fussilat", meaning: "Explained in Detail", ayahCount: 54, revelationType: "Meccan"),
        SurahInfo(id: 42, arabicName: "ٱلشُّورَىٰ", englishName: "Ash-Shura", meaning: "The Consultation", ayahCount: 53, revelationType: "Meccan"),
        SurahInfo(id: 43, arabicName: "ٱلزُّخْرُف", englishName: "Az-Zukhruf", meaning: "The Gold Adornments", ayahCount: 89, revelationType: "Meccan"),
        SurahInfo(id: 44, arabicName: "ٱلدُّخَان", englishName: "Ad-Dukhan", meaning: "The Smoke", ayahCount: 59, revelationType: "Meccan"),
        SurahInfo(id: 45, arabicName: "ٱلْجَاثِيَة", englishName: "Al-Jathiyah", meaning: "The Kneeling", ayahCount: 37, revelationType: "Meccan"),
        SurahInfo(id: 46, arabicName: "ٱلْأَحْقَاف", englishName: "Al-Ahqaf", meaning: "The Wind-Curved Sandhills", ayahCount: 35, revelationType: "Meccan"),
        SurahInfo(id: 47, arabicName: "مُحَمَّد", englishName: "Muhammad", meaning: "Muhammad", ayahCount: 38, revelationType: "Medinan"),
        SurahInfo(id: 48, arabicName: "ٱلْفَتْح", englishName: "Al-Fath", meaning: "The Victory", ayahCount: 29, revelationType: "Medinan"),
        SurahInfo(id: 49, arabicName: "ٱلْحُجُرَات", englishName: "Al-Hujurat", meaning: "The Rooms", ayahCount: 18, revelationType: "Medinan"),
        SurahInfo(id: 50, arabicName: "قٓ", englishName: "Qaf", meaning: "The Letter Qaf", ayahCount: 45, revelationType: "Meccan"),
        SurahInfo(id: 51, arabicName: "ٱلذَّارِيَات", englishName: "Adh-Dhariyat", meaning: "The Winnowing Winds", ayahCount: 60, revelationType: "Meccan"),
        SurahInfo(id: 52, arabicName: "ٱلطُّور", englishName: "At-Tur", meaning: "The Mount", ayahCount: 49, revelationType: "Meccan"),
        SurahInfo(id: 53, arabicName: "ٱلنَّجْم", englishName: "An-Najm", meaning: "The Star", ayahCount: 62, revelationType: "Meccan"),
        SurahInfo(id: 54, arabicName: "ٱلْقَمَر", englishName: "Al-Qamar", meaning: "The Moon", ayahCount: 55, revelationType: "Meccan"),
        SurahInfo(id: 55, arabicName: "ٱلرَّحْمَٰن", englishName: "Ar-Rahman", meaning: "The Most Merciful", ayahCount: 78, revelationType: "Medinan"),
        SurahInfo(id: 56, arabicName: "ٱلْوَاقِعَة", englishName: "Al-Waqi'ah", meaning: "The Inevitable", ayahCount: 96, revelationType: "Meccan"),
        SurahInfo(id: 57, arabicName: "ٱلْحَدِيد", englishName: "Al-Hadid", meaning: "The Iron", ayahCount: 29, revelationType: "Medinan"),
        SurahInfo(id: 58, arabicName: "ٱلْمُجَادِلَة", englishName: "Al-Mujadila", meaning: "The Pleading Woman", ayahCount: 22, revelationType: "Medinan"),
        SurahInfo(id: 59, arabicName: "ٱلْحَشْر", englishName: "Al-Hashr", meaning: "The Exile", ayahCount: 24, revelationType: "Medinan"),
        SurahInfo(id: 60, arabicName: "ٱلْمُمْتَحَنَة", englishName: "Al-Mumtahanah", meaning: "She That is Examined", ayahCount: 13, revelationType: "Medinan"),
        SurahInfo(id: 61, arabicName: "ٱلصَّفّ", englishName: "As-Saff", meaning: "The Ranks", ayahCount: 14, revelationType: "Medinan"),
        SurahInfo(id: 62, arabicName: "ٱلْجُمُعَة", englishName: "Al-Jumu'ah", meaning: "Friday", ayahCount: 11, revelationType: "Medinan"),
        SurahInfo(id: 63, arabicName: "ٱلْمُنَافِقُون", englishName: "Al-Munafiqun", meaning: "The Hypocrites", ayahCount: 11, revelationType: "Medinan"),
        SurahInfo(id: 64, arabicName: "ٱلتَّغَابُن", englishName: "At-Taghabun", meaning: "The Mutual Disillusion", ayahCount: 18, revelationType: "Medinan"),
        SurahInfo(id: 65, arabicName: "ٱلطَّلَاق", englishName: "At-Talaq", meaning: "The Divorce", ayahCount: 12, revelationType: "Medinan"),
        SurahInfo(id: 66, arabicName: "ٱلتَّحْرِيم", englishName: "At-Tahrim", meaning: "The Prohibition", ayahCount: 12, revelationType: "Medinan"),
        SurahInfo(id: 67, arabicName: "ٱلْمُلْك", englishName: "Al-Mulk", meaning: "The Sovereignty", ayahCount: 30, revelationType: "Meccan"),
        SurahInfo(id: 68, arabicName: "ٱلْقَلَم", englishName: "Al-Qalam", meaning: "The Pen", ayahCount: 52, revelationType: "Meccan"),
        SurahInfo(id: 69, arabicName: "ٱلْحَاقَّة", englishName: "Al-Haqqah", meaning: "The Reality", ayahCount: 52, revelationType: "Meccan"),
        SurahInfo(id: 70, arabicName: "ٱلْمَعَارِج", englishName: "Al-Ma'arij", meaning: "The Ascending Stairways", ayahCount: 44, revelationType: "Meccan"),
        SurahInfo(id: 71, arabicName: "نُوح", englishName: "Nuh", meaning: "Noah", ayahCount: 28, revelationType: "Meccan"),
        SurahInfo(id: 72, arabicName: "ٱلْجِنّ", englishName: "Al-Jinn", meaning: "The Jinn", ayahCount: 28, revelationType: "Meccan"),
        SurahInfo(id: 73, arabicName: "ٱلْمُزَّمِّل", englishName: "Al-Muzzammil", meaning: "The Enshrouded One", ayahCount: 20, revelationType: "Meccan"),
        SurahInfo(id: 74, arabicName: "ٱلْمُدَّثِّر", englishName: "Al-Muddathir", meaning: "The Cloaked One", ayahCount: 56, revelationType: "Meccan"),
        SurahInfo(id: 75, arabicName: "ٱلْقِيَامَة", englishName: "Al-Qiyamah", meaning: "The Resurrection", ayahCount: 40, revelationType: "Meccan"),
        SurahInfo(id: 76, arabicName: "ٱلْإِنْسَان", englishName: "Al-Insan", meaning: "Man", ayahCount: 31, revelationType: "Medinan"),
        SurahInfo(id: 77, arabicName: "ٱلْمُرْسَلَات", englishName: "Al-Mursalat", meaning: "The Emissaries", ayahCount: 50, revelationType: "Meccan"),
        SurahInfo(id: 78, arabicName: "ٱلنَّبَأ", englishName: "An-Naba", meaning: "The Tidings", ayahCount: 40, revelationType: "Meccan"),
        SurahInfo(id: 79, arabicName: "ٱلنَّازِعَات", englishName: "An-Nazi'at", meaning: "Those Who Drag Forth", ayahCount: 46, revelationType: "Meccan"),
        SurahInfo(id: 80, arabicName: "عَبَسَ", englishName: "Abasa", meaning: "He Frowned", ayahCount: 42, revelationType: "Meccan"),
        SurahInfo(id: 81, arabicName: "ٱلتَّكْوِير", englishName: "At-Takwir", meaning: "The Overthrowing", ayahCount: 29, revelationType: "Meccan"),
        SurahInfo(id: 82, arabicName: "ٱلْإِنْفِطَار", englishName: "Al-Infitar", meaning: "The Cleaving", ayahCount: 19, revelationType: "Meccan"),
        SurahInfo(id: 83, arabicName: "ٱلْمُطَفِّفِين", englishName: "Al-Mutaffifin", meaning: "The Defrauding", ayahCount: 36, revelationType: "Meccan"),
        SurahInfo(id: 84, arabicName: "ٱلْإِنْشِقَاق", englishName: "Al-Inshiqaq", meaning: "The Splitting Open", ayahCount: 25, revelationType: "Meccan"),
        SurahInfo(id: 85, arabicName: "ٱلْبُرُوج", englishName: "Al-Buruj", meaning: "The Mansions of Stars", ayahCount: 22, revelationType: "Meccan"),
        SurahInfo(id: 86, arabicName: "ٱلطَّارِق", englishName: "At-Tariq", meaning: "The Morning Star", ayahCount: 17, revelationType: "Meccan"),
        SurahInfo(id: 87, arabicName: "ٱلْأَعْلَى", englishName: "Al-A'la", meaning: "The Most High", ayahCount: 19, revelationType: "Meccan"),
        SurahInfo(id: 88, arabicName: "ٱلْغَاشِيَة", englishName: "Al-Ghashiyah", meaning: "The Overwhelming", ayahCount: 26, revelationType: "Meccan"),
        SurahInfo(id: 89, arabicName: "ٱلْفَجْر", englishName: "Al-Fajr", meaning: "The Dawn", ayahCount: 30, revelationType: "Meccan"),
        SurahInfo(id: 90, arabicName: "ٱلْبَلَد", englishName: "Al-Balad", meaning: "The City", ayahCount: 20, revelationType: "Meccan"),
        SurahInfo(id: 91, arabicName: "ٱلشَّمْس", englishName: "Ash-Shams", meaning: "The Sun", ayahCount: 15, revelationType: "Meccan"),
        SurahInfo(id: 92, arabicName: "ٱلَّيْل", englishName: "Al-Lail", meaning: "The Night", ayahCount: 21, revelationType: "Meccan"),
        SurahInfo(id: 93, arabicName: "ٱلضُّحَىٰ", englishName: "Ad-Duhaa", meaning: "The Morning Hours", ayahCount: 11, revelationType: "Meccan"),
        SurahInfo(id: 94, arabicName: "ٱلشَّرْح", englishName: "Ash-Sharh", meaning: "The Relief", ayahCount: 8, revelationType: "Meccan"),
        SurahInfo(id: 95, arabicName: "ٱلتِّين", englishName: "At-Tin", meaning: "The Fig", ayahCount: 8, revelationType: "Meccan"),
        SurahInfo(id: 96, arabicName: "ٱلْعَلَق", englishName: "Al-Alaq", meaning: "The Clot", ayahCount: 19, revelationType: "Meccan"),
        SurahInfo(id: 97, arabicName: "ٱلْقَدْر", englishName: "Al-Qadr", meaning: "The Power", ayahCount: 5, revelationType: "Meccan"),
        SurahInfo(id: 98, arabicName: "ٱلْبَيِّنَة", englishName: "Al-Bayyinah", meaning: "The Clear Proof", ayahCount: 8, revelationType: "Medinan"),
        SurahInfo(id: 99, arabicName: "ٱلزَّلْزَلَة", englishName: "Az-Zalzalah", meaning: "The Earthquake", ayahCount: 8, revelationType: "Medinan"),
        SurahInfo(id: 100, arabicName: "ٱلْعَادِيَات", englishName: "Al-Adiyat", meaning: "The Chargers", ayahCount: 11, revelationType: "Meccan"),
        SurahInfo(id: 101, arabicName: "ٱلْقَارِعَة", englishName: "Al-Qari'ah", meaning: "The Calamity", ayahCount: 11, revelationType: "Meccan"),
        SurahInfo(id: 102, arabicName: "ٱلتَّكَاثُر", englishName: "At-Takathur", meaning: "The Rivalry in Worldly Increase", ayahCount: 8, revelationType: "Meccan"),
        SurahInfo(id: 103, arabicName: "ٱلْعَصْر", englishName: "Al-Asr", meaning: "The Declining Day", ayahCount: 3, revelationType: "Meccan"),
        SurahInfo(id: 104, arabicName: "ٱلْهُمَزَة", englishName: "Al-Humazah", meaning: "The Traducer", ayahCount: 9, revelationType: "Meccan"),
        SurahInfo(id: 105, arabicName: "ٱلْفِيل", englishName: "Al-Fil", meaning: "The Elephant", ayahCount: 5, revelationType: "Meccan"),
        SurahInfo(id: 106, arabicName: "قُرَيْش", englishName: "Quraysh", meaning: "Quraysh", ayahCount: 4, revelationType: "Meccan"),
        SurahInfo(id: 107, arabicName: "ٱلْمَاعُون", englishName: "Al-Ma'un", meaning: "The Small Kindnesses", ayahCount: 7, revelationType: "Meccan"),
        SurahInfo(id: 108, arabicName: "ٱلْكَوْثَر", englishName: "Al-Kawthar", meaning: "The Abundance", ayahCount: 3, revelationType: "Meccan"),
        SurahInfo(id: 109, arabicName: "ٱلْكَافِرُون", englishName: "Al-Kafirun", meaning: "The Disbelievers", ayahCount: 6, revelationType: "Meccan"),
        SurahInfo(id: 110, arabicName: "ٱلنَّصْر", englishName: "An-Nasr", meaning: "The Victory", ayahCount: 3, revelationType: "Medinan"),
        SurahInfo(id: 111, arabicName: "ٱلْمَسَد", englishName: "Al-Masad", meaning: "The Palm Fiber", ayahCount: 5, revelationType: "Meccan"),
        SurahInfo(id: 112, arabicName: "ٱلْإِخْلَاص", englishName: "Al-Ikhlas", meaning: "The Sincerity", ayahCount: 4, revelationType: "Meccan"),
        SurahInfo(id: 113, arabicName: "ٱلْفَلَق", englishName: "Al-Falaq", meaning: "The Daybreak", ayahCount: 5, revelationType: "Meccan"),
        SurahInfo(id: 114, arabicName: "ٱلنَّاس", englishName: "An-Nas", meaning: "Mankind", ayahCount: 6, revelationType: "Meccan"),
    ]

    static let ayahOffsets: [Int] = {
        var offsets = [0]
        var total = 0
        for surah in SurahInfo.all {
            total += surah.ayahCount
            offsets.append(total)
        }
        return offsets
    }()

    static func globalAyahNumber(surah: Int, ayahInSurah: Int) -> Int {
        guard surah >= 1, surah <= 114 else { return ayahInSurah }
        return ayahOffsets[surah - 1] + ayahInSurah
    }

    static func surahAndAyah(fromGlobal globalNumber: Int) -> (surah: Int, ayah: Int) {
        for i in (0..<ayahOffsets.count - 1).reversed() {
            if globalNumber > ayahOffsets[i] {
                return (surah: i + 1, ayah: globalNumber - ayahOffsets[i])
            }
        }
        return (surah: 1, ayah: 1)
    }
}
