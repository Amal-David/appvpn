import Foundation

struct IKEv2Parameters: Codable, Sendable, Equatable {
    var serverAddress: String
    var remoteIdentifier: String
    var localIdentifier: String?
    var usernameAccount: String
    var useCertificate: Bool
    var deadPeerDetection: Bool
}
