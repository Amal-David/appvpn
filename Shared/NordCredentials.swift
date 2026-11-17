import Foundation

struct NordCredentials: Sendable, Equatable {
    var username: String
    var password: String

    var hasContent: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && password.isEmpty == false
    }
}

enum NordCredentialValidator: Sendable {
    static func validateFormat(_ credentials: NordCredentials) throws {
        let username = credentials.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if username.isEmpty || credentials.password.isEmpty {
            throw AppRouteError.nordCredentialsRejected
        }
        if username.contains("@") {
            throw AppRouteError.nordCredentialsRejected
        }
        if username.count < 4 || credentials.password.count < 8 {
            throw AppRouteError.nordCredentialsRejected
        }
    }
}
