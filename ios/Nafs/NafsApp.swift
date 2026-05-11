import SwiftUI
import RevenueCat
import UserNotifications
import AVFoundation

@main
struct NafsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.configureRevenueCat()

        // Configure the audio session category only. Do NOT call
        // setActive(true) here — activating at process launch races with
        // the system audio session and crashes some TestFlight devices
        // with OSStatus -50. We activate lazily when audio is first needed.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    }

    private static func configureRevenueCat() {
        // Guard against empty API keys — Purchases.configure raises an
        // uncatchable NSException when given an empty string, which is the
        // most common TestFlight launch crash for us.
        Purchases.logLevel = .debug

        #if DEBUG
        let key = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        #else
        let primary = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        let key = primary.isEmpty ? Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY : primary
        #endif

        guard !key.isEmpty else {
            print("[Nafs] RevenueCat API key missing — skipping configure to avoid launch crash.")
            return
        }
        Purchases.configure(withAPIKey: key)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Permission prompt is deferred until the scene is
                    // attached. Calling it inside App.init() has crashed
                    // on launch on some TestFlight devices.
                    NotificationService.shared.requestPermission()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    RatingService.shared.handleScenePhaseChange(newPhase)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    nonisolated func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
}
