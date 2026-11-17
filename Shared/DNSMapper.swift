import Foundation

struct DNSMapping: Sendable, Equatable {
    var hostname: String
    var ipv4: String
    var ipv6: String
}

struct DNSMapper: Sendable {
    private var fakeIPv4Base: UInt32 = 0xC6330001
    private var fakeIPv6Base: [UInt16] = [0xFD00, 0xA771, 0, 0, 0, 0, 0, 1]
    private var table: [String: DNSMapping] = [:]

    mutating func mapping(for host: String) -> DNSMapping {
        let key = RuleEngine.normalize(host)
        if let existing = table[key] {
            return existing
        }
        let index = UInt32(table.count + 1)
        let ipv4 = Self.dotted(fakeIPv4Base &+ index)
        let ipv6 = Self.colon(fakeIPv6Base, hostIndex: index)
        let mapping = DNSMapping(hostname: key, ipv4: ipv4, ipv6: ipv6)
        table[key] = mapping
        return mapping
    }

    func hostname(forFakeIPv4 ip: String) -> String? {
        table.first { $0.value.ipv4 == ip }?.key
    }

    func hostname(forFakeIPv6 ip: String) -> String? {
        table.first { $0.value.ipv6.lowercased() == ip.lowercased() }?.key
    }

    var mappings: [DNSMapping] {
        Array(table.values)
    }

    private static func dotted(_ value: UInt32) -> String {
        let a = (value >> 24) & 0xFF
        let b = (value >> 16) & 0xFF
        let c = (value >> 8) & 0xFF
        let d = value & 0xFF
        return "\(a).\(b).\(c).\(d)"
    }

    private static func colon(_ base: [UInt16], hostIndex: UInt32) -> String {
        var groups = base
        groups[6] = UInt16((hostIndex >> 16) & 0xFFFF)
        groups[7] = UInt16(hostIndex & 0xFFFF)
        return groups.map { String(format: "%x", $0) }.joined(separator: ":")
    }
}
