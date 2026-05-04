import WidgetKit
import SwiftUI

// MARK: - Shared

nonisolated enum WidgetTheme {
    static let gold = Color(red: 200/255, green: 169/255, blue: 106/255)
    static let goldLight = Color(red: 212/255, green: 184/255, blue: 122/255)
    static let goldDark = Color(red: 184/255, green: 149/255, blue: 90/255)
    static let cream = Color(red: 248/255, green: 246/255, blue: 241/255)
    static let creamCard = Color(red: 240/255, green: 237/255, blue: 230/255)
    static let ink = Color(red: 20/255, green: 18/255, blue: 16/255)
    static let inkSoft = Color(red: 36/255, green: 32/255, blue: 28/255)
    static let darkText = Color(red: 46/255, green: 42/255, blue: 37/255)

    static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    static var shared: UserDefaults? { UserDefaults(suiteName: appGroupID) }
}

nonisolated struct WidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetTheme.ink, WidgetTheme.inkSoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { geo in
                Circle()
                    .fill(WidgetTheme.gold.opacity(0.08))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.3)
            }
        }
    }
}

nonisolated struct WidgetCreamBackground: View {
    var body: some View {
        ZStack {
            WidgetTheme.cream
            GeometryReader { geo in
                Circle()
                    .stroke(WidgetTheme.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: geo.size.width * 0.45, y: -geo.size.height * 0.25)
            }
        }
    }
}

// MARK: - Content Library

nonisolated enum NafsContentLibrary {
    static let ayat: [(arabic: String, translation: String, reference: String)] = [
        ("إِنَّ مَعَ ٱلْعُسْرِ يُسْرًۭا", "Indeed, with hardship comes ease.", "Qur'an 94:6"),
        ("فَٱذْكُرُونِىٓ أَذْكُرْكُمْ", "Remember Me, and I will remember you.", "Qur'an 2:152"),
        ("وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥٓ", "Whoever puts their trust in Allah, He is enough for them.", "Qur'an 65:3"),
        ("إِنَّ ٱللَّهَ مَعَ ٱلصَّٰبِرِينَ", "Indeed, Allah is with the patient.", "Qur'an 2:153"),
        ("وَٱللَّهُ خَيْرُ ٱلرَّٰزِقِينَ", "And Allah is the best of providers.", "Qur'an 62:11"),
        ("لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا", "Allah does not burden a soul beyond that it can bear.", "Qur'an 2:286"),
        ("وَٱصْبِرْ وَمَا صَبْرُكَ إِلَّا بِٱللَّهِ", "Be patient, and your patience is only by Allah.", "Qur'an 16:127"),
        ("وَبَشِّرِ ٱلصَّٰبِرِينَ", "And give good news to those who patiently endure.", "Qur'an 2:155"),
        ("إِنَّ ٱلصَّلَوٰةَ تَنْهَىٰ عَنِ ٱلْفَحْشَاءِ وَٱلْمُنكَرِ", "Indeed, prayer prohibits immorality and wrongdoing.", "Qur'an 29:45"),
        ("وَذَكِّرْ فَإِنَّ ٱلذِّكْرَىٰ تَنفَعُ ٱلْمُؤْمِنِينَ", "And remind, for reminders benefit the believers.", "Qur'an 51:55"),
        ("وَلَا تَيْـَٔسُوا۟ مِن رَّوْحِ ٱللَّهِ", "Do not despair of the mercy of Allah.", "Qur'an 12:87"),
        ("إِنَّمَا ٱلْمُؤْمِنُونَ إِخْوَةٌۭ", "The believers are but brothers.", "Qur'an 49:10"),
        ("وَمَنْ أَحْسَنُ قَوْلًۭا مِّمَّن دَعَآ إِلَى ٱللَّهِ", "Who is better in speech than one who calls to Allah.", "Qur'an 41:33"),
        ("رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةًۭ", "Our Lord, grant us good in this world.", "Qur'an 2:201"),
        ("ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ", "Call upon Me; I will respond to you.", "Qur'an 40:60"),
    ]

    static let reflections: [String] = [
        "A moment of dhikr is heavier on the scale than a mountain of distraction.",
        "Every prayer you protect today is a light you carry into the grave.",
        "The Qur'an does not need you — you need it. Open one page today.",
        "Allah is closer to you than your jugular vein. Turn to Him now.",
        "Your time is your life. What will you spend it on today?",
        "A small consistent deed is more beloved to Allah than a grand, broken one.",
        "Gratitude turns what you have into enough. Say Alhamdulillah.",
        "The heart that remembers Allah is never truly alone.",
        "Tawbah is never too late. The door is open until the soul reaches the throat.",
        "Your sujood is the closest you will ever be to Allah in this world.",
        "You do not need a mosque to begin. You only need a moment of sincerity.",
        "The world is a bridge — build something eternal on the other side.",
        "Every struggle you hide for His sake is witnessed by the One who matters.",
        "Rizq comes from Allah. Effort is an act of worship, not a guarantee.",
        "Speak gently. Your words will meet you again on the Day of Judgment.",
    ]

    static func todayAyah(for date: Date = .now) -> (arabic: String, translation: String, reference: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return ayat[day % ayat.count]
    }

    static func todayReflection(for date: Date = .now) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return reflections[day % reflections.count]
    }
}

// MARK: - Prayer Data

nonisolated struct SharedPrayerTime: Codable, Sendable {
    let name: String
    let time: Date
}

nonisolated struct SharedPrayerDay: Codable, Sendable {
    let dayStart: Date
    let times: [SharedPrayerTime]
}

nonisolated enum WidgetPrayerLoader {
    static func load(for date: Date = .now) -> (times: [SharedPrayerTime], location: String) {
        guard let shared = WidgetTheme.shared else { return (fallback(for: date), "") }
        let location = shared.string(forKey: "nafs_locationName") ?? ""

        // Prefer multi-day data so widgets remain accurate after midnight.
        if let data = shared.data(forKey: "nafs_prayerTimesMultiDay"),
           let days = try? JSONDecoder().decode([SharedPrayerDay].self, from: data) {
            let cal = Calendar(identifier: .gregorian)
            let target = cal.startOfDay(for: date)
            if let today = days.first(where: { cal.isDate($0.dayStart, inSameDayAs: target) }) {
                return (today.times, location)
            }
            // Fallback to next available day if today's data is missing.
            if let next = days.first(where: { $0.dayStart >= target }) {
                return (next.times, location)
            }
        }

        // Legacy single-day payload.
        if let data = shared.data(forKey: "nafs_prayerTimes"),
           let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data) {
            let cal = Calendar(identifier: .gregorian)
            // Only trust the legacy payload if it's for the requested day.
            if let first = decoded.first, cal.isDate(first.time, inSameDayAs: date) {
                return (decoded, location)
            }
        }

        return (fallback(for: date), location)
    }

    static func nextPrayer(from times: [SharedPrayerTime], now: Date = .now) -> SharedPrayerTime? {
        times.sorted { $0.time < $1.time }.first(where: { $0.time > now })
            ?? times.sorted { $0.time < $1.time }.last
    }

    private static func fallback(for date: Date = .now) -> [SharedPrayerTime] {
        let cal = Calendar.current
        let base = cal.startOfDay(for: date)
        let raw: [(String, Int, Int)] = [
            ("Fajr", 5, 15),
            ("Dhuhr", 12, 30),
            ("Asr", 15, 45),
            ("Maghrib", 18, 30),
            ("Isha", 20, 0),
        ]
        return raw.compactMap { name, h, m in
            guard let date = cal.date(bySettingHour: h, minute: m, second: 0, of: base) else { return nil }
            return SharedPrayerTime(name: name, time: date)
        }
    }
}

// MARK: - Ayah Widget

nonisolated struct AyahEntry: TimelineEntry {
    let date: Date
    let arabic: String
    let translation: String
    let reference: String
}

nonisolated struct AyahProvider: TimelineProvider {
    func placeholder(in context: Context) -> AyahEntry {
        let a = NafsContentLibrary.todayAyah()
        return AyahEntry(date: .now, arabic: a.arabic, translation: a.translation, reference: a.reference)
    }

    func getSnapshot(in context: Context, completion: @escaping (AyahEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AyahEntry>) -> Void) {
        var entries: [AyahEntry] = []
        let cal = Calendar.current
        let now = Date.now
        let startOfHour = cal.date(bySetting: .minute, value: 0, of: now) ?? now
        for offset in 0..<8 {
            let date = cal.date(byAdding: .hour, value: offset * 3, to: startOfHour) ?? now
            let a = NafsContentLibrary.todayAyah(for: date)
            entries.append(AyahEntry(date: date, arabic: a.arabic, translation: a.translation, reference: a.reference))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct AyahWidgetView: View {
    let entry: AyahEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Ayah of the Day")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                }
                .foregroundStyle(WidgetTheme.gold)

                Text(entry.arabic)
                    .font(.system(size: family == .systemSmall ? 14 : 17, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(family == .systemSmall ? 2 : 3)
                    .multilineTextAlignment(.leading)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(entry.translation)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(family == .systemSmall ? 2 : 4)
                    .lineSpacing(2)

                Spacer(minLength: 0)

                Text(entry.reference)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetTheme.gold)
                    .tracking(0.5)
            }
            .padding(family == .systemSmall ? 2 : 4)
        }
    }
}

nonisolated struct AyahReminderWidget: Widget {
    let kind: String = "NafsAyahReminder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AyahProvider()) { entry in
            AyahWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Ayah of the Day")
        .description("A rotating verse from the Qur'an on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Prayer Times Widget

nonisolated struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let prayers: [SharedPrayerTime]
    let locationName: String
}

nonisolated struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        let loaded = WidgetPrayerLoader.load()
        return PrayerTimesEntry(date: .now, prayers: loaded.times, locationName: loaded.location)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimesEntry>) -> Void) {
        let now = Date.now
        let loaded = WidgetPrayerLoader.load(for: now)
        let entry = PrayerTimesEntry(date: now, prayers: loaded.times, locationName: loaded.location)
        let cal = Calendar(identifier: .gregorian)
        let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(3600)
        let nextPrayer = loaded.times.first(where: { $0.time > now })?.time
        let refresh = [nextPrayer, nextMidnight].compactMap { $0 }.min() ?? nextMidnight
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct PrayerTimesWidgetView: View {
    let entry: PrayerTimesEntry
    @Environment(\.widgetFamily) private var family

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        ZStack {
            WidgetCreamBackground()
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Prayer Times")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                    Spacer()
                    if !entry.locationName.isEmpty && family != .systemSmall {
                        Text(entry.locationName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(WidgetTheme.darkText.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(WidgetTheme.gold)

                ForEach(entry.prayers.prefix(family == .systemSmall ? 3 : 5), id: \.name) { p in
                    HStack {
                        Text(p.name)
                            .font(.system(size: family == .systemSmall ? 12 : 14, weight: .semibold))
                            .foregroundStyle(isPast(p) ? WidgetTheme.darkText.opacity(0.4) : WidgetTheme.darkText)
                        Spacer()
                        Text(Self.timeFormatter.string(from: p.time))
                            .font(.system(size: family == .systemSmall ? 11 : 13, weight: .medium, design: .rounded))
                            .foregroundStyle(isNext(p) ? WidgetTheme.gold : WidgetTheme.darkText.opacity(isPast(p) ? 0.4 : 0.8))
                            .monospacedDigit()
                    }
                    if isNext(p) {
                        Rectangle()
                            .fill(WidgetTheme.gold.opacity(0.3))
                            .frame(height: 1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(2)
        }
    }

    private func isPast(_ p: SharedPrayerTime) -> Bool {
        p.time < entry.date
    }

    private func isNext(_ p: SharedPrayerTime) -> Bool {
        WidgetPrayerLoader.nextPrayer(from: entry.prayers, now: entry.date)?.name == p.name
    }
}

nonisolated struct PrayerTimesWidget: Widget {
    let kind: String = "NafsPrayerTimes"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetCreamBackground() }
        }
        .configurationDisplayName("Prayer Times")
        .description("All five daily prayer times at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Next Prayer Widget

nonisolated struct NextPrayerEntry: TimelineEntry {
    let date: Date
    let next: SharedPrayerTime?
    let locationName: String
    var family: WidgetFamily = .systemSmall
}

nonisolated struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPrayerEntry {
        let loaded = WidgetPrayerLoader.load()
        return NextPrayerEntry(date: .now, next: WidgetPrayerLoader.nextPrayer(from: loaded.times), locationName: loaded.location, family: context.family)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let now = Date.now
        let loaded = WidgetPrayerLoader.load(for: now)
        let next = WidgetPrayerLoader.nextPrayer(from: loaded.times)
        var entries: [NextPrayerEntry] = [
            NextPrayerEntry(date: now, next: next, locationName: loaded.location, family: context.family)
        ]
        if let nextTime = next?.time, nextTime > now {
            let total = Int(nextTime.timeIntervalSince(now))
            for offset in stride(from: 60, through: min(60 * 60, total), by: 60) {
                let d = now.addingTimeInterval(TimeInterval(offset))
                if d >= nextTime { break }
                entries.append(NextPrayerEntry(date: d, next: next, locationName: loaded.location, family: context.family))
            }
        }
        let cal = Calendar(identifier: .gregorian)
        let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(3600)
        let refresh = [next?.time, nextMidnight].compactMap { $0 }.min() ?? nextMidnight
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

struct NextPrayerWidgetView: View {
    let entry: NextPrayerEntry
    @Environment(\.widgetFamily) private var family

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        default:
            homeView
        }
    }

    @ViewBuilder private var inlineView: some View {
        if let next = entry.next {
            Text("\(next.name) \(Self.shortTimeFormatter.string(from: next.time))")
        } else {
            Text("Nafs — Loading")
        }
    }

    @ViewBuilder private var circularView: some View {
        if let next = entry.next {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(next.name.prefix(4).uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .minimumScaleFactor(0.7)
                    Text(Self.shortTimeFormatter.string(from: next.time))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(2)
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "moon.stars.fill")
            }
        }
    }

    @ViewBuilder private var rectangularView: some View {
        if let next = entry.next {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("NEXT PRAYER")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                }
                Text("\(next.name) · \(Self.timeFormatter.string(from: next.time))")
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(next.time, style: .relative)
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nafs")
                    .font(.system(size: 11, weight: .bold))
                Text("Enable location")
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var homeView: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Next Prayer")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(WidgetTheme.gold)

                if let next = entry.next {
                    Text(next.name)
                        .font(.system(size: family == .systemSmall ? 26 : 34, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Text(Self.timeFormatter.string(from: next.time))
                        .font(.system(size: family == .systemSmall ? 14 : 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetTheme.gold)
                        .monospacedDigit()

                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                        Text(next.time, style: .relative)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.75))

                    if !entry.locationName.isEmpty {
                        Text(entry.locationName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                } else {
                    Text("—")
                        .foregroundStyle(.white)
                }
            }
            .padding(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

nonisolated struct NextPrayerWidget: Widget {
    let kind: String = "NafsNextPrayer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    switch entry.family {
                    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                        Color.clear
                    default:
                        WidgetBackground()
                    }
                }
        }
        .configurationDisplayName("Next Prayer")
        .description("Your next salah with a live countdown. Add to Lock Screen for instant glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Lock Screen Daily Prayers Widget

struct DailyPrayersAccessoryView: View {
    let entry: PrayerTimesEntry
    @Environment(\.widgetFamily) private var family

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    private var nextPrayer: SharedPrayerTime? {
        WidgetPrayerLoader.nextPrayer(from: entry.prayers, now: entry.date)
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let n = nextPrayer {
                Text("\(n.name) \(Self.timeFormatter.string(from: n.time))")
            } else {
                Text("Nafs Prayers")
            }
        case .accessoryRectangular:
            rectangularView
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                if let n = nextPrayer {
                    VStack(spacing: 0) {
                        Text(n.name.prefix(4).uppercased())
                            .font(.system(size: 10, weight: .semibold))
                        Text(Self.timeFormatter.string(from: n.time))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(2)
                } else {
                    Image(systemName: "moon.stars.fill")
                }
            }
        default:
            PrayerTimesWidgetView(entry: entry)
        }
    }

    @ViewBuilder private var rectangularView: some View {
        let prayers = entry.prayers.prefix(5)
        if prayers.isEmpty {
            Text("Loading prayer times…")
        } else {
            HStack(spacing: 6) {
                ForEach(Array(prayers), id: \.name) { p in
                    VStack(spacing: 1) {
                        Text(String(p.name.prefix(3)).uppercased())
                            .font(.system(size: 9, weight: .bold))
                        Text(Self.timeFormatter.string(from: p.time))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(p.time < entry.date ? 0.5 : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

nonisolated struct DailyPrayersWidget: Widget {
    let kind: String = "NafsDailyPrayers"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            DailyPrayersAccessoryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Daily Prayers (Lock Screen)")
        .description("All five daily prayer times on your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

// MARK: - Hijri Date Widget

nonisolated struct HijriEntry: TimelineEntry {
    let date: Date
}

nonisolated struct HijriProvider: TimelineProvider {
    func placeholder(in context: Context) -> HijriEntry { HijriEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (HijriEntry) -> Void) { completion(HijriEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HijriEntry>) -> Void) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        completion(Timeline(entries: [HijriEntry(date: .now)], policy: .after(tomorrow)))
    }
}

struct HijriWidgetView: View {
    let entry: HijriEntry
    @Environment(\.widgetFamily) private var family

    private var hijri: (day: String, month: String, year: String) {
        let islamic = Calendar(identifier: .islamicUmmAlQura)
        let comps = islamic.dateComponents([.day, .month, .year], from: entry.date)
        let months = ["Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani", "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
        let monthIndex = max(0, min(11, (comps.month ?? 1) - 1))
        return ("\(comps.day ?? 1)", months[monthIndex], "\(comps.year ?? 0) AH")
    }

    private var gregorian: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: entry.date)
    }

    var body: some View {
        ZStack {
            WidgetCreamBackground()
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Hijri Date")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(WidgetTheme.gold)

                Text(hijri.day)
                    .font(.system(size: family == .systemSmall ? 44 : 56, weight: .bold, design: .serif))
                    .foregroundStyle(WidgetTheme.darkText)

                Text(hijri.month)
                    .font(.system(size: family == .systemSmall ? 13 : 16, weight: .semibold))
                    .foregroundStyle(WidgetTheme.gold)

                Text(hijri.year)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetTheme.darkText.opacity(0.6))

                Spacer(minLength: 0)

                Text(gregorian)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetTheme.darkText.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

nonisolated struct HijriDateWidget: Widget {
    let kind: String = "NafsHijriDate"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HijriProvider()) { entry in
            HijriWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetCreamBackground() }
        }
        .configurationDisplayName("Hijri Date")
        .description("Today's date on the Islamic calendar.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Prayer Streak Widget

nonisolated struct PrayerStreakSnapshot: Sendable {
    let streak: Int
    let completed: Int
    let total: Int
    let next: SharedPrayerTime?
}

nonisolated enum PrayerStreakLoader {
    static func load(for date: Date = .now) -> PrayerStreakSnapshot {
        let shared = WidgetTheme.shared
        let streak = shared?.integer(forKey: "nafs_widget_streakDays") ?? 0
        var completed = shared?.integer(forKey: "nafs_widget_completedToday") ?? 0
        let storedTotal = shared?.integer(forKey: "nafs_widget_totalToday") ?? 0
        let total = storedTotal > 0 ? storedTotal : 5

        // If the stored completion date isn't today, treat today's count as 0.
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        let todayKey = f.string(from: date)
        if let storedKey = shared?.string(forKey: "nafs_widget_completedDateKey"), storedKey != todayKey {
            completed = 0
        } else if shared?.string(forKey: "nafs_widget_completedDateKey") == nil {
            completed = 0
        }

        let times = WidgetPrayerLoader.load(for: date).times
        let next = WidgetPrayerLoader.nextPrayer(from: times, now: date)
        return PrayerStreakSnapshot(streak: streak, completed: completed, total: total, next: next)
    }
}

nonisolated struct PrayerStreakEntry: TimelineEntry {
    let date: Date
    let snapshot: PrayerStreakSnapshot
}

nonisolated struct PrayerStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerStreakEntry {
        PrayerStreakEntry(date: .now, snapshot: PrayerStreakLoader.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerStreakEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerStreakEntry>) -> Void) {
        let now = Date.now
        let entry = PrayerStreakEntry(date: now, snapshot: PrayerStreakLoader.load(for: now))
        let cal = Calendar(identifier: .gregorian)
        let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(3600)
        let nextPrayer = entry.snapshot.next?.time
        let refresh = [nextPrayer, nextMidnight].compactMap { $0 }.min() ?? nextMidnight
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct PrayerStreakWidgetView: View {
    let entry: PrayerStreakEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private var streakLabel: String {
        entry.snapshot.streak == 1 ? "Day Streak" : "Day Streak"
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemMedium, .systemLarge:
            mediumView
        default:
            smallView
        }
    }

    @ViewBuilder private var inlineView: some View {
        Text("\(entry.snapshot.streak)d streak · \(entry.snapshot.completed)/\(entry.snapshot.total)")
    }

    @ViewBuilder private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("DAY")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.6)
                    .opacity(0.85)
            }
            .padding(2)
        }
    }

    @ViewBuilder private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("PRAYER STREAK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(entry.snapshot.streak == 1 ? "day" : "days")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(0.85)
            }
            Text("\(entry.snapshot.completed)/\(entry.snapshot.total) prayers today")
                .font(.system(size: 10, weight: .medium))
                .opacity(0.85)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Home

    private var bg: Color {
        colorScheme == .dark ? WidgetTheme.ink : WidgetTheme.cream
    }
    private var primary: Color {
        colorScheme == .dark ? .white : WidgetTheme.darkText
    }
    private var secondary: Color {
        primary.opacity(0.6)
    }

    @ViewBuilder private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("STREAK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundStyle(WidgetTheme.gold)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.gold)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(entry.snapshot.streak == 1 ? "day" : "days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondary)
            }

            Spacer(minLength: 0)

            Text("\(entry.snapshot.completed)/\(entry.snapshot.total) today")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(primary)

            progressDots
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("PRAYER STREAK")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundStyle(WidgetTheme.gold)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(entry.snapshot.streak)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTheme.gold)
                    .monospacedDigit()
                Text(entry.snapshot.streak == 1 ? "Day Streak" : "Day Streak")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(primary)
            }

            Text("\(entry.snapshot.completed)/\(entry.snapshot.total) prayers today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(primary)

            progressDots

            Spacer(minLength: 0)

            if let next = entry.snapshot.next {
                HStack(spacing: 4) {
                    Image(systemName: "sun.and.horizon.fill")
                        .font(.system(size: 10))
                    Text("Next: \(next.name) · \(Self.timeFormatter.string(from: next.time))")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(secondary)
            }
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var progressDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<entry.snapshot.total, id: \.self) { i in
                Circle()
                    .fill(i < entry.snapshot.completed ? WidgetTheme.gold : primary.opacity(0.18))
                    .frame(width: 7, height: 7)
            }
        }
    }
}

nonisolated struct PrayerStreakWidget: Widget {
    let kind: String = "NafsPrayerStreak"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerStreakProvider()) { entry in
            PrayerStreakWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    PrayerStreakBackground()
                }
        }
        .configurationDisplayName("Prayer Streak")
        .description("Your prayer streak and today's progress at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

struct PrayerStreakBackground: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            Color.clear
        default:
            ZStack {
                colorScheme == .dark ? WidgetTheme.ink : WidgetTheme.cream
                GeometryReader { geo in
                    Circle()
                        .fill(WidgetTheme.gold.opacity(colorScheme == .dark ? 0.10 : 0.12))
                        .frame(width: geo.size.width * 0.9)
                        .offset(x: geo.size.width * 0.45, y: -geo.size.height * 0.3)
                }
            }
        }
    }
}

// MARK: - Daily Reflection Widget

nonisolated struct ReflectionEntry: TimelineEntry {
    let date: Date
    let text: String
}

nonisolated struct ReflectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReflectionEntry {
        ReflectionEntry(date: .now, text: NafsContentLibrary.todayReflection())
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectionEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectionEntry>) -> Void) {
        var entries: [ReflectionEntry] = []
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        for offset in 0..<4 {
            let date = cal.date(byAdding: .hour, value: offset * 6, to: start) ?? start
            entries.append(ReflectionEntry(date: date, text: NafsContentLibrary.todayReflection(for: date)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct ReflectionWidgetView: View {
    let entry: ReflectionEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            WidgetBackground()
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                    Text("Daily Reminder")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(WidgetTheme.gold)

                Text(entry.text)
                    .font(.system(size: family == .systemSmall ? 12 : 15, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Text("— Nafs")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WidgetTheme.gold)
                        .tracking(1.0)
                }
            }
            .padding(2)
        }
    }
}

nonisolated struct DailyReflectionWidget: Widget {
    let kind: String = "NafsDailyReflection"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReflectionProvider()) { entry in
            ReflectionWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Daily Reminder")
        .description("A short Islamic reflection to carry through your day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
