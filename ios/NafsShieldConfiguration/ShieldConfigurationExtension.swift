import ManagedSettings
import ManagedSettingsUI
import UIKit

nonisolated final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    nonisolated override func configuration(shielding application: Application) -> ShieldConfiguration {
        nafsShieldConfiguration(appName: application.localizedDisplayName)
    }

    nonisolated override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        nafsShieldConfiguration(appName: application.localizedDisplayName ?? category.localizedDisplayName)
    }

    nonisolated override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        nafsShieldConfiguration(appName: webDomain.domain)
    }

    nonisolated override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        nafsShieldConfiguration(appName: webDomain.domain ?? category.localizedDisplayName)
    }

    private nonisolated func nafsShieldConfiguration(appName: String?) -> ShieldConfiguration {
        let background = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1.0)
        let gold = UIColor(red: 0.82, green: 0.66, blue: 0.38, alpha: 1.0)
        let softGold = UIColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 1.0)
        let white = UIColor.white
        let muted = UIColor(red: 0.78, green: 0.72, blue: 0.60, alpha: 1.0)

        let prayer = currentPrayerName()
        let displayApp = (appName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "This app"

        let title = "It's time for \(prayer)"
        let subtitle = "\(displayApp) is locked until you've prayed"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "moon.stars.fill")?.withTintColor(gold, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: title, color: white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: muted),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Go Pray", color: .black),
            primaryButtonBackgroundColor: softGold
        )
    }

    private nonisolated func currentPrayerName() -> String {
        let appGroupID = "group.app.rork.4lq2ucv31aityltnkks3n.nafs"
        guard let shared = UserDefaults(suiteName: appGroupID),
              let data = shared.data(forKey: "nafs_prayerTimes") else {
            return fallbackPrayerName()
        }

        struct SharedPrayerTime: Codable { let name: String; let time: Date }
        guard let times = try? JSONDecoder().decode([SharedPrayerTime].self, from: data),
              !times.isEmpty else {
            return fallbackPrayerName()
        }

        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)

        let todayTimes = times.compactMap { entry -> (String, Date)? in
            let t = entry.time
            let comps = cal.dateComponents([.hour, .minute], from: t)
            guard let mapped = cal.date(bySettingHour: comps.hour ?? 0,
                                        minute: comps.minute ?? 0,
                                        second: 0,
                                        of: today) else { return nil }
            return (entry.name, mapped)
        }.sorted { $0.1 < $1.1 }

        let passed = todayTimes.filter { $0.1 <= now }
        if let current = passed.last {
            return current.0
        }
        return todayTimes.first?.0 ?? fallbackPrayerName()
    }

    private nonisolated func fallbackPrayerName() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<11: return "Fajr"
        case 11..<15: return "Dhuhr"
        case 15..<18: return "Asr"
        case 18..<20: return "Maghrib"
        default: return "Isha"
        }
    }
}
