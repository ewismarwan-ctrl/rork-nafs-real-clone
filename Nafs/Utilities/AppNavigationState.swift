import SwiftUI

@Observable
@MainActor
final class AppNavigationState {
    var selectedTab: AppTab = .home
}
