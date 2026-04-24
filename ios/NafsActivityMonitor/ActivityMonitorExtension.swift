import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

nonisolated final class ActivityMonitorExtension: DeviceActivityMonitor {
    private static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private static let storeName = ManagedSettingsStore.Name("nafsPrayerLock")

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShieldsIfNeeded(activity: activity)
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Keep shields on. Main app clears them after prayer is marked complete.
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    private nonisolated func applyShieldsIfNeeded(activity: DeviceActivityName) {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }

        // If user has explicitly unlocked (prayer completed), skip.
        let prayerKey = activity.rawValue
        let completedKey = "nafs_prayerCompleted_\(prayerKey)_\(Self.todayString())"
        if defaults.bool(forKey: completedKey) { return }

        guard let data = defaults.data(forKey: "nafs_familyActivitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }

        let store = ManagedSettingsStore(named: Self.storeName)
        let appTokens = selection.applicationTokens
        let catTokens = selection.categoryTokens
        store.shield.applications = appTokens.isEmpty ? nil : appTokens
        store.shield.applicationCategories = catTokens.isEmpty ? nil : .specific(catTokens)

        defaults.set(prayerKey, forKey: "nafs_prayerActiveLock")
        defaults.set(Date(), forKey: "nafs_prayerActiveLockDate")
    }

    private nonisolated static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
