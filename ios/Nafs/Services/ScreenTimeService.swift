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

    /// Tracks the last applied shield state so we can skip redundant
    /// ManagedSettingsStore writes. Writing to the store is comparatively
    /// expensive and was being called every Focus-screen tick, which made
    /// lock/unlock feel slow.
    private var lastAppliedAppTokens: Set<ApplicationToken>? = nil
    private var lastAppliedCategoryTokens: Set<ActivityCategoryToken>? = nil
    private var shieldsActive: Bool = false
    private let appGroupID: String = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }
    private let prayerLockEnabledKey: String = "nafs_prayerLockEnabled_v1"

    /// Master switch — when off, no prayer-driven shields are ever applied.
    var prayerLockEnabled: Bool {
        if defaults.object(forKey: prayerLockEnabledKey) == nil { return true }
        return defaults.bool(forKey: prayerLockEnabledKey)
    }

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
        guard prayerLockEnabled else {
            removeShields()
            return
        }
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
        // Skip the ManagedSettings write if nothing changed — repeated writes
        // here are the main cause of the laggy lock/unlock UX.
        if shieldsActive,
           lastAppliedAppTokens == appTokens,
           lastAppliedCategoryTokens == catTokens {
            isUnlocked = false
            unlockExpiresAt = nil
            return
        }
        store.shield.applications = appTokens.isEmpty ? nil : appTokens
        store.shield.applicationCategories = catTokens.isEmpty ? nil : .specific(catTokens)
        lastAppliedAppTokens = appTokens
        lastAppliedCategoryTokens = catTokens
        shieldsActive = true
        isUnlocked = false
        unlockExpiresAt = nil
        defaults.removeObject(forKey: "nafs_fcUnlockExpiry")
    }

    func removeShields() {
        if !shieldsActive && lastAppliedAppTokens == nil && lastAppliedCategoryTokens == nil {
            return
        }
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        lastAppliedAppTokens = nil
        lastAppliedCategoryTokens = nil
        shieldsActive = false
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

        guard prayerLockEnabled else {
            activePrayerLock = nil
            lastLockedPrayerAt = nil
            defaults.removeObject(forKey: "nafs_prayerActiveLock")
            defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
            removeShields()
            return
        }

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

        // Only the *current* prayer window can trigger a lock. A prayer that
        // was missed and is now in the past (i.e. a later prayer has already
        // started) must not retroactively re-lock — otherwise marking the
        // current prayer complete would immediately re-shield for an older
        // missed prayer, which is what made apps appear to "lock again".
        let currentWindowPrayer = sortedPrayers.last(where: { $0.time <= now })
        if let currentWindowPrayer,
           !isPrayerCompleted(currentWindowPrayer.name, on: currentWindowPrayer.time) {
            activatePrayerLock(currentWindowPrayer.name, at: currentWindowPrayer.time)
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

        guard prayerLockEnabled else {
            activePrayerLock = nil
            lastLockedPrayerAt = nil
            defaults.removeObject(forKey: "nafs_prayerActiveLock")
            defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
            removeShields()
            return
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

    /// Persist the prayer-lock master switch and immediately reflect it in shields.
    func setPrayerLockEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: prayerLockEnabledKey)
        sharedDefaults?.set(enabled, forKey: prayerLockEnabledKey)
        if enabled { return }
        activePrayerLock = nil
        lastLockedPrayerAt = nil
        defaults.removeObject(forKey: "nafs_prayerActiveLock")
        defaults.removeObject(forKey: "nafs_prayerActiveLockDate")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLock")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLockDate")
        removeShields()
        // Cancel every pre-scheduled DeviceActivity window so the extension
        // doesn't reapply shields while the app is closed.
        PrayerActivityScheduler.shared.stopAll()
    }

    /// Convenience entry-point used by surfaces (e.g. Home) that don't hold a
    /// long-lived `ScreenTimeService` instance. Persists completion to both
    /// standard defaults *and* the app group, and — if the just-completed
    /// prayer matches the currently active lock — removes the shield so apps
    /// don't stay locked after the user marks the prayer complete from Home.
    static func recordPrayerCompletion(_ prayer: PrayerName) {
        PrayerCompletionStore.markCompleted(prayer, on: .now)
        SharedDataService.syncPrayerStreak()

        let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
        let shared = UserDefaults(suiteName: appGroupID)
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        shared?.set(true, forKey: "nafs_prayerCompleted_\(prayer.rawValue)_\(f.string(from: Date()))")

        let standard = UserDefaults.standard
        let active = standard.string(forKey: "nafs_prayerActiveLock")
        if active == prayer.rawValue {
            standard.removeObject(forKey: "nafs_prayerActiveLock")
            standard.removeObject(forKey: "nafs_prayerActiveLockDate")
            shared?.removeObject(forKey: "nafs_prayerActiveLock")
            shared?.removeObject(forKey: "nafs_prayerActiveLockDate")
            let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("nafsPrayerLock"))
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
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
