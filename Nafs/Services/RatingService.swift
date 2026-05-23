import SwiftUI
import StoreKit
import UIKit

@MainActor
@Observable
final class RatingService {
    static let shared = RatingService()

    private let hasRatedKey = "nafs.hasRatedApp"
    private let lastPromptKey = "nafs.lastRatePromptDate"

    var hasRated: Bool {
        get { UserDefaults.standard.bool(forKey: hasRatedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRatedKey) }
    }

    private(set) var isPromptInProgress: Bool = false
    private var promptStartedAt: Date?

    /// Opens the App Store review page. Uses itms-apps first (opens App Store
    /// app directly on device), falls back to https (which iOS auto-redirects
    /// to App Store), and finally the in-app StoreKit prompt.
    func requestReview() {
        isPromptInProgress = true
        promptStartedAt = Date()
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)

        let candidates: [URL] = [
            URL(string: NafsConstants.rateAppURLItmsApps),
            URL(string: NafsConstants.rateAppURL)
        ].compactMap { $0 }

        openFirstAvailable(urls: candidates, index: 0)
    }

    private func openFirstAvailable(urls: [URL], index: Int) {
        guard index < urls.count else {
            tryStoreKitFallback()
            return
        }
        let url = urls[index]
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            guard let self else { return }
            if !success {
                self.openFirstAvailable(urls: urls, index: index + 1)
            }
        }
    }

    private func tryStoreKitFallback() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            isPromptInProgress = false
            return
        }
        AppStore.requestReview(in: scene)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isPromptInProgress else { return }

        if phase == .active, let start = promptStartedAt {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed > 2.0 {
                hasRated = true
            }
            isPromptInProgress = false
            promptStartedAt = nil
        }
    }
}
