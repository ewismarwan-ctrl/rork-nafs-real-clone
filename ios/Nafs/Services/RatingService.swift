import SwiftUI
import StoreKit
import UIKit

@MainActor
@Observable
final class RatingService {
    static let shared = RatingService()

    private let hasRatedKey = "nafs.hasRatedApp"
    private let lastPromptKey = "nafs.lastRatePromptDate"
    private let attemptInProgressKey = "nafs.ratePromptInProgress"

    var hasRated: Bool {
        get { UserDefaults.standard.bool(forKey: hasRatedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRatedKey) }
    }

    private(set) var isPromptInProgress: Bool = false
    private var promptStartedAt: Date?

    func requestReview() {
        isPromptInProgress = true
        promptStartedAt = Date()
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)

        guard let url = URL(string: NafsConstants.rateAppURL) else {
            isPromptInProgress = false
            return
        }

        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            guard let self else { return }
            if !success {
                self.tryStoreKitFallback()
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
