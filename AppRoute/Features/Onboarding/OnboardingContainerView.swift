import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        @Bindable var session = session
        NavigationStack(path: $session.onboardingPath) {
            WelcomeView()
                .navigationDestination(for: OnboardingStep.self) { step in
                    destination(for: step)
                }
        }
    }

    @ViewBuilder
    private func destination(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeView()
        case .compatibility:
            CompatibilityView()
        case .howRoutingWorks:
            HowRoutingWorksView()
        case .privacy:
            PrivacyDisclosureView()
        case .providerPicker:
            ProviderPickerView()
        case .credentialImport:
            CredentialImportView()
        case .serverPicker:
            ServerPickerView()
        case .enableRouting:
            EnableRoutingView()
        case .servicePicker:
            ServicePickerView(showsOnboardingContinue: true)
        case .routingTest:
            RoutingTestView(isOnboarding: true)
        case .complete:
            DashboardView()
        }
    }
}
