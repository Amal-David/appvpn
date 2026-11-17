import Foundation

enum TunnelFailurePolicy: String, Codable, Sendable, CaseIterable, Identifiable {
    case keepOffline
    case allowDirect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepOffline:
            "Keep service offline"
        case .allowDirect:
            "Allow direct"
        }
    }

    var subtitle: String {
        switch self {
        case .keepOffline:
            "Privacy-first. If the tunnel fails, matching service traffic is not sent on the regular connection."
        case .allowDirect:
            "Availability-first. If the tunnel fails, matching service traffic may use the regular connection."
        }
    }
}
