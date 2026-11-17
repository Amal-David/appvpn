import Foundation

actor WireGuardAdapter: VPNProvider {
    let kind: ProviderKind = .wireGuard
    private let store: CredentialStore
    private var parsed: WireGuardConfig?

    init(store: CredentialStore) {
        self.store = store
    }

    func importCredentials(_ input: ProviderCredentialInput) async throws {
        guard case .wireGuardFile(let data) = input else {
            throw AppRouteError.invalidCredentialInput
        }
        let result = try WireGuardConfigParser.parse(data)
        try await store.saveWireGuard(config: result.config, privateKey: result.privateKey)
        parsed = result.config
    }

    func listEndpoints() async throws -> [VPNEndpoint] {
        if parsed == nil {
            parsed = try await store.loadWireGuardConfig()
        }
        guard let parsed else { return [] }
        return [
            VPNEndpoint(
                displayName: parsed.peer.endpointHost,
                country: "From .conf",
                city: "UDP \(parsed.peer.endpointPort)",
                hostname: parsed.peer.endpointHost,
                port: parsed.peer.endpointPort,
                isExample: false
            )
        ]
    }

    func buildTunnelConfiguration(endpoint: VPNEndpoint) async throws -> TunnelConfiguration {
        guard let parsed else {
            throw AppRouteError.wireGuardParseFailed("Import a .conf file first.")
        }
        return TunnelConfiguration(
            providerKind: .wireGuard,
            endpoint: endpoint,
            ikev2: nil,
            wireGuard: parsed,
            openVPN: nil,
            protocolReadiness: .packetTunnelRoutesReady
        )
    }

    func validateCredentials() async throws {
        parsed = try await store.loadWireGuardConfig()
        guard parsed?.hasPrivateKey == true else {
            throw AppRouteError.wireGuardPrivateKeyMissing
        }
        _ = try await store.loadWireGuardPrivateKey()
    }
}
