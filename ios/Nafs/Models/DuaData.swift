import Foundation

nonisolated struct DuaItem: Identifiable, Sendable, Hashable {
    let id: String
    let arabic: String
    let translation: String
    let reference: String
    let theme: DuaTheme
}

nonisolated enum DuaTheme: String, CaseIterable, Sendable, Identifiable {
    case gratitude = "Gratitude"
    case healing = "Healing"
    case strength = "Strength"
    case love = "Love"
    case guidance = "Guidance"
    case protection = "Protection"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .healing: return "cross.circle.fill"
        case .strength: return "bolt.fill"
        case .love: return "heart.circle.fill"
        case .guidance: return "light.beacon.max.fill"
        case .protection: return "shield.fill"
        }
    }
}

extension DuaItem {
    static let all: [DuaItem] = [
        DuaItem(id: "g1", arabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", translation: "All praise is due to Allah, Lord of all the worlds.", reference: "Quran 1:2", theme: .gratitude),
        DuaItem(id: "g2", arabic: "رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ", translation: "My Lord, enable me to be grateful for Your favor which You have bestowed upon me.", reference: "Quran 27:19", theme: .gratitude),
        DuaItem(id: "g3", arabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", translation: "If you are grateful, I will surely increase you in favor.", reference: "Quran 14:7", theme: .gratitude),

        DuaItem(id: "h1", arabic: "رَبِّ إِنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ", translation: "My Lord, indeed adversity has touched me, and You are the Most Merciful of the merciful.", reference: "Quran 21:83", theme: .healing),
        DuaItem(id: "h2", arabic: "وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ", translation: "And when I am ill, it is He who cures me.", reference: "Quran 26:80", theme: .healing),
        DuaItem(id: "h3", arabic: "وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ", translation: "We send down the Quran as a healing and mercy for the believers.", reference: "Quran 17:82", theme: .healing),

        DuaItem(id: "s1", arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", translation: "Sufficient for us is Allah, and He is the best Disposer of affairs.", reference: "Quran 3:173", theme: .strength),
        DuaItem(id: "s2", arabic: "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا", translation: "Our Lord, pour upon us patience and plant firmly our feet.", reference: "Quran 2:250", theme: .strength),
        DuaItem(id: "s3", arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا", translation: "Allah does not burden a soul beyond that it can bear.", reference: "Quran 2:286", theme: .strength),

        DuaItem(id: "l1", arabic: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ", translation: "Our Lord, grant us from our spouses and offspring comfort to our eyes.", reference: "Quran 25:74", theme: .love),
        DuaItem(id: "l2", arabic: "وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا لِّتَسْكُنُوا إِلَيْهَا وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً", translation: "And of His signs is that He created for you mates that you may find tranquility in them, and He placed between you affection and mercy.", reference: "Quran 30:21", theme: .love),

        DuaItem(id: "d1", arabic: "رَبِّ زِدْنِي عِلْمًا", translation: "My Lord, increase me in knowledge.", reference: "Quran 20:114", theme: .guidance),
        DuaItem(id: "d2", arabic: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ", translation: "Guide us to the straight path.", reference: "Quran 1:6", theme: .guidance),
        DuaItem(id: "d3", arabic: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا", translation: "Our Lord, let not our hearts deviate after You have guided us.", reference: "Quran 3:8", theme: .guidance),

        DuaItem(id: "p1", arabic: "رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ", translation: "My Lord, I seek refuge in You from the incitements of the devils.", reference: "Quran 23:97", theme: .protection),
        DuaItem(id: "p2", arabic: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ", translation: "Say: I seek refuge in the Lord of daybreak.", reference: "Quran 113:1", theme: .protection),
        DuaItem(id: "p3", arabic: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ", translation: "In the name of Allah, with whose name nothing on earth or in the heavens can harm.", reference: "Tirmidhi 3388", theme: .protection),
    ]

    static func byTheme(_ theme: DuaTheme) -> [DuaItem] {
        all.filter { $0.theme == theme }
    }
}
