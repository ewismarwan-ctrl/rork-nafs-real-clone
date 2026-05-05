import Foundation
import UserNotifications
import RevenueCat

@MainActor
class NotificationService {
    static let shared = NotificationService()

    var locationName: String = ""

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func schedulePrayerNotifications(
        prayerTimes: [PrayerTime],
        upcomingDays: [[(name: String, time: Date)]] = [],
        enabledPrayers: [PrayerName: Bool],
        cityName: String = ""
    ) {
        if !cityName.isEmpty {
            locationName = cityName
        }

        // Flatten all upcoming prayer occurrences across the next N days so a
        // single notification id (`prayer_<name>_<yyyy-MM-dd>`) maps to one
        // future fire. This avoids stale notifications hanging around when
        // the user adjusts methods/location.
        let upcoming: [(name: PrayerName, time: Date)] = {
            if upcomingDays.isEmpty {
                return prayerTimes.map { (name: $0.name, time: $0.time) }
            }
            var out: [(name: PrayerName, time: Date)] = []
            for day in upcomingDays {
                for entry in day {
                    guard let p = PrayerName(rawValue: entry.name) else { continue }
                    out.append((name: p, time: entry.time))
                }
            }
            return out
        }()

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let prayerIds = requests.filter { $0.identifier.hasPrefix("prayer_") || $0.identifier.hasPrefix("dhikr_") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: prayerIds)

            Task { @MainActor in
                let now = Date.now
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                let dayFormatter = DateFormatter()
                dayFormatter.calendar = Calendar(identifier: .gregorian)
                dayFormatter.timeZone = TimeZone.current
                dayFormatter.dateFormat = "yyyy-MM-dd"

                for entry in upcoming {
                    guard enabledPrayers[entry.name] ?? true else { continue }
                    guard entry.time > now else { continue }

                    let prayerDisplayName = NafsStrings.prayerName(entry.name)
                    let timeString = timeFormatter.string(from: entry.time)
                    let dayKey = dayFormatter.string(from: entry.time)
                    let city = self.locationName

                    let content = UNMutableNotificationContent()
                    content.title = prayerDisplayName
                    if city.isEmpty {
                        content.body = "\(prayerDisplayName) Time \(timeString)"
                    } else {
                        content.body = self.prayerNotificationBody(for: entry.name, city: city, time: timeString)
                    }
                    content.sound = .default
                    content.interruptionLevel = .timeSensitive

                    let comps = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute, .second],
                        from: entry.time
                    )
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "prayer_\(entry.name.rawValue)_\(dayKey)",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request)

                    let dhikrContent = UNMutableNotificationContent()
                    dhikrContent.title = "Nafs"
                    dhikrContent.body = "Open Nafs to do your dhikr for \(prayerDisplayName)"
                    dhikrContent.sound = .default
                    dhikrContent.interruptionLevel = .timeSensitive

                    let dhikrFire = entry.time.addingTimeInterval(5 * 60)
                    let dhikrComps = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute, .second],
                        from: dhikrFire
                    )
                    let dhikrTrigger = UNCalendarNotificationTrigger(dateMatching: dhikrComps, repeats: false)
                    let dhikrRequest = UNNotificationRequest(
                        identifier: "dhikr_\(entry.name.rawValue)_\(dayKey)",
                        content: dhikrContent,
                        trigger: dhikrTrigger
                    )
                    center.add(dhikrRequest)
                }

                print("[Nafs.Notifications] scheduled \(upcoming.count) upcoming prayer notifications")
                self.scheduleTomorrowRefresh()
            }
        }
    }

    private func prayerNotificationBody(for prayer: PrayerName, city: String, time: String) -> String {
        switch prayer {
        case .fajr:
            return "Fajr Time in \(city) \(time)"
        case .dhuhr:
            return "Time to offer Dhuhr in \(city) is \(time)"
        case .asr:
            return "Asr Time in \(city) \(time)"
        case .maghrib:
            return "Maghrib Time in \(city) \(time)"
        case .isha:
            return "Isha Time in \(city) \(time)"
        }
    }

    private func scheduleTomorrowRefresh() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["prayer_daily_refresh"])

        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 0
        components.minute = 5

        let content = UNMutableNotificationContent()
        content.title = "Nafs"
        content.body = "Your prayer times have been updated for today."
        content.sound = nil

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "prayer_daily_refresh",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func scheduleSubscriptionExpiryReminders(plan: ActivePlan?, expirationDate: Date?, isInTrial: Bool, willRenew: Bool) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let subIds = requests.filter { $0.identifier.hasPrefix("sub_expiry_") || $0.identifier.hasPrefix("sub_trial_") }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: subIds)

            guard let expirationDate, willRenew else { return }

            let now = Date.now

            if isInTrial {
                // Yearly trial: remind before trial ends so user can cancel >=24h before.
                let reminders: [(String, TimeInterval, String)] = [
                    ("sub_trial_3day", 3 * 24 * 3600, "Your free trial ends in 3 days. After that, you'll be charged for your yearly Nafs Premium plan. Cancel at least 24 hours before if you don't want to renew."),
                    ("sub_trial_2day", 2 * 24 * 3600, "Your free trial ends in 2 days. Cancel at least 24 hours before the trial ends to avoid being charged."),
                    ("sub_trial_1day", 1 * 24 * 3600, "Your free trial ends tomorrow. After that, your yearly Nafs Premium will begin."),
                ]
                for (id, before, body) in reminders {
                    let fire = expirationDate.addingTimeInterval(-before)
                    let interval = fire.timeIntervalSince(now)
                    guard interval > 60 else { continue }
                    let content = UNMutableNotificationContent()
                    content.title = "Nafs Premium — Free Trial"
                    content.body = body
                    content.sound = .default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                    center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
                }
                return
            }

            guard let plan else { return }

            let reminders: [(String, TimeInterval, String)] = {
                switch plan {
                case .weekly:
                    return [
                        ("sub_expiry_2day", 2 * 24 * 3600, "Your weekly Nafs Premium renews in 2 days. Cancel at least 24 hours before if you don't want to renew."),
                        ("sub_expiry_1day", 1 * 24 * 3600, "Your weekly Nafs Premium renews tomorrow."),
                    ]
                case .monthly:
                    return [
                        ("sub_expiry_3day", 3 * 24 * 3600, "Your monthly Nafs Premium renews in 3 days."),
                        ("sub_expiry_1day", 1 * 24 * 3600, "Your monthly Nafs Premium renews tomorrow. Cancel at least 24 hours before to avoid being charged."),
                    ]
                case .yearly:
                    return [
                        ("sub_expiry_7day", 7 * 24 * 3600, "Your yearly Nafs Premium renews in 7 days."),
                        ("sub_expiry_3day", 3 * 24 * 3600, "Your yearly Nafs Premium renews in 3 days."),
                        ("sub_expiry_1day", 1 * 24 * 3600, "Your yearly Nafs Premium renews tomorrow. Cancel at least 24 hours before to avoid being charged."),
                    ]
                }
            }()

            for (id, before, body) in reminders {
                let fire = expirationDate.addingTimeInterval(-before)
                let interval = fire.timeIntervalSince(now)
                guard interval > 60 else { continue }
                let content = UNMutableNotificationContent()
                content.title = "Nafs Premium"
                content.body = body
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }
}
