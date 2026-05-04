import SwiftUI
import WidgetKit

@Observable
@MainActor
class AppViewModel {
    var userName: String {
        get { UserDefaults.standard.string(forKey: "nafs_userName") ?? "Friend" }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_userName") }
    }

    var isPremium: Bool = false

    var streakDays: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_streakDays") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_streakDays") }
    }

    var prayerConsistency: Double = 0.0
    var quranStreak: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_quranStreak") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_quranStreak") }
    }
    var screenTimeReduced: Int = 0

    var gardenTrees: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_gardenTrees") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_gardenTrees") }
    }
    var gardenFlowers: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_gardenFlowers") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_gardenFlowers") }
    }
    var gardenOrbs: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_gardenOrbs") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_gardenOrbs") }
    }
    var gardenBlooms: Int {
        get { UserDefaults.standard.integer(forKey: "nafs_gardenBlooms") }
        set { UserDefaults.standard.set(newValue, forKey: "nafs_gardenBlooms") }
    }

    var todayLogs: Set<String> = []

    var prayerTimes: [PrayerTime] = []
    var blockedApps: [BlockedApp] = []

    var storeViewModel: StoreViewModel?
    let prayerService = PrayerTimeService()
    let focusEconomy = FocusEconomyService()

    var tasbihCount: Int = 0
    var showFreePlanBanner: Bool = false
    var freePlanTimer: Int = 0
    var showPremiumGate: Bool = false
    var premiumGateFeature: String = ""
    var premiumGateBenefit: String = ""

    var calculationMethod: PrayerCalculationMethod {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "nafs_calcMethod"),
                  let method = PrayerCalculationMethod(rawValue: raw) else { return .isna }
            return method
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "nafs_calcMethod")
            Task { await refreshPrayerTimes(forceRecompute: true) }
        }
    }

    var asrMadhab: AsrMadhab {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "nafs_asrMadhab"),
                  let madhab = AsrMadhab(rawValue: raw) else { return .shafi }
            return madhab
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "nafs_asrMadhab")
            Task { await refreshPrayerTimes(forceRecompute: true) }
        }
    }

    var dailyAyahNotifications: Bool = true
    var prayerNotifications: [PrayerName: Bool] = [
        .fajr: true, .dhuhr: true, .asr: true, .maghrib: true, .isha: true
    ]

    var scaleState: ScaleState {
        if streakDays == 0 && prayerConsistency == 0 { return .balanced }
        if prayerConsistency >= 0.9 { return .balanced }
        if prayerConsistency >= 0.7 { return .tippingGold }
        if prayerConsistency >= 0.4 { return .tippingDark }
        return .fallen
    }

    var hijriDate: String {
        let islamic = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = islamic
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: .now) + " AH"
    }

    private static let motivationalLines = [
        "What will you earn for Allah today?",
        "Your deen is your greatest asset.",
        "Every deed counts. Start now.",
        "The best investment is in your akhirah.",
        "MashaAllah — another day, another chance.",
    ]

    var dailyMotivation: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return Self.motivationalLines[dayOfYear % Self.motivationalLines.count]
    }

    var nextPrayer: PrayerTime? {
        let now = Date.now
        return prayerTimes.sorted { $0.time < $1.time }.first(where: { $0.time > now })
    }

    var nextPrayerCountdown: String {
        guard let next = nextPrayer else { return "Now" }
        let diff = next.time.timeIntervalSince(.now)
        if diff <= 0 { return "Now" }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    init() {
        loadPersistedData()
        loadBlockedApps()
        checkAndRelockExpiredApps()
        Task {
            await refreshPrayerTimes()
        }
        if !isPremium {
            startFreePlanTimer()
        }
        startPrayerCountdownTimer()
        let hasUnlocked = blockedApps.contains(where: { !$0.isLocked && $0.unlockExpiresAt != nil })
        if hasUnlocked { scheduleRelockCheck() }
    }

    func refreshPrayerTimes(forceRecompute: Bool = false) async {
        if forceRecompute { prayerService.invalidateCache() }
        await prayerService.fetchPrayerTimes(method: calculationMethod, madhab: asrMadhab)
        prayerTimes = prayerService.prayerTimes
        NotificationService.shared.schedulePrayerNotifications(
            prayerTimes: prayerTimes,
            enabledPrayers: prayerNotifications,
            cityName: prayerService.locationName
        )
        PrayerActivityScheduler.shared.updateSchedule(prayerTimes: prayerTimes)
        // Only push real, location-based prayer times to widgets.
        // Otherwise the widget would display stale/fallback hours that
        // don't match the user's device or location.
        if prayerService.hasRealLocationData {
            SharedDataService.syncPrayerTimes(
                prayerTimes.map { (name: $0.name.rawValue, time: $0.time) },
                locationName: prayerService.locationName
            )
            // Pre-compute next 7 days so widgets stay accurate even when the app isn't opened.
            let multiDay = await prayerService.computeUpcomingDays(
                method: calculationMethod,
                madhab: asrMadhab,
                days: 7
            )
            SharedDataService.syncMultiDayPrayerTimes(multiDay)
        }
        SharedDataService.syncPrayerStreak()
    }

    func requirePremium(feature: String, benefit: String) -> Bool {
        guard !isPremium else { return true }
        premiumGateFeature = feature
        premiumGateBenefit = benefit
        showPremiumGate = true
        return false
    }

    private func logKey(for habit: HabitType) -> String {
        switch habit.frequency {
        case .daily:
            return habit.rawValue + "_" + DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
        case .weekly:
            let cal = Calendar.current
            let week = cal.component(.weekOfYear, from: .now)
            let year = cal.component(.yearForWeekOfYear, from: .now)
            return habit.rawValue + "_W\(year)-\(week)"
        }
    }

    func logHabit(_ habit: HabitType) -> Bool {
        guard isPremium else {
            _ = requirePremium(feature: "Habit Logging", benefit: "Your deeds deserve to be counted. Start your free trial.")
            return false
        }
        let key = logKey(for: habit)
        guard !todayLogs.contains(key) else { return false }
        todayLogs.insert(key)
        saveTodayLogs()

        updateGardenFromHabit(habit)
        updateStreak()
        updateHabitStreak(habit)
        awardFocusMinutes(for: habit)

        return true
    }

    private func awardFocusMinutes(for habit: HabitType) {
        focusEconomy.earn(baseMinutes: habit.screenTimeMinutes)
    }

    func canLogHabit(_ habit: HabitType) -> Bool {
        guard isPremium else { return true }
        return !todayLogs.contains(logKey(for: habit))
    }

    func habitStreak(_ habit: HabitType) -> Int {
        UserDefaults.standard.integer(forKey: "nafs_habitStreak_\(habit.rawValue)")
    }

    private func updateHabitStreak(_ habit: HabitType) {
        let lastKey = "nafs_habitLastLog_\(habit.rawValue)"
        let streakKey = "nafs_habitStreak_\(habit.rawValue)"
        let cal = Calendar.current
        let last = UserDefaults.standard.object(forKey: lastKey) as? Date
        let now = Date.now
        var current = UserDefaults.standard.integer(forKey: streakKey)

        switch habit.frequency {
        case .daily:
            if let last {
                if cal.isDateInToday(last) { return }
                if cal.isDateInYesterday(last) { current += 1 } else { current = 1 }
            } else {
                current = 1
            }
        case .weekly:
            let nowWeek = cal.component(.weekOfYear, from: now)
            let nowYear = cal.component(.yearForWeekOfYear, from: now)
            if let last {
                let lastWeek = cal.component(.weekOfYear, from: last)
                let lastYear = cal.component(.yearForWeekOfYear, from: last)
                if lastWeek == nowWeek && lastYear == nowYear { return }
                let diffWeeks = (nowYear - lastYear) * 52 + (nowWeek - lastWeek)
                if diffWeeks == 1 { current += 1 } else { current = 1 }
            } else {
                current = 1
            }
        }
        UserDefaults.standard.set(current, forKey: streakKey)
        UserDefaults.standard.set(now, forKey: lastKey)
    }

    var optionalHabits: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: "nafs_optionalHabits") ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "nafs_optionalHabits")
        }
    }

    func toggleOptionalHabit(_ habit: HabitType) {
        var current = optionalHabits
        if current.contains(habit.rawValue) {
            current.remove(habit.rawValue)
        } else {
            current.insert(habit.rawValue)
        }
        optionalHabits = current
    }

    func unlockAllForMinutes(_ minutes: Int) {
        let expiry = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        for idx in blockedApps.indices {
            blockedApps[idx].isLocked = false
            blockedApps[idx].unlockExpiresAt = expiry
        }
        saveBlockedApps()
        scheduleRelockCheck()
    }

    func addBlockedApp(name: String, icon: String, color: String) {
        guard !blockedApps.contains(where: { $0.name == name }) else { return }
        let app = BlockedApp(name: name, icon: icon, color: color, isLocked: true)
        blockedApps.append(app)
        saveBlockedApps()
    }

    func removeBlockedApp(_ app: BlockedApp) {
        blockedApps.removeAll(where: { $0.id == app.id })
        saveBlockedApps()
    }

    func relockApp(_ app: BlockedApp) {
        if let idx = blockedApps.firstIndex(where: { $0.id == app.id }) {
            blockedApps[idx].isLocked = true
            blockedApps[idx].unlockExpiresAt = nil
            saveBlockedApps()
        }
    }

    func checkAndRelockExpiredApps() {
        var changed = false
        for i in blockedApps.indices {
            if !blockedApps[i].isLocked,
               let expiry = blockedApps[i].unlockExpiresAt,
               Date.now >= expiry {
                blockedApps[i].isLocked = true
                blockedApps[i].unlockExpiresAt = nil
                changed = true
            }
        }
        if changed { saveBlockedApps() }
    }

    private func scheduleRelockCheck() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                checkAndRelockExpiredApps()
                let hasUnlocked = blockedApps.contains(where: { !$0.isLocked && $0.unlockExpiresAt != nil })
                if !hasUnlocked { break }
            }
        }
    }

    func purchasePremium() async -> Bool {
        guard let store = storeViewModel else { return false }
        if store.offerings == nil || store.yearlyPackage == nil {
            await store.fetchOfferings()
        }
        if let pkg = store.yearlyPackage {
            return await store.purchase(package: pkg)
        }
        return false
    }

    private func updateGardenFromHabit(_ habit: HabitType) {
        switch habit {
        case .fardOnTime, .fardLate:
            gardenTrees += 1
        case .quran:
            gardenFlowers += 1
            quranStreak += 1
        case .dhikr:
            gardenOrbs += 1
        case .voluntaryFast:
            gardenBlooms += 1
        default:
            break
        }
    }

    private func updateStreak() {
        let lastLogDate = UserDefaults.standard.string(forKey: "nafs_lastLogDate") ?? ""
        let todayStr = DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)

        if lastLogDate != todayStr {
            let yesterdayStr = DateFormatter.localizedString(
                from: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
                dateStyle: .short, timeStyle: .none
            )
            if lastLogDate == yesterdayStr {
                streakDays += 1
            } else if lastLogDate.isEmpty {
                streakDays = 1
            } else {
                streakDays = 1
            }
            UserDefaults.standard.set(todayStr, forKey: "nafs_lastLogDate")
        }
    }

    private func loadPersistedData() {
        loadTodayLogs()
        recalculateConsistency()
    }

    private func loadTodayLogs() {
        let todayStr = DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none)
        let savedDate = UserDefaults.standard.string(forKey: "nafs_todayLogsDate") ?? ""
        if savedDate == todayStr {
            if let data = UserDefaults.standard.data(forKey: "nafs_todayLogs"),
               let saved = try? JSONDecoder().decode(Set<String>.self, from: data) {
                todayLogs = saved
            }
        } else {
            todayLogs = []
            UserDefaults.standard.set(todayStr, forKey: "nafs_todayLogsDate")
            saveTodayLogs()
        }
    }

    private func saveTodayLogs() {
        if let data = try? JSONEncoder().encode(todayLogs) {
            UserDefaults.standard.set(data, forKey: "nafs_todayLogs")
        }
    }

    private func saveBlockedApps() {
        if let data = try? JSONEncoder().encode(blockedApps) {
            UserDefaults.standard.set(data, forKey: "nafs_blockedApps")
        }
    }

    private func loadBlockedApps() {
        guard let data = UserDefaults.standard.data(forKey: "nafs_blockedApps"),
              let saved = try? JSONDecoder().decode([BlockedApp].self, from: data) else { return }
        blockedApps = saved
    }

    private func recalculateConsistency() {
        let cal = Calendar.current
        let days = PrayerCompletionStore.recentDays(7, calendar: cal)
        let total = days.reduce(0) { $0 + PrayerCompletionStore.completedCount(on: $1) }
        let maxPossible = PrayerName.allCases.count * 7
        prayerConsistency = maxPossible > 0 ? min(Double(total) / Double(maxPossible), 1.0) : 0
    }

    private func startFreePlanTimer() {
        Task {
            try? await Task.sleep(for: .seconds(60))
            showFreePlanBanner = true
        }
    }

    private func startPrayerCountdownTimer() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                let now = Date.now
                let sorted = prayerTimes.sorted { $0.time < $1.time }
                var foundNext = false
                prayerTimes = sorted.map { prayer in
                    let isNext = !foundNext && prayer.time > now
                    if isNext { foundNext = true }
                    return PrayerTime(id: prayer.name.rawValue, name: prayer.name, time: prayer.time, isNext: isNext)
                }

                let needsRefresh = prayerTimes.last?.time ?? .distantFuture < now
                if needsRefresh {
                    await refreshPrayerTimes()
                }
            }
        }
    }
}


