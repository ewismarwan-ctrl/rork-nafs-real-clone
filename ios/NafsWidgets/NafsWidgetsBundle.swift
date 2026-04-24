import WidgetKit
import SwiftUI

@main
struct NafsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AyahReminderWidget()
        PrayerTimesWidget()
        NextPrayerWidget()
        HijriDateWidget()
        DailyReflectionWidget()
    }
}
