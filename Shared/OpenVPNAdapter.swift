import Foundation

actor OpenVPNAdapter: VPNProvider {
    let kind: ProviderKind = .openVPN
    private let store: CredentialStore
    private var parsed: OpenVPNConfig?

    init(store: CredentialStore) {
        self.store = store
    }

    func importCredentials(_ input: ProviderCredentialInput) async throws {
        guard case .openVPNFile(let data) = input else {
            throw AppRouteError.invalidCredentialInput
        }
        let config = try OpenVPNConfigParser.parse(data)
        try await store.saveOpenVPN(config)
        parsed = config
    }

    func listEndpoints() async throws -> [VPNEndpoint] {
        if parsed == nil {
            parsed = try await store.loadOpenVPN()
        }
        guard let parsed else { return [] }
        return [
            VPNEndpoint(
                displayName: parsed.remoteHost,
                country: "From .ovpn",
                city: parsed.displayProtocol,
                hostname: parsed.remoteHost,
                port: parsed.remotePort,
                isExample: false
            )
        ]
    }

    func buildTunnelConfiguration(endpoint: VPNEndpoint) async throws -> TunnelConfiguration {
        guard let parsed else {
            throw AppRouteError.openVPNParseFailed("Import a .ovpn file first.")
        }
        return TunnelConfiguration(
            providerKind: .openVPN,
            endpoint: endpoint,
            ikev2: nil,
            wireGuard: nil,
            openVPN: parsed,
            protocolReadiness: .metadataOnly(
                reason: "The .ovpn file was parsed locally. A full OpenVPN protocol stack is not implemented in the V1 packet tunnel, so this provider cannot carry traffic yet."
            )
        )
    }

    func validateCredentials() async throws {
        parsed = try await store.loadOpenVPN()
        guard parsed != nil else {
            throw AppRouteError.openVPNParseFailed("No imported OpenVPN configuration was found.")
        }
    }
}
