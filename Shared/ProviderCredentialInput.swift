import Foundation

enum ProviderCredentialInput: Sendable, Equatable {
    case nordService(username: String, password: String)
    case openVPNFile(Data)
    case wireGuardFile(Data)
}
