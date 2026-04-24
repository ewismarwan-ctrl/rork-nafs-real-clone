import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

@MainActor
final class PrayerActivityScheduler {
    static let shared = PrayerActivityScheduler()

    private let center = DeviceActivityCenter()
    private let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"

    private init() {}

    func updateSchedule(prayerTimes: [PrayerTime]) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else { return }

        let selection = loadSelection()
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            center.stopMonitoring()
            return
        }

        persistSelectionToAppGroup(selection)

        center.stopMonitoring()

        let cal = Calendar.current
        let now = Date.now

        for (idx, prayer) in prayerTimes.enumerated() {
            let start = prayer.time
            let end: Date
            if idx + 1 < prayerTimes.count {
                end = prayerTimes[idx + 1].time
            } else {
                end = cal.date(byAdding: .hour, value: 6, to: start) ?? start.addingTimeInterval(6 * 3600)
            }

            guard end > now else { continue }

            let effectiveStart = max(start, now.addingTimeInterval(5))

            let startComps = cal.dateComponents([.hour, .minute, .second], from: effectiveStart)
            let endComps = cal.dateComponents([.hour, .minute, .second], from: end)

            let schedule = DeviceActivitySchedule(
                intervalStart: startComps,
                intervalEnd: endComps,
                repeats: true,
                warningTime: nil
            )

            let name = DeviceActivityName(prayer.name.rawValue)
            do {
                try center.startMonitoring(name, during: schedule)
            } catch {
                print("[Nafs] Failed to schedule \(prayer.name.rawValue): \(error)")
            }
        }
    }

    func stopAll() {
        center.stopMonitoring()
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
        guard let shared = UserDefaults(suiteName: appGroupID) else { return }
        if let data = try? PropertyListEncoder().encode(selection) {
            shared.set(data, forKey: "nafs_familyActivitySelection")
        }
    }
}
