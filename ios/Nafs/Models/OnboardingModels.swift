import Foundation

nonisolated enum OnboardingScreen: Int, CaseIterable {
    case splash = 0
    case languageSelection
    case problem        // Stop delaying / Salah
    case discipline     // You don't lack / discipline
    case oneScroll      // It starts with / one scroll
    case notFault       // It's not your / fault
    case system         // So we built a / system
    case whenSalah      // When it's time for / Salah
    case automation     // No reminders. / No willpower.
    case appSelection   // Select apps to block
    case phoneMockup    // Empty phone mockup placeholder
    case reward         // You pray → it unlocks
    case paywall
}

nonisolated struct SelectionOption: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String

    init(_ id: String, title: String, icon: String = "") {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

nonisolated struct OnboardingOptions {
    static var deenAreas: [SelectionOption] {
        [
            SelectionOption("salah", title: NafsStrings.deenSalah.localized, icon: "moon.stars"),
            SelectionOption("quran", title: NafsStrings.deenQuran.localized, icon: "book.closed"),
            SelectionOption("dhikr", title: NafsStrings.deenDhikr.localized, icon: "hands.sparkles"),
            SelectionOption("knowledge", title: NafsStrings.deenKnowledge.localized, icon: "lightbulb"),
            SelectionOption("screentime", title: NafsStrings.deenScreentime.localized, icon: "iphone"),
            SelectionOption("discipline", title: NafsStrings.deenDiscipline.localized, icon: "shield.checkered"),
            SelectionOption("accountability", title: NafsStrings.deenAccountability.localized, icon: "person.3"),
            SelectionOption("all", title: NafsStrings.deenAll.localized, icon: "checkmark.seal.fill"),
        ]
    }

    static var salahRelationship: [SelectionOption] {
        [
            SelectionOption("all_5", title: NafsStrings.salahAll5.localized, icon: "checkmark.seal.fill"),
            SelectionOption("most", title: NafsStrings.salahMost.localized, icon: "chart.line.uptrend.xyaxis"),
            SelectionOption("sometimes", title: NafsStrings.salahSometimes.localized, icon: "hand.raised"),
            SelectionOption("drifted", title: NafsStrings.salahDrifted.localized, icon: "arrow.uturn.backward"),
            SelectionOption("new", title: NafsStrings.salahNew.localized, icon: "sparkles"),
        ]
    }

    static var quranRelationship: [SelectionOption] {
        [
            SelectionOption("daily", title: NafsStrings.quranDaily.localized, icon: "book.fill"),
            SelectionOption("sometimes", title: NafsStrings.quranSometimes.localized, icon: "bookmark"),
            SelectionOption("rarely", title: NafsStrings.quranRarely.localized, icon: "text.book.closed"),
            SelectionOption("memorize", title: NafsStrings.quranMemorize.localized, icon: "brain.head.profile"),
            SelectionOption("starting", title: NafsStrings.quranStarting.localized, icon: "sparkles"),
        ]
    }

    static var knowledgeAreas: [SelectionOption] {
        [
            SelectionOption("tafsir", title: NafsStrings.knTafsir.localized, icon: "text.magnifyingglass"),
            SelectionOption("hadith", title: NafsStrings.knHadith.localized, icon: "quote.opening"),
            SelectionOption("history", title: NafsStrings.knHistory.localized, icon: "clock.arrow.circlepath"),
            SelectionOption("fiqh", title: NafsStrings.knFiqh.localized, icon: "scale.3d"),
            SelectionOption("seerah", title: NafsStrings.knSeerah.localized, icon: "star"),
            SelectionOption("aqeedah", title: NafsStrings.knAqeedah.localized, icon: "heart.circle"),
            SelectionOption("all", title: NafsStrings.deenAll.localized, icon: "checkmark.seal.fill"),
        ]
    }

    static var phoneEffect: [SelectionOption] {
        [
            SelectionOption("distracts_prayer", title: NafsStrings.phoneDistract.localized, icon: "moon.stars"),
            SelectionOption("scrolling", title: NafsStrings.phoneScrolling.localized, icon: "arrow.down.circle"),
            SelectionOption("mostly_fine", title: NafsStrings.phoneFine.localized, icon: "hand.thumbsup"),
            SelectionOption("intentional", title: NafsStrings.phoneIntentional.localized, icon: "lightbulb"),
        ]
    }

    static var spiritualChallenge: [SelectionOption] {
        [
            SelectionOption("consistency", title: NafsStrings.challengeConsistency.localized, icon: "chart.line.uptrend.xyaxis"),
            SelectionOption("knowledge", title: NafsStrings.challengeKnowledge.localized, icon: "book"),
            SelectionOption("connection", title: NafsStrings.challengeConnection.localized, icon: "heart"),
            SelectionOption("discipline", title: NafsStrings.challengeDiscipline.localized, icon: "shield.checkered"),
            SelectionOption("community", title: NafsStrings.challengeCommunity.localized, icon: "person.3"),
            SelectionOption("balance", title: NafsStrings.challengeBalance.localized, icon: "scale.3d"),
        ]
    }

    static var excitingFeatures: [SelectionOption] {
        [
            SelectionOption("earn_screentime", title: NafsStrings.featureScreentime.localized, icon: "lock.open"),
            SelectionOption("quran_reader", title: NafsStrings.featureQuranReader.localized, icon: "book.fill"),
            SelectionOption("nafs_ai", title: NafsStrings.featureAI.localized, icon: "sparkles"),
            SelectionOption("garden", title: NafsStrings.featureGarden.localized, icon: "tree.fill"),
            SelectionOption("guided_plans", title: NafsStrings.featurePlans.localized, icon: "map"),
            SelectionOption("muhasabah", title: NafsStrings.featureMuhasabah.localized, icon: "pencil.and.list.clipboard"),
            SelectionOption("prayer_qibla", title: NafsStrings.featurePrayerQibla.localized, icon: "location.north.fill"),
        ]
    }

    static var strictnessLevels: [SelectionOption] {
        [
            SelectionOption("gentle", title: NafsStrings.strictGentle.localized, icon: "leaf"),
            SelectionOption("balanced", title: NafsStrings.strictBalanced.localized, icon: "scale.3d"),
            SelectionOption("strict", title: NafsStrings.strictStrict.localized, icon: "lock.shield"),
            SelectionOption("maximum", title: NafsStrings.strictMaximum.localized, icon: "lock.fill"),
        ]
    }
}

nonisolated struct CountryData: Identifiable, Hashable {
    let id: String
    let name: String
    let cities: [String]
}

nonisolated let popularCountries: [CountryData] = [
    CountryData(id: "us", name: "United States", cities: ["New York", "Los Angeles", "Chicago", "Houston", "Dallas", "Detroit", "Washington D.C."]),
    CountryData(id: "uk", name: "United Kingdom", cities: ["London", "Birmingham", "Manchester", "Leeds", "Bradford"]),
    CountryData(id: "ca", name: "Canada", cities: ["Toronto", "Montreal", "Vancouver", "Calgary", "Ottawa"]),
    CountryData(id: "sa", name: "Saudi Arabia", cities: ["Riyadh", "Jeddah", "Mecca", "Medina", "Dammam"]),
    CountryData(id: "ae", name: "UAE", cities: ["Dubai", "Abu Dhabi", "Sharjah", "Ajman"]),
    CountryData(id: "eg", name: "Egypt", cities: ["Cairo", "Alexandria", "Giza", "Luxor"]),
    CountryData(id: "pk", name: "Pakistan", cities: ["Karachi", "Lahore", "Islamabad", "Rawalpindi", "Faisalabad"]),
    CountryData(id: "my", name: "Malaysia", cities: ["Kuala Lumpur", "Penang", "Johor Bahru", "Shah Alam"]),
    CountryData(id: "id", name: "Indonesia", cities: ["Jakarta", "Surabaya", "Bandung", "Medan"]),
    CountryData(id: "tr", name: "Turkey", cities: ["Istanbul", "Ankara", "Izmir", "Bursa"]),
    CountryData(id: "ng", name: "Nigeria", cities: ["Lagos", "Abuja", "Kano", "Ibadan"]),
    CountryData(id: "in", name: "India", cities: ["Mumbai", "Delhi", "Hyderabad", "Bangalore", "Chennai"]),
    CountryData(id: "bd", name: "Bangladesh", cities: ["Dhaka", "Chittagong", "Sylhet", "Rajshahi"]),
    CountryData(id: "de", name: "Germany", cities: ["Berlin", "Munich", "Hamburg", "Frankfurt", "Cologne"]),
    CountryData(id: "fr", name: "France", cities: ["Paris", "Marseille", "Lyon", "Toulouse"]),
    CountryData(id: "au", name: "Australia", cities: ["Sydney", "Melbourne", "Brisbane", "Perth"]),
]
