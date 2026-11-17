import Foundation
import Security

struct KeychainClient: Sendable {
    var accessGroup: String

    func setPassword(_ password: String, account: String, service: String) throws {
        try delete(account: account, service: service)
        guard let data = password.data(using: .utf8) else {
            throw AppRouteError.keychainFailed
        }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessGroup.isEmpty
                ? kSecAttrAccessibleAfterFirstUnlock
                : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        if accessGroup.isEmpty == false {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            return
        }
        if accessGroup.isEmpty == false {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            let fallback = SecItemAdd(query as CFDictionary, nil)
            if fallback == errSecSuccess {
                return
            }
        }
        throw AppRouteError.keychainFailed
    }

    func persistentPasswordReference(account: String, service: String) throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnPersistentRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if accessGroup.isEmpty == false {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound, accessGroup.isEmpty == false {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw AppRouteError.keychainFailed
        }
        return data
    }

    func password(account: String, service: String) throws -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if accessGroup.isEmpty == false {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound, accessGroup.isEmpty == false {
            query.removeValue(forKey: kSecAttrAccessGroup as String)
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw AppRouteError.keychainFailed
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(account: String, service: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        if accessGroup.isEmpty == false {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AppRouteError.keychainFailed
        }
    }
}
