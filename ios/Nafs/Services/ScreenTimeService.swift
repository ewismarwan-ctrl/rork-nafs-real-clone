import SwiftUI
import FamilyControls
import ManagedSettings

@Observable
@MainActor
class ScreenTimeService {
    var activitySelection: FamilyActivitySelection = FamilyActivitySelection()
    var isAuthorized: Bool = false
    var isUnlocked: Bool = false
    var unlockExpiresAt: Date? = nil
    var isRequestingAuth: Bool = false
    var prayerModeEnabled: Bool = true
    var activePrayerLock: PrayerName?
    var lastLockedPrayerAt: Date?

    private let store: ManagedSettingsStore = ManagedSettingsStore(named: ManagedSettingsStore.Name("nafsPrayerLock"))
    private let defaults: UserDefaults = .standard
    private let appGroupID: String = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    var selectedAppCount: Int {
        activitySelection.applicationTokens.count
    }

    var selectedCategoryCount: Int {
        activitySelection.categoryTokens.count
    }

    var hasSelection: Bool {
        !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty
    }

    var remainingUnlockTime: TimeInterval? {
        guard let expiry = unlockExpiresAt, expiry > .now else { return nil }
        return expiry.timeIntervalSince(.now)
    }

    init() {
        checkAuthStatus()
        loadSelection()
        loadPrayerSettings()
        restoreUnlockState()
    }

    func requestAuthorization() async {
        isRequestingAuth = true
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
        isRequestingAuth = false
    }

    func onSelectionChanged() {
        saveSelection()
        syncSelectionToAppGroup()
        guard isAuthorized else { return }
        if activePrayerLock != nil && !isUnlocked {
            applyShields()
            return
        }
        let savedMode = defaults.string(forKey: "nafs_focusMode_v2") ?? "auto"
        if savedMode == "earn", !isUnlocked {
            applyShields()
        }
    }

    private func syncSelectionToAppGroup() {
        guard let shared = sharedDefaults else { return }
        if let data = try? PropertyListEncoder().encode(activitySelection) {
            shared.set(data, forKey: "nafs_familyActivitySelection")
        }
    }

    func applyDisciplineShields() {
        guard isAuthorized, hasSelection, !isUnlocked else { return }
        applyShields()
    }

    func applyShields() {
        let appTokens = activitySelection.applicationTokens
        let catTokens = activitySelection.categoryTokens
        store.shield.applications = appTokens.isEmpty ? nil : appTokens
        store.shield.applicationCategories = catTokens.isEmpty ? nil : .specific(catTokens)
        isUnlocked = false
        unlockExpiresAt = nil
        defaults.removeObject(forKey: "nafs_fcUnlockExpiry")
    }

    func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    func temporaryUnlock(minutes: Int) {
        let expiry = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        unlockExpiresAt = expiry
        isUnlocked = true
        removeShields()
        defaults.set(expiry, forKey: "nafs_fcUnlockExpiry")
        scheduleRelock(at: expiry)
    }

    func relockNow() {
        guard hasSelection, isAuthorized else { return }
        applyShields()
    }

    func clearAll() {
        store.clearAllSettings()
        activitySelection = FamilyActivitySelection()
        isUnlocked = false
        unlockExpiresAt = nil
        activePrayerLock = nil
        lastLockedPrayerAt = nil
        defaults.removeObject(forKey: "nafs_familyActivitySelection")
        defaults.removeObject(forKey: "nafs_fcUnlockExpiry")
        defaults.removeObject(forKey: "nafs_prayerActiveLock")
        defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
    }

    func isPrayerSelected(_ prayer: PrayerName) -> Bool {
        true
    }

    func evaluatePrayerLock(prayerTimes: [PrayerTime], focusMode: FocusMode?) {
        guard isAuthorized, hasSelection else { return }

        if let expiry = unlockExpiresAt, expiry <= .now {
            isUnlocked = false
            unlockExpiresAt = nil
            defaults.removeObject(forKey: "nafs_fcUnlockExpiry")
        }

        if focusMode == .earn {
            if !isUnlocked {
                applyShields()
            }
            return
        }

        guard focusMode == .auto else {
            if activePrayerLock == nil {
                removeShields()
            }
            return
        }

        if let activePrayerLock {
            if isPrayerCompleted(activePrayerLock, on: lastLockedPrayerAt ?? .now) {
                self.activePrayerLock = nil
                lastLockedPrayerAt = nil
                defaults.removeObject(forKey: "nafs_prayerActiveLock")
                defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
                removeShields()
            } else {
                if !isUnlocked {
                    applyShields()
                }
                persistActivePrayerLock(activePrayerLock)
                return
            }
        }

        let now: Date = .now
        let sortedPrayers = prayerTimes.sorted { $0.time < $1.time }

        let currentPrayer = sortedPrayers.last(where: { prayer in
            now >= prayer.time && !isPrayerCompleted(prayer.name, on: prayer.time)
        })

        if let currentPrayer {
            activatePrayerLock(currentPrayer.name, at: currentPrayer.time)
        } else {
            removeShields()
        }
    }

    func markPrayerComplete(prayerTimes: [PrayerTime]) {
        guard let activePrayerLock else { return }
        markPrayerCompleted(activePrayerLock, on: .now)
        markPrayerCompletedInAppGroup(activePrayerLock)
        self.activePrayerLock = nil
        lastLockedPrayerAt = nil
        defaults.removeObject(forKey: "nafs_prayerActiveLock")
        defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLock")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLockDate")
        removeShields()
        evaluatePrayerLock(prayerTimes: prayerTimes, focusMode: .auto)
        if self.activePrayerLock != nil {
            applyShields()
        }
    }

    private func markPrayerCompletedInAppGroup(_ prayer: PrayerName) {
        guard let shared = sharedDefaults else { return }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        let key = "nafs_prayerCompleted_\(prayer.rawValue)_\(f.string(from: Date()))"
        shared.set(true, forKey: key)
    }

    private func activatePrayerLock(_ prayer: PrayerName, at date: Date) {
        activePrayerLock = prayer
        lastLockedPrayerAt = date
        persistActivePrayerLock(prayer)
        applyShields()
    }

    private func persistActivePrayerLock(_ prayer: PrayerName) {
        defaults.set(prayer.rawValue, forKey: "nafs_prayerActiveLock")
        defaults.set(lastLockedPrayerAt ?? .now, forKey: "nafs_prayerActiveLockDate")
    }

    private func isPrayerCompleted(_ prayer: PrayerName, on date: Date) -> Bool {
        PrayerCompletionStore.isCompleted(prayer, on: date)
    }

    func completedPrayersToday() -> Int {
        PrayerCompletionStore.completedCount(on: .now)
    }

    func currentStreakDays() -> Int {
        PrayerCompletionStore.currentStreakDays()
    }

    private func markPrayerCompleted(_ prayer: PrayerName, on date: Date) {
        PrayerCompletionStore.markCompleted(prayer, on: date)
        SharedDataService.syncPrayerStreak()
    }

    /// Manually mark an arbitrary prayer complete (e.g. from Home tap-to-mark).
    /// If the prayer matches the active lock, shields are removed.
    @discardableResult
    func markPrayerCompleteManually(_ prayer: PrayerName, prayerTimes: [PrayerTime]) -> (count: Int, streak: Int) {
        markPrayerCompleted(prayer, on: .now)
        markPrayerCompletedInAppGroup(prayer)
        if activePrayerLock == prayer {
            activePrayerLock = nil
            lastLockedPrayerAt = nil
            defaults.removeObject(forKey: "nafs_prayerActiveLock")
            defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
            sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLock")
            sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLockDate")
            removeShields()
            evaluatePrayerLock(prayerTimes: prayerTimes, focusMode: .auto)
            if self.activePrayerLock != nil {
                applyShields()
            }
        }
        return (completedPrayersToday(), currentStreakDays())
    }

    private func checkAuthStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private func saveSelection() {
        if let data = try? PropertyListEncoder().encode(activitySelection) {
            defaults.set(data, forKey: "nafs_familyActivitySelection")
        }
    }

    private func loadSelection() {
        guard let data = defaults.data(forKey: "nafs_familyActivitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        activitySelection = selection
    }

    private func loadPrayerSettings() {
        if let rawPrayer = defaults.string(forKey: "nafs_prayerActiveLock"),
           let prayer = PrayerName(rawValue: rawPrayer) {
            activePrayerLock = prayer
        }

        if let storedDate = defaults.object(forKey: "nafs_prayerActiveLockDate") as? Date {
            lastLockedPrayerAt = storedDate
        }
    }

    private func restoreUnlockState() {
        if let expiry = defaults.object(forKey: "nafs_fcUnlockExpiry") as? Date {
            if expiry > .now {
                isUnlocked = true
                unlockExpiresAt = expiry
                removeShields()
                scheduleRelock(at: expiry)
                return
            } else {
                defaults.removeObject(forKey: "nafs_fcUnlockExpiry")
            }
        }

        if activePrayerLock != nil, hasSelection, isAuthorized {
            applyShields()
            return
        }

        let savedMode = defaults.string(forKey: "nafs_focusMode_v2") ?? "auto"
        if savedMode == "earn", hasSelection, isAuthorized {
            applyShields()
        }
    }

    private func scheduleRelock(at date: Date) {
        Task {
            let delay = date.timeIntervalSince(.now)
            guard delay > 0 else { return }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            if activePrayerLock != nil {
                applyShields()
            } else {
                relockNow()
            }
        }
    }
}
