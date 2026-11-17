import Foundation

actor NordAdapter: VPNProvider {
    let kind: ProviderKind = .nordManual
    private let store: CredentialStore
    private var importedUsername: String?

    init(store: CredentialStore) {
        self.store = store
    }

    func importCredentials(_ input: ProviderCredentialInput) async throws {
        guard case .nordService(let username, let password) = input else {
            throw AppRouteError.invalidCredentialInput
        }
        let credentials = NordCredentials(username: username, password: password)
        try NordCredentialValidator.validateFormat(credentials)
        try await store.saveNord(credentials)
        importedUsername = username
    }

    func listEndpoints() async throws -> [VPNEndpoint] {
        NordExampleServers.curated
    }

    func buildTunnelConfiguration(endpoint: VPNEndpoint) async throws -> TunnelConfiguration {
        let parameters = IKEv2Parameters(
            serverAddress: endpoint.hostname,
            remoteIdentifier: endpoint.hostname,
            localIdentifier: importedUsername,
            usernameAccount: importedUsername ?? "",
            useCertificate: false,
            deadPeerDetection: true
        )
        return TunnelConfiguration(
            providerKind: .nordManual,
            endpoint: endpoint,
            ikev2: parameters,
            wireGuard: nil,
            openVPN: nil,
            protocolReadiness: .packetTunnelRoutesReady
        )
    }

    func validateCredentials() async throws {
        guard let credentials = try await store.loadNord() else {
            throw AppRouteError.nordCredentialsMissing
        }
        try NordCredentialValidator.validateFormat(credentials)
        importedUsername = credentials.username
    }
}
