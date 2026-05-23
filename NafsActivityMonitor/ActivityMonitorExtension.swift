import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation
import os

/// `DeviceActivityMonitor` subclass that iOS instantiates in the background
/// at every scheduled prayer-window boundary. It runs even when the Nafs app
/// is fully closed, which is the entire reason prayer-lock blocking has to be
/// driven by `DeviceActivitySchedule` and not by in-app timers.
nonisolated final class ActivityMonitorExtension: DeviceActivityMonitor {
    private static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private static let storeName = ManagedSettingsStore.Name("nafsPrayerLock")
    private static let log = Logger(subsystem: "app.rork.nafs", category: "ActivityMonitor")

    nonisolated override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        Self.log.info("intervalDidStart: \(activity.rawValue, privacy: .public)")
        applyShieldsIfNeeded(activity: activity)
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        Self.log.info("intervalDidEnd: \(activity.rawValue, privacy: .public)")
        // Shields stay on. The main app removes them once the user marks
        // the prayer complete; otherwise the next prayer's interval reapplies.
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    private nonisolated func applyShieldsIfNeeded(activity: DeviceActivityName) {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID) else {
            Self.log.error("missing app-group defaults; cannot apply shield")
            return
        }

        // Master switch — if the user disabled prayer lock entirely, never shield.
        if defaults.object(forKey: "nafs_prayerLockEnabled_v1") != nil,
           defaults.bool(forKey: "nafs_prayerLockEnabled_v1") == false {
            Self.log.info("master prayer lock disabled; skipping shield for \(activity.rawValue, privacy: .public)")
            return
        }

        // Resolve activity → (prayer, dayKey) via the registry written by the app.
        let record = Self.lookupRecord(activity: activity, defaults: defaults)
        let prayerKey = record?.prayer ?? activity.rawValue
        let dayKey = record?.dayKey ?? Self.todayString()

        // Don't reapply shield if the user already prayed for that prayer & day.
        let appCompletedKey = "nafs_prayerComplete_\(dayKey)_\(prayerKey)"
        let groupCompletedKey = "nafs_prayerCompleted_\(prayerKey)_\(dayKey)"
        if defaults.bool(forKey: appCompletedKey) || defaults.bool(forKey: groupCompletedKey) {
            Self.log.info("prayer \(prayerKey, privacy: .public) on \(dayKey, privacy: .public) already completed; skipping shield")
            return
        }

        guard let data = defaults.data(forKey: "nafs_familyActivitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            Self.log.error("no FamilyActivitySelection in app group; cannot shield")
            return
        }

        let store = ManagedSettingsStore(named: Self.storeName)
        let appTokens = selection.applicationTokens
        let catTokens = selection.categoryTokens
        store.shield.applications = appTokens.isEmpty ? nil : appTokens
        store.shield.applicationCategories = catTokens.isEmpty ? nil : .specific(catTokens)

        defaults.set(prayerKey, forKey: "nafs_prayerActiveLock")
        defaults.set(Date(), forKey: "nafs_prayerActiveLockDate")

        Self.log.info("shield applied for \(prayerKey, privacy: .public) (\(appTokens.count) apps, \(catTokens.count) categories)")
    }

    private nonisolated static func lookupRecord(activity: DeviceActivityName, defaults: UserDefaults) -> ScheduleRecord? {
        guard let data = defaults.data(forKey: "nafs_scheduledActivities"),
              let registry = try? JSONDecoder().decode([String: ScheduleRecord].self, from: data) else {
            return nil
        }
        return registry[activity.rawValue]
    }

    private nonisolated static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

private nonisolated struct ScheduleRecord: Codable {
    let prayer: String
    let dayKey: String
}
