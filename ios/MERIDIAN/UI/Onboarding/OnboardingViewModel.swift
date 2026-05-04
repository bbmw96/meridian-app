import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    var currentPage: Int = 0
    let totalPages: Int = 4

    var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    func advance() {
        guard !isLastPage else { return }
        currentPage += 1
    }

    func complete(appState: AppState) {
        appState.isOnboarded = true
        appState.persistPreferences()
    }
}
