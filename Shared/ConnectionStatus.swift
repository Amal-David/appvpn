import Foundation
import NetworkExtension

enum ConnectionStatus: Sendable, Equatable {
    case invalid
    case disconnected
    case connecting
    case connected
    case reasserting
    case disconnecting
    case unknown

    init(vpnStatus: NEVPNStatus) {
        switch vpnStatus {
        case .invalid:
            self = .invalid
        case .disconnected:
            self = .disconnected
        case .connecting:
            self = .connecting
        case .connected:
            self = .connected
        case .reasserting:
            self = .reasserting
        case .disconnecting:
            self = .disconnecting
        @unknown default:
            self = .unknown
        }
    }

    var title: String {
        switch self {
        case .invalid:
            "Not installed"
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting"
        case .connected:
            "Connected"
        case .reasserting:
            "Reconnecting"
        case .disconnecting:
            "Stopping"
        case .unknown:
            "Unknown"
        }
    }

    var isActive: Bool {
        switch self {
        case .connected, .connecting, .reasserting:
            true
        case .invalid, .disconnected, .disconnecting, .unknown:
            false
        }
    }
}
