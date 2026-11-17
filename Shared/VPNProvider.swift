import Foundation

protocol VPNProvider: Sendable {
    var kind: ProviderKind { get }
    func importCredentials(_ input: ProviderCredentialInput) async throws
    func listEndpoints() async throws -> [VPNEndpoint]
    func buildTunnelConfiguration(endpoint: VPNEndpoint) async throws -> TunnelConfiguration
    func validateCredentials() async throws
}
