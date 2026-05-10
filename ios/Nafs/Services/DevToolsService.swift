import Foundation
import SwiftUI
import WidgetKit

/// Developer / TestFlight-only utilities used to trigger marketing demo
/// states (manual lock, success screen, fake streak, etc.) without waiting
/// for real prayer times.
///
/// Every entry point is gated behind `DevToolsService.isAvailable`, which is
/// `true` only in DEBUG builds or TestFlight (sandbox receipt). Production
/// App Store builds return `false` so the Developer Tools section is
/// completely hidden and unreachable.
@MainActor
enum DevToolsService {
    private static let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
    private static var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    private static let manualLockKey = "nafs_dev_manualLockActive"

    // MARK: - Visibility

    static var isAvailable: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }

    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    static var buildKind: String {
        #if DEBUG
        return "Debug"
        #else
        return isTestFlight ? "TestFlight" : "Production"
        #endif
    }

    // MARK: - Manual lock

    static var isManualLockActive: Bool {
        get { UserDefaults.standard.bool(forKey: manualLockKey) }
        set { UserDefaults.standard.set(newValue, forKey: manualLockKey) }
    }

    @discardableResult
    static func manualLock(_ service: ScreenTimeService) -> Bool {
        guard service.isAuthorized, service.hasSelection else { return false }
        service.applyShields()
        isManualLockActive = true
        return true
    }

    static func manualUnlock(_ service: ScreenTimeService) {
        service.removeShields()
        service.activePrayerLock = nil
        service.lastLockedPrayerAt = nil
        UserDefaults.standard.removeObject(forKey: "nafs_prayerActiveLock")
        UserDefaults.standard.removeObject(forKey: "nafs_prayerActiveLockDate")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLock")
        sharedDefaults?.removeObject(forKey: "nafs_prayerActiveLockDate")
        isManualLockActive = false
    }

    /// Override the shared prayer-times payload so the OS shield picks
    /// `prayer` as the current/active prayer for screenshots.
    static func forceActivePrayer(_ prayer: PrayerName) {
        guard let shared = sharedDefaults else { return }
        let now = Date.now
        let cal = Calendar.current
        let ordered: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
        guard let targetIdx = ordered.firstIndex(of: prayer) else { return }
        var payload: [SharedPrayerTime] = []
        for (idx, p) in ordered.enumerated() {
            let minutesFromTarget = (idx - targetIdx) * 90
            let t = cal.date(byAdding: .minute, value: minutesFromTarget - 1, to: now) ?? now
            payload.append(SharedPrayerTime(name: p.rawValue, time: t))
        }
        if let data = try? JSONEncoder().encode(payload) {
            shared.set(data, forKey: "nafs_prayerTimes")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Resets

    static func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
    }

    static func resetPaywallSeen() {
        UserDefaults.standard.removeObject(forKey: "nafs_paywallSeen")
        UserDefaults.standard.removeObject(forKey: "nafs_onboardingPaywallSeen")
    }

    static func resetPrayerProgress() {
        let cal = Calendar.current
        for offset in 0..<2 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            for prayer in PrayerName.allCases {
                PrayerCompletionStore.resetCompletion(prayer, on: day)
            }
        }
        SharedDataService.syncPrayerStreak()
    }

    static func resetPrayerStreak() {
        let cal = Calendar.current
        for offset in 0..<400 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            for prayer in PrayerName.allCases {
                PrayerCompletionStore.resetCompletion(prayer, on: day)
            }
        }
        UserDefaults.standard.removeObject(forKey: "nafs_streakDays")
        SharedDataService.syncPrayerStreak()
    }

    static func resetWidgetDemoData() {
        guard let shared = sharedDefaults else { return }
        shared.removeObject(forKey: "nafs_widget_streakDays")
        shared.removeObject(forKey: "nafs_widget_completedToday")
        shared.removeObject(forKey: "nafs_widget_totalToday")
        shared.removeObject(forKey: "nafs_widget_completedDateKey")
        SharedDataService.syncPrayerStreak()
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func resetAppSelection(_ service: ScreenTimeService) {
        service.clearAll()
    }

    static func resetReviewPromptState() {
        UserDefaults.standard.removeObject(forKey: "nafs.hasRatedApp")
        UserDefaults.standard.removeObject(forKey: "nafs.lastRatePromptDate")
        UserDefaults.standard.removeObject(forKey: "nafs_firstPrayerRatingShown")
        UserDefaults.standard.removeObject(forKey: "nafs_prayerCompletionCount")
    }

    // MARK: - Demo data

    /// Set today's completed prayer count (0...5) by marking the first N
    /// prayers complete.
    static func setPrayerProgressToday(count: Int) {
        let clamped = max(0, min(PrayerName.allCases.count, count))
        for (idx, prayer) in PrayerName.allCases.enumerated() {
            if idx < clamped {
                PrayerCompletionStore.markCompleted(prayer, on: .now)
            } else {
                PrayerCompletionStore.resetCompletion(prayer, on: .now)
            }
        }
        SharedDataService.syncPrayerStreak()
    }

    /// Mark every prayer complete for the last `days` consecutive days
    /// (including today) so `currentStreakDays` returns `days`.
    static func setStreakDays(_ days: Int) {
        let clamped = max(0, min(365, days))
        let cal = Calendar.current
        for offset in 0..<400 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            for prayer in PrayerName.allCases {
                PrayerCompletionStore.resetCompletion(prayer, on: day)
            }
        }
        for offset in 0..<clamped {
            guard let day = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            for prayer in PrayerName.allCases {
                PrayerCompletionStore.markCompleted(prayer, on: day)
            }
        }
        SharedDataService.syncPrayerStreak()
    }

    /// Push hard-coded widget values to the App Group, bypassing the live
    /// streak calculation, then reload timelines.
    static func setWidgetDemo(streak: Int, completed: Int, total: Int = PrayerName.allCases.count) {
        guard let shared = sharedDefaults else { return }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        shared.set(streak, forKey: "nafs_widget_streakDays")
        shared.set(completed, forKey: "nafs_widget_completedToday")
        shared.set(total, forKey: "nafs_widget_totalToday")
        shared.set(f.string(from: .now), forKey: "nafs_widget_completedDateKey")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
