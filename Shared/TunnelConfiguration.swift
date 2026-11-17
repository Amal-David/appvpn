import Foundation

struct TunnelConfiguration: Codable, Sendable, Equatable {
    var providerKind: ProviderKind
    var endpoint: VPNEndpoint
    var ikev2: IKEv2Parameters?
    var wireGuard: WireGuardConfig?
    var openVPN: OpenVPNConfig?
    var protocolReadiness: ProtocolReadiness
}
