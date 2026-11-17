import Foundation

struct TunnelDiagnosticsSnapshot: Codable, Sendable, Equatable {
    var lastStarted: Date?
    var lastError: String?
    var classifiedVPNCount: Int
    var classifiedDirectCount: Int
    var handshakeTODO: String
    var ipv6Enabled: Bool
}
