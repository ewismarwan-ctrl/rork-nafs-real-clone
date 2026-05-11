import Foundation
import SwiftUI
import WidgetKit

/// Developer / marketing tools service.
///
/// Provides a single place to:
/// - detect whether internal-testing tools should be exposed
/// - manually trigger demo states (lock/unlock, success screen)
/// - reset onboarding / paywall / prayer / widget state for repeated capture
///
/// `isAvailable` is `true` only for DEBUG builds and TestFlight builds.
/// Production App Store builds always hide these tools — guaranteed by the
/// receipt path check below.
@MainActor
@Observable
final class DevToolsService {
    static let shared = DevToolsService()

    private let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    // MARK: - Visibility

    /// Production App Store builds ship with a production receipt. TestFlight
    /// builds (and the Simulator) ship with a sandbox receipt. DEBUG builds
    /// are always allowed.
    nonisolated static var isAvailable: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlightBuild
        #endif
    }

    nonisolated static var isTestFlightBuild: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.lastPathComponent == "sandboxReceipt"
    }

    nonisolated static var buildLabel: String {
        #if DEBUG
        return "Debug"
        #else
        return isTestFlightBuild ? "TestFlight" : "Release"
        #endif
    }

    // MARK: - State surfaced to the UI

    var lastActionMessage: String = ""
    private(set) var didFlash: Bool = false

    private func flash(_ message: String) {
        lastActionMessage = message
        didFlash.toggle()
    }

    // MARK: - Manual lock / unlock

    /// Apply real Family Controls shields immediately, regardless of prayer time.
    func manualLockNow(using service: ScreenTimeService) {
        guard service.isAuthorized, service.hasSelection else {
            flash("Select apps in Focus first")
            return
        }
        service.applyShields()
        flash("Shields applied to selected apps")
    }

    /// Remove all shields immediately and clear any demo prayer state.
    func manualUnlockNow(using service: ScreenTimeService) {
        service.removeShields()
        service.isUnlocked = true
        service.activePrayerLock = nil
        clearDemoPrayerState()
        flash("Shields removed")
    }

    // MARK: - Demo presets (write fake prayer data to the App Group so the
    //         real ShieldConfigurationExtension renders the desired text)

    enum DemoPreset {
        case maghribTikTok
        case asrInstagram

        var prayer: PrayerName {
            switch self {
            case .maghribTikTok: return .maghrib
            case .asrInstagram: return .asr
            }
        }

        var appLabel: String {
            switch self {
            case .maghribTikTok: return "TikTok"
            case .asrInstagram: return "Instagram"
            }
        }
    }

    /// Writes a synthetic "current prayer" snapshot to the App Group so the
    /// Shield extension picks up the desired prayer name on next render.
    /// Then triggers the real shields on whatever apps the user selected.
    func triggerLockDemo(_ preset: DemoPreset, using service: ScreenTimeService) {
        writeDemoPrayerSnapshot(currentPrayer: preset.prayer)
        guard service.isAuthorized, service.hasSelection else {
            flash("Demo armed — pick apps in Focus to see the shield")
            return
        }
        service.applyShields()
        flash("\(preset.prayer.rawValue) lock demo armed for \(preset.appLabel)")
    }

    private func writeDemoPrayerSnapshot(currentPrayer: PrayerName) {
        guard let shared = sharedDefaults else { return }
        let now = Date()
        let cal = Calendar.current
        // Place the chosen prayer 1 minute in the past, others scattered so it
        // is selected as "the current prayer" by the Shield extension.
        let order: [PrayerName] = PrayerName.allCases
        let idx = order.firstIndex(of: currentPrayer) ?? 0
        let times: [(String, Date)] = order.enumerated().map { (i, name) in
            let offsetMinutes: Int
            if i < idx { offsetMinutes = -(idx - i) * 60 }
            else if i == idx { offsetMinutes = -1 }
            else { offsetMinutes = (i - idx) * 60 }
            let date = cal.date(byAdding: .minute, value: offsetMinutes, to: now) ?? now
            return (name.rawValue, date)
        }

        struct SharedPrayerTime: Codable { let name: String; let time: Date }
        let payload = times.map { SharedPrayerTime(name: $0.0, time: $0.1) }
        if let data = try? JSONEncoder().encode(payload) {
            shared.set(data, forKey: "nafs_prayerTimes")
        }
        shared.set(true, forKey: "nafs_devDemoActive")
    }

    private func clearDemoPrayerState() {
        guard let shared = sharedDefaults else { return }
        shared.removeObject(forKey: "nafs_devDemoActive")
    }

    // MARK: - Demo data setters

    /// Mark the first `count` prayers complete for today (idempotent).
    func setTodayProgress(_ count: Int) {
        let clamped = max(0, min(PrayerName.allCases.count, count))
        for (i, prayer) in PrayerName.allCases.enumerated() {
            if i < clamped {
                PrayerCompletionStore.markCompleted(prayer, on: .now)
            } else {
                PrayerCompletionStore.resetCompletion(prayer, on: .now)
            }
        }
        SharedDataService.syncPrayerStreak()
        flash("Today set to \(clamped)/\(PrayerName.allCases.count)")
    }

    /// Build a synthetic streak by marking every prayer complete for the
    /// previous `days - 1` days plus today. This is real data (no override
    /// flag) so every surface — widgets, Focus, Home — picks it up.
    func setStreakDays(_ days: Int) {
        let clamped = max(0, min(365, days))
        let cal = Calendar.current
        for offset in 0..<clamped {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            for prayer in PrayerName.allCases {
                PrayerCompletionStore.markCompleted(prayer, on: day)
            }
        }
        SharedDataService.syncPrayerStreak()
        flash("Streak set to \(clamped) days")
    }

    /// Push current values straight to the widget App Group keys so widgets
    /// repaint immediately for screenshots/videos.
    func refreshWidgetDemoState() {
        SharedDataService.syncPrayerStreak()
        WidgetCenter.shared.reloadAllTimelines()
        flash("Widget timelines reloaded")
    }

    // MARK: - Resets

    func resetOnboarding() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "hasSeenWelcome")
        flash("Onboarding reset — relaunch to see it")
    }

    func resetPaywallSeenState() {
        let defaults = UserDefaults.standard
        let prefixes = ["nafs_paywall", "nafs.paywall", "nafs_seenPaywall"]
        for key in defaults.dictionaryRepresentation().keys
        where prefixes.contains(where: { key.hasPrefix($0) }) {
            defaults.removeObject(forKey: key)
        }
        flash("Paywall seen state cleared")
    }

    func resetPrayerProgress() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("nafs_prayerComplete_") {
            defaults.removeObject(forKey: key)
        }
        if let shared = sharedDefaults {
            for key in shared.dictionaryRepresentation().keys
            where key.hasPrefix("nafs_prayerCompleted_") {
                shared.removeObject(forKey: key)
            }
        }
        SharedDataService.syncPrayerStreak()
        flash("All prayer progress cleared")
    }

    func resetPrayerStreak() {
        // Streak is derived from per-day completion. Wipe all completion
        // history and resync widgets.
        resetPrayerProgress()
        UserDefaults.standard.removeObject(forKey: "nafs_streakDays")
        flash("Streak reset")
    }

    func resetWidgetDemoData() {
        guard let shared = sharedDefaults else { return }
        let keys = [
            "nafs_widget_streakDays",
            "nafs_widget_completedToday",
            "nafs_widget_totalToday",
            "nafs_widget_completedDateKey",
        ]
        for key in keys { shared.removeObject(forKey: key) }
        WidgetCenter.shared.reloadAllTimelines()
        flash("Widget demo data cleared")
    }

    func resetAppSelection(using service: ScreenTimeService) {
        service.clearAll()
        flash("App selection cleared")
    }

    func resetReviewPromptState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "nafs_prayerCompletionCount")
        defaults.removeObject(forKey: "nafs_firstPrayerRatingShown")
        defaults.removeObject(forKey: "nafs.hasRatedApp")
        defaults.removeObject(forKey: "nafs.lastRatePromptDate")
        flash("Review prompt state reset")
    }
}
