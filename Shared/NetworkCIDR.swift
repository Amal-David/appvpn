import Foundation

struct NetworkCIDR: Codable, Sendable, Hashable {
    var family: IPProtocolFamily
    var address: String
    var prefixLength: Int

    var presentation: String {
        "\(address)/\(prefixLength)"
    }

    init(family: IPProtocolFamily, address: String, prefixLength: Int) {
        self.family = family
        self.address = address
        self.prefixLength = prefixLength
    }

    init?(presentation: String) {
        let parts = presentation.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2, let prefix = Int(parts[1]) else { return nil }
        let address = parts[0]
        let family: IPProtocolFamily = address.contains(":") ? .ipv6 : .ipv4
        let maxPrefix = family == .ipv6 ? 128 : 32
        guard prefix >= 0 && prefix <= maxPrefix else { return nil }
        self.init(family: family, address: address, prefixLength: prefix)
    }

    func contains(ip: String) -> Bool {
        switch family {
        case .ipv4:
            return ipv4Contains(ip)
        case .ipv6:
            return ipv6Contains(ip)
        }
    }

    private func ipv4Contains(_ ip: String) -> Bool {
        guard let network = Self.ipv4Address(address), let candidate = Self.ipv4Address(ip) else {
            return false
        }
        if prefixLength == 0 { return true }
        let shift = UInt32(32 - prefixLength)
        let mask = shift >= 32 ? UInt32(0) : ~UInt32((1 << shift) - 1)
        return (network & mask) == (candidate & mask)
    }

    private func ipv6Contains(_ ip: String) -> Bool {
        guard let network = Self.ipv6Address(address), let candidate = Self.ipv6Address(ip) else {
            return false
        }
        var remaining = prefixLength
        for index in 0..<8 {
            if remaining <= 0 { break }
            let bits = min(16, remaining)
            let mask: UInt16 = bits == 16 ? 0xFFFF : UInt16((0xFFFF << (16 - bits)) & 0xFFFF)
            if (network[index] & mask) != (candidate[index] & mask) {
                return false
            }
            remaining -= bits
        }
        return true
    }

    static func ipv4Address(_ value: String) -> UInt32? {
        let parts = value.split(separator: ".").map(String.init)
        guard parts.count == 4 else { return nil }
        var result: UInt32 = 0
        for part in parts {
            guard let octet = UInt32(part), octet <= 255 else { return nil }
            result = (result << 8) + octet
        }
        return result
    }

    static func ipv6Address(_ value: String) -> [UInt16]? {
        let trimmed = value.lowercased()
        if trimmed.contains("."), let mapped = ipv4Mapped(trimmed) {
            return mapped
        }
        let halves = trimmed.split(separator: "::", omittingEmptySubsequences: false).map(String.init)
        if halves.count > 2 { return nil }
        func parseGroup(_ text: String) -> [UInt16]? {
            if text.isEmpty { return [] }
            var groups: [UInt16] = []
            for part in text.split(separator: ":") {
                guard let value = UInt16(part, radix: 16) else { return nil }
                groups.append(value)
            }
            return groups
        }
        if halves.count == 1 {
            return parseGroup(halves[0]).flatMap { $0.count == 8 ? $0 : nil }
        }
        guard let head = parseGroup(halves[0]), let tail = parseGroup(halves[1]) else { return nil }
        if head.count + tail.count > 8 { return nil }
        let zeros = Array(repeating: UInt16(0), count: 8 - head.count - tail.count)
        return head + zeros + tail
    }

    private static func ipv4Mapped(_ value: String) -> [UInt16]? {
        guard let dotted = value.split(separator: ":").last, let ipv4 = ipv4Address(String(dotted)) else {
            return nil
        }
        return [
            0, 0, 0, 0, 0, 0xFFFF,
            UInt16((ipv4 >> 16) & 0xFFFF),
            UInt16(ipv4 & 0xFFFF)
        ]
    }
}
