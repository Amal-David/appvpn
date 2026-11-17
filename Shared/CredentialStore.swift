import Foundation

actor CredentialStore {
    private enum Account {
        static let nordUsername = "nord.service.username"
        static let nordPassword = "nord.service.password"
        static let wireGuardPrivateKey = "wireguard.private-key"
        static let openVPNJSON = "openvpn.config.json"
        static let wireGuardJSON = "wireguard.config.json"
        static let ikev2Password = "nord.ikev2.password"
    }

    private enum Service {
        static let secrets = "app.approute.secrets"
        static let metadata = "app.approute.metadata"
        static let ikev2 = "app.approute.ikev2"
    }

    private let keychain: KeychainClient
    private let vpnKeychain = KeychainClient(accessGroup: "")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(accessGroup: String = AppRouteConstants.keychainAccessGroup) {
        keychain = KeychainClient(accessGroup: accessGroup)
    }

    func saveNord(_ credentials: NordCredentials) throws {
        try keychain.setPassword(credentials.username, account: Account.nordUsername, service: Service.secrets)
        try keychain.setPassword(credentials.password, account: Account.nordPassword, service: Service.secrets)
        try vpnKeychain.setPassword(credentials.password, account: Account.ikev2Password, service: Service.ikev2)
    }

    func loadNord() throws -> NordCredentials? {
        let username = try keychain.password(account: Account.nordUsername, service: Service.secrets)
        let password = try keychain.password(account: Account.nordPassword, service: Service.secrets)
        guard let username, let password else { return nil }
        return NordCredentials(username: username, password: password)
    }

    func nordPasswordPersistentReference() throws -> Data {
        if let credentials = try loadNord() {
            try vpnKeychain.setPassword(credentials.password, account: Account.ikev2Password, service: Service.ikev2)
        }
        return try vpnKeychain.persistentPasswordReference(account: Account.ikev2Password, service: Service.ikev2)
    }

    func saveOpenVPN(_ config: OpenVPNConfig) throws {
        let data = try encoder.encode(config)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppRouteError.keychainFailed
        }
        try keychain.setPassword(text, account: Account.openVPNJSON, service: Service.metadata)
    }

    func loadOpenVPN() throws -> OpenVPNConfig? {
        guard let text = try keychain.password(account: Account.openVPNJSON, service: Service.metadata),
              let data = text.data(using: .utf8) else { return nil }
        return try decoder.decode(OpenVPNConfig.self, from: data)
    }

    func saveWireGuard(config: WireGuardConfig, privateKey: String) throws {
        let data = try encoder.encode(config)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppRouteError.keychainFailed
        }
        try keychain.setPassword(text, account: Account.wireGuardJSON, service: Service.metadata)
        try keychain.setPassword(privateKey, account: Account.wireGuardPrivateKey, service: Service.secrets)
    }

    func loadWireGuardConfig() throws -> WireGuardConfig? {
        guard let text = try keychain.password(account: Account.wireGuardJSON, service: Service.metadata),
              let data = text.data(using: .utf8) else { return nil }
        return try decoder.decode(WireGuardConfig.self, from: data)
    }

    func loadWireGuardPrivateKey() throws -> String {
        guard let key = try keychain.password(account: Account.wireGuardPrivateKey, service: Service.secrets) else {
            throw AppRouteError.wireGuardPrivateKeyMissing
        }
        return key
    }

    func deleteAll() throws {
        try keychain.delete(account: Account.nordUsername, service: Service.secrets)
        try keychain.delete(account: Account.nordPassword, service: Service.secrets)
        try vpnKeychain.delete(account: Account.ikev2Password, service: Service.ikev2)
        try keychain.delete(account: Account.wireGuardPrivateKey, service: Service.secrets)
        try keychain.delete(account: Account.openVPNJSON, service: Service.metadata)
        try keychain.delete(account: Account.wireGuardJSON, service: Service.metadata)
    }
}
