import Foundation

struct OpenVPNConfig: Codable, Sendable, Equatable {
    var remoteHost: String
    var remotePort: Int
    var proto: String
    var cipher: String?
    var dataCiphers: [String]
    var hasEmbeddedCertificate: Bool
    var hasAuthUserPass: Bool
    var rawLineCount: Int

    var displayProtocol: String {
        "\(proto.uppercased()) \(remoteHost):\(remotePort)"
    }
}

enum OpenVPNConfigParser: Sendable {
    static func parse(_ data: Data) throws -> OpenVPNConfig {
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppRouteError.openVPNParseFailed("The file was not valid UTF-8.")
        }
        return try parse(text)
    }

    static func parse(_ text: String) throws -> OpenVPNConfig {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false && $0.hasPrefix("#") == false && $0.hasPrefix(";") == false }

        var remoteHost: String?
        var remotePort = 1194
        var proto = "udp"
        var cipher: String?
        var dataCiphers: [String] = []
        var hasEmbeddedCertificate = false
        var hasAuthUserPass = false

        for line in lines {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let command = parts.first?.lowercased() else { continue }
            switch command {
            case "remote":
                if parts.count >= 2 {
                    remoteHost = parts[1]
                }
                if parts.count >= 3, let port = Int(parts[2]) {
                    remotePort = port
                }
            case "proto":
                if parts.count >= 2 {
                    proto = parts[1].lowercased()
                }
            case "port":
                if parts.count >= 2, let port = Int(parts[1]) {
                    remotePort = port
                }
            case "cipher":
                if parts.count >= 2 {
                    cipher = parts[1]
                }
            case "data-ciphers":
                dataCiphers = parts.dropFirst().flatMap { $0.split(separator: ":").map(String.init) }
            case "auth-user-pass":
                hasAuthUserPass = true
            case "<ca>", "<cert>", "<key>", "<tls-auth>", "<tls-crypt>":
                hasEmbeddedCertificate = true
            default:
                if line.hasPrefix("<ca>") || line.hasPrefix("<cert>") || line.hasPrefix("<key>") {
                    hasEmbeddedCertificate = true
                }
            }
        }

        if text.contains("<ca>") || text.contains("<cert>") || text.contains("<key>") {
            hasEmbeddedCertificate = true
        }

        guard let host = remoteHost, host.isEmpty == false else {
            throw AppRouteError.openVPNParseFailed("No `remote` host was found.")
        }

        return OpenVPNConfig(
            remoteHost: host,
            remotePort: remotePort,
            proto: proto,
            cipher: cipher,
            dataCiphers: dataCiphers,
            hasEmbeddedCertificate: hasEmbeddedCertificate,
            hasAuthUserPass: hasAuthUserPass,
            rawLineCount: lines.count
        )
    }
}
