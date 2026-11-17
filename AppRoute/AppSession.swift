import Foundation
import Observation

@Observable
@MainActor
final class AppSession {
    var hasCompletedOnboarding: Bool
    var onboardingPath: [OnboardingStep]
    var compatibilityAnswer: CompatibilityAnswer?
    var policy: RoutingPolicy
    var connectionStatus: ConnectionStatus
    var lastError: AppRouteError?
    var nordUsername: String
    var nordPassword: String
    var customHostname: String

    let credentialStore: CredentialStore
    let policyStore: PolicyStore
    let analytics: LocalAnalytics
    let tunnelController: TunnelController
    let subscriptionStore: SubscriptionStore

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        onboardingPath = []
        compatibilityAnswer = nil
        policy = .empty
        connectionStatus = .invalid
        lastError = nil
        nordUsername = ""
        nordPassword = ""
        customHostname = ""
        credentialStore = CredentialStore()
        policyStore = PolicyStore()
        analytics = LocalAnalytics()
        tunnelController = TunnelController(credentials: credentialStore)
        subscriptionStore = SubscriptionStore()
    }

    func bootstrap() async {
        await analytics.record(.install)
        policy = (try? await policyStore.load()) ?? .empty
        await tunnelController.refresh()
        connectionStatus = tunnelController.status
        await subscriptionStore.loadProducts()
    }

    func record(_ name: FunnelEventName, selectedServiceCount: Int? = nil) {
        Task {
            await analytics.record(name, selectedServiceCount: selectedServiceCount)
        }
    }

    func persistPolicy() async {
        try? await policyStore.save(policy)
    }

    func connectVPN() async {
        lastError = nil
        do {
            var passwordReference: Data?
            var username: String?
            if policy.providerKind == .nordManual {
                guard let credentials = try await credentialStore.loadNord() else {
                    throw AppRouteError.nordCredentialsMissing
                }
                username = credentials.username
                passwordReference = try await credentialStore.nordPasswordPersistentReference()
            }
            policy.isRoutingEnabled = true
            await persistPolicy()
            try await tunnelController.enableAndStart(
                policy: policy,
                nordPasswordReference: passwordReference,
                nordUsername: username
            )
            connectionStatus = tunnelController.status
            lastError = tunnelController.lastError
        } catch let error as AppRouteError {
            lastError = error
            tunnelController.lastMessage = error.userFacingMessage
            connectionStatus = tunnelController.status
        } catch {
            let mapped = AppRouteError.fromVPN(error)
            lastError = mapped
            tunnelController.lastMessage = mapped.userFacingMessage
        }
    }

    func completeOnboarding() async {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        await persistPolicy()
    }

    func resetLocalData() async {
        try? await credentialStore.deleteAll()
        try? await policyStore.delete()
        await analytics.deleteAll()
        policy = .empty
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        onboardingPath = []
        nordUsername = ""
        nordPassword = ""
        await analytics.record(.privacyDeleted)
    }

    func provider(for kind: ProviderKind) -> any VPNProvider {
        ProviderFactory.make(kind: kind, store: credentialStore)
    }
}
