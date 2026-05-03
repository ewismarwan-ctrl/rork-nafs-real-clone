import SwiftUI

@Observable
@MainActor
class OnboardingViewModel {
    var currentScreen: OnboardingScreen = .splash
    var direction: Int = 1

    var selectedDistractions: Set<String> = []
    var hasCompletedOnboarding: Bool = false

    var totalScreens: Int { OnboardingScreen.allCases.count }

    var progress: Double {
        let total = max(totalScreens - 2, 1) // exclude splash + languageSelection
        let current = max(currentScreen.rawValue - 1, 0)
        return min(Double(current) / Double(total), 1)
    }

    var canProceed: Bool {
        switch currentScreen {
        case .distractions:
            return !selectedDistractions.isEmpty
        default:
            return true
        }
    }

    var requiresAnswer: Bool {
        currentScreen == .distractions && !canProceed
    }

    var showBackButton: Bool {
        currentScreen.rawValue > OnboardingScreen.identity.rawValue
    }

    var showProgressBar: Bool {
        switch currentScreen {
        case .splash, .languageSelection, .paywall:
            return false
        default:
            return true
        }
    }

    func goNext() {
        guard let next = OnboardingScreen(rawValue: currentScreen.rawValue + 1) else { return }
        direction = 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentScreen = next
        }
    }

    func goBack() {
        guard let prev = OnboardingScreen(rawValue: currentScreen.rawValue - 1) else { return }
        direction = -1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentScreen = prev
        }
    }

    func toggleDistraction(_ id: String) {
        if selectedDistractions.contains(id) {
            selectedDistractions.remove(id)
        } else {
            selectedDistractions.insert(id)
        }
        persistDistractions()
    }

    func persistDistractions() {
        UserDefaults.standard.set(Array(selectedDistractions), forKey: OnboardingDistractions.storageKey)
    }

    func completeOnboarding() {
        persistDistractions()
        hasCompletedOnboarding = true
    }
}
