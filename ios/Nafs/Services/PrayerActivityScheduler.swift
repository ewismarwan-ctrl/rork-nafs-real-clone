import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Schedules `DeviceActivitySchedule`s ahead of time so iOS activates the
/// shield at every prayer time, even when the Nafs app is fully closed.
///
/// We deliberately schedule one non-repeating activity per `(prayer × day)`
/// for the next 7 days. Using `repeats: true` with time-only components is
/// unreliable for prayer apps because:
///
/// - Prayer times shift slightly every day.
/// - Last-prayer windows wrap past midnight.
/// - When the app is opened mid-prayer-window, `repeats: true` re-anchors
///   the daily fire-time to "now+5s", which is then wrong on subsequent days.
///
/// Scheduling concrete dated windows ahead of time guarantees iOS can fire
/// `intervalDidStart` in the `DeviceActivityMonitorExtension` while the app
/// is closed — that's the whole point of this architecture.
@MainActor
final class PrayerActivityScheduler {
    static let shared = PrayerActivityScheduler()

    private let center = DeviceActivityCenter()
    private let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private let scheduleDays = 7

    private init() {}

    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    /// Schedule prayer windows for today and the upcoming days.
    ///
    /// - Parameters:
    ///   - prayerTimes: Today's prayer times, used as fallback if `upcomingDays` is empty.
    ///   - upcomingDays: Computed prayer times for the next N days. Each inner array is
    ///     one day's prayer times, ordered Fajr → Isha. Pass an empty array if not
    ///     available; this method will still schedule today.
    func updateSchedule(prayerTimes: [PrayerTime], upcomingDays: [[(name: String, time: Date)]] = []) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            print("[Nafs.Scheduler] skip — Family Controls not approved")
            return
        }

        let selection = loadSelection()
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            print("[Nafs.Scheduler] skip — no apps/categories selected; clearing schedules")
            center.stopMonitoring()
            sharedDefaults?.removeObject(forKey: "nafs_scheduledActivities")
            return
        }

        guard prayerLockEnabledFlag() else {
            print("[Nafs.Scheduler] skip — master prayer lock disabled; clearing schedules")
            center.stopMonitoring()
            sharedDefaults?.removeObject(forKey: "nafs_scheduledActivities")
            return
        }

        persistSelectionToAppGroup(selection)

        // Always start fresh — DeviceActivityCenter retains schedules across launches,
        // so we must clear stale ones before reseeding for the new prayer-time set.
        center.stopMonitoring()

        let allDays: [[PrayerEntry]] = buildDays(prayerTimes: prayerTimes, upcomingDays: upcomingDays)
        let now = Date.now
        var registered: [String: ScheduleRecord] = [:]
        var scheduledCount = 0

        for day in allDays {
            for (idx, prayer) in day.enumerated() {
                let start = prayer.time
                let end: Date
                if idx + 1 < day.count {
                    end = day[idx + 1].time
                } else {
                    // Isha → end shortly before midnight to avoid cross-day windows.
                    end = endOfDay(for: start)
                }

                guard end > now else { continue }

                let effectiveStart = max(start, now.addingTimeInterval(5))
                let activityName = activityName(for: prayer.name, on: start)

                let cal = Calendar.current
                let startComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: effectiveStart)
                let endComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)

                let schedule = DeviceActivitySchedule(
                    intervalStart: startComps,
                    intervalEnd: endComps,
                    repeats: false,
                    warningTime: nil
                )

                do {
                    try center.startMonitoring(DeviceActivityName(activityName), during: schedule)
                    registered[activityName] = ScheduleRecord(prayer: prayer.name, dayKey: dayKey(for: start))
                    scheduledCount += 1
                    print("[Nafs.Scheduler] registered \(activityName) start=\(effectiveStart) end=\(end)")
                } catch {
                    print("[Nafs.Scheduler] failed to register \(activityName): \(error)")
                }
            }
        }

        persistRegistry(registered)
        print("[Nafs.Scheduler] done — \(scheduledCount) prayer windows scheduled across \(allDays.count) day(s)")
    }

    func stopAll() {
        center.stopMonitoring()
        sharedDefaults?.removeObject(forKey: "nafs_scheduledActivities")
        print("[Nafs.Scheduler] stopped all schedules")
    }

    // MARK: - Helpers

    private struct PrayerEntry {
        let name: PrayerName
        let time: Date
    }

    private struct ScheduleRecord: Codable {
        let prayer: String
        let dayKey: String

        init(prayer: PrayerName, dayKey: String) {
            self.prayer = prayer.rawValue
            self.dayKey = dayKey
        }
    }

    private func buildDays(
        prayerTimes: [PrayerTime],
        upcomingDays: [[(name: String, time: Date)]]
    ) -> [[PrayerEntry]] {
        if upcomingDays.isEmpty {
            let today = prayerTimes
                .compactMap { p -> PrayerEntry? in
                    PrayerEntry(name: p.name, time: p.time)
                }
                .sorted { $0.time < $1.time }
            return today.isEmpty ? [] : [today]
        }
        return upcomingDays.prefix(scheduleDays).map { day in
            day.compactMap { entry -> PrayerEntry? in
                guard let name = PrayerName(rawValue: entry.name) else { return nil }
                return PrayerEntry(name: name, time: entry.time)
            }
            .sorted { $0.time < $1.time }
        }
    }

    private func endOfDay(for date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = 23
        comps.minute = 59
        comps.second = 0
        return cal.date(from: comps) ?? date.addingTimeInterval(6 * 3600)
    }

    private func activityName(for prayer: PrayerName, on date: Date) -> String {
        "prayer_\(prayer.rawValue)_\(dayKey(for: date))"
    }

    private func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func loadSelection() -> FamilyActivitySelection {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "nafs_familyActivitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }

    private func persistSelectionToAppGroup(_ selection: FamilyActivitySelection) {
        guard let shared = sharedDefaults else { return }
        if let data = try? PropertyListEncoder().encode(selection) {
            shared.set(data, forKey: "nafs_familyActivitySelection")
        }
    }

    private func persistRegistry(_ registry: [String: ScheduleRecord]) {
        guard let shared = sharedDefaults else { return }
        if let data = try? JSONEncoder().encode(registry) {
            shared.set(data, forKey: "nafs_scheduledActivities")
        }
    }

    private func prayerLockEnabledFlag() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "nafs_prayerLockEnabled_v1") == nil { return true }
        return defaults.bool(forKey: "nafs_prayerLockEnabled_v1")
    }
}
