import Foundation

enum ProtocolReadiness: Codable, Sendable, Equatable {
    case packetTunnelRoutesReady
    case metadataOnly(reason: String)

    var isFullyWired: Bool {
        switch self {
        case .packetTunnelRoutesReady:
            true
        case .metadataOnly:
            false
        }
    }

    var userFacingNote: String {
        switch self {
        case .packetTunnelRoutesReady:
            "Nord uses Apple's built-in IKEv2 (Personal VPN) for a real device VPN. WireGuard still uses the packet tunnel for destination rules; a full WireGuard handshake is not completed in this build."
        case .metadataOnly(let reason):
            reason
        }
    }
}
