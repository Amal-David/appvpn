import Foundation

enum DestinationMatch: Sendable, Equatable {
    case vpnService(id: String)
    case direct
}
