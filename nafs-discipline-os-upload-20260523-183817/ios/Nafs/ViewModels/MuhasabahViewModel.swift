import SwiftUI
import UserNotifications

@Observable
@MainActor
class MuhasabahViewModel {
    var gratitudeText: String = ""
    var struggleText: String = ""
    var tomorrowText: String = ""
    var selectedMood: MuhasabahMood? = nil
    var entries: [MuhasabahEntry] = []
    var showCompletion: Bool = false
    var completionMessage: String = ""
    var expandedEntryID: String? = nil

    private let storageKey = "nafs_muhasabah_entries"
    private let lastCompletedKey = "nafs_muhasabah_lastCompleted"

    var canComplete: Bool {
        !gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !struggleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !tomorrowText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedMood != nil
    }

    var hasCompletedToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastCompletedKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    init() {
        loadEntries()
        scheduleNightlyReminder()
    }

    func completeMuhasabah(userName: String, appViewModel: AppViewModel) {
        guard canComplete, !hasCompletedToday, let mood = selectedMood else { return }

        let entry = MuhasabahEntry(
            gratitude: gratitudeText.trimmingCharacters(in: .whitespacesAndNewlines),
            struggle: struggleText.trimmingCharacters(in: .whitespacesAndNewlines),
            tomorrow: tomorrowText.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood
        )

        entries.insert(entry, at: 0)
        saveEntries()
        UserDefaults.standard.set(Date(), forKey: lastCompletedKey)
        appViewModel.recordDiscipline(.muhasabahReflection)

        completionMessage = "Reset. Rebuild. Keep going, \(userName). Discipline earns freedom."
        showCompletion = true

        gratitudeText = ""
        struggleText = ""
        tomorrowText = ""
        selectedMood = nil
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MuhasabahEntry].self, from: data) else { return }
        entries = decoded
    }

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func scheduleNightlyReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        center.removePendingNotificationRequests(withIdentifiers: ["nafs_muhasabah_nightly"])

        let content = UNMutableNotificationContent()
        content.title = "Time for Muhasabah \u{1F319}"
        content.body = "Take a moment to reflect on your day before it ends."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "nafs_muhasabah_nightly", content: content, trigger: trigger)
        center.add(request)
    }
}
