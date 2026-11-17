import Foundation

struct WireGuardPeer: Codable, Sendable, Equatable {
    var publicKey: String
    var endpointHost: String
    var endpointPort: Int
    var allowedIPs: [String]
    var persistentKeepalive: Int?
}

struct WireGuardConfig: Codable, Sendable, Equatable {
    var address: [String]
    var dns: [String]
    var peer: WireGuardPeer
    var hasPrivateKey: Bool
}

enum WireGuardConfigParser: Sendable {
    static func parse(_ data: Data) throws -> (config: WireGuardConfig, privateKey: String) {
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppRouteError.wireGuardParseFailed("The file was not valid UTF-8.")
        }
        return try parse(text)
    }

    static func parse(_ text: String) throws -> (config: WireGuardConfig, privateKey: String) {
        var section = ""
        var privateKey = ""
        var addresses: [String] = []
        var dns: [String] = []
        var publicKey = ""
        var endpoint = ""
        var allowedIPs: [String] = []
        var keepalive: Int?

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            if line.hasPrefix("[") && line.hasSuffix("]") {
                section = String(line.dropFirst().dropLast()).lowercased()
                continue
            }
            let parts = line.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard parts.count == 2 else { continue }
            let key = parts[0].lowercased()
            let value = parts[1]
            switch (section, key) {
            case ("interface", "privatekey"):
                privateKey = value
            case ("interface", "address"):
                addresses.append(contentsOf: splitList(value))
            case ("interface", "dns"):
                dns.append(contentsOf: splitList(value))
            case ("peer", "publickey"):
                publicKey = value
            case ("peer", "endpoint"):
                endpoint = value
            case ("peer", "allowedips"):
                allowedIPs.append(contentsOf: splitList(value))
            case ("peer", "persistentkeepalive"):
                keepalive = Int(value)
            default:
                continue
            }
        }

        if privateKey.isEmpty {
            throw AppRouteError.wireGuardPrivateKeyMissing
        }
        if publicKey.isEmpty {
            throw AppRouteError.wireGuardParseFailed("No Peer PublicKey was found.")
        }
        let (host, port) = try splitEndpoint(endpoint)
        if allowedIPs.isEmpty {
            allowedIPs = ["0.0.0.0/0", "::/0"]
        }

        let config = WireGuardConfig(
            address: addresses,
            dns: dns,
            peer: WireGuardPeer(
                publicKey: publicKey,
                endpointHost: host,
                endpointPort: port,
                allowedIPs: allowedIPs,
                persistentKeepalive: keepalive
            ),
            hasPrivateKey: true
        )
        return (config, privateKey)
    }

    private static func splitList(_ value: String) -> [String] {
        value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
    }

    private static func splitEndpoint(_ value: String) throws -> (String, Int) {
        if value.isEmpty {
            throw AppRouteError.wireGuardParseFailed("No Peer Endpoint was found.")
        }
        if value.hasPrefix("[") {
            guard let close = value.firstIndex(of: "]") else {
                throw AppRouteError.wireGuardParseFailed("The IPv6 endpoint was malformed.")
            }
            let host = String(value[value.index(after: value.startIndex)..<close])
            let rest = value[value.index(after: close)...]
            let port = Int(rest.trimmingCharacters(in: CharacterSet(charactersIn: ":"))) ?? 51820
            return (host, port)
        }
        if let colon = value.lastIndex(of: ":"),
           let port = Int(value[value.index(after: colon)...]) {
            return (String(value[..<colon]), port)
        }
        return (value, 51820)
    }
}
