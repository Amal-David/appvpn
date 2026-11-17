import Foundation

enum ProviderKind: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    case nordManual
    case openVPN
    case wireGuard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nordManual:
            "NordVPN (manual)"
        case .openVPN:
            "OpenVPN"
        case .wireGuard:
            "WireGuard"
        }
    }

    var systemImage: String {
        switch self {
        case .nordManual:
            "globe.badge.chevron.backward"
        case .openVPN:
            "doc.badge.gearshape"
        case .wireGuard:
            "key.horizontal"
        }
    }

    var summary: String {
        switch self {
        case .nordManual:
            "Compatible with NordVPN manual configurations using service credentials. This is not an official NordVPN integration. NordLynx is out of scope."
        case .openVPN:
            "Import a .ovpn file. AppRoute reads remote, protocol, and metadata locally. A full OpenVPN handshake is not wired into the packet tunnel in V1."
        case .wireGuard:
            "Import a .conf file. The private key stays in Keychain. The packet tunnel can start with destination routes; a complete WireGuard handshake is not in this pass."
        }
    }
}
