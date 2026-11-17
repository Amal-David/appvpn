import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        if session.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}
