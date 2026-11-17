import Darwin
import Foundation

actor TunnelRuntimeState {
    private var ruleEngine = RuleEngine(policy: .empty)
    private var classifiedVPNCount = 0
    private var classifiedDirectCount = 0
    private var cancelled = false

    func install(policy: RoutingPolicy) {
        ruleEngine = RuleEngine(policy: policy)
        cancelled = false
    }

    func cancel() {
        cancelled = true
    }

    func isCancelled() -> Bool {
        cancelled
    }

    func counts() -> (vpn: Int, direct: Int) {
        (classifiedVPNCount, classifiedDirectCount)
    }

    func classify(packets: [Data], protocols: [NSNumber]) {
        // Packets are inspected only for destination classification. Payload is never logged.
        for (packet, proto) in zip(packets, protocols) {
            let family: IPProtocolFamily = proto.intValue == Int(AF_INET6) ? .ipv6 : .ipv4
            if let ip = Self.destinationIP(packet: packet, family: family) {
                switch ruleEngine.classify(ip: ip) {
                case .vpnService:
                    classifiedVPNCount += 1
                case .direct:
                    classifiedDirectCount += 1
                }
            } else {
                classifiedDirectCount += 1
            }
        }
        // TODO: Complete provider handshake (IKEv2 / WireGuard) then encapsulate matched packets.
    }

    private static func destinationIP(packet: Data, family: IPProtocolFamily) -> String? {
        switch family {
        case .ipv4:
            guard packet.count >= 20 else { return nil }
            return "\(packet[16]).\(packet[17]).\(packet[18]).\(packet[19])"
        case .ipv6:
            guard packet.count >= 40 else { return nil }
            let bytes = Array(packet[24..<40])
            var groups: [String] = []
            var index = 0
            while index < 16 {
                let value = UInt16(bytes[index]) << 8 | UInt16(bytes[index + 1])
                groups.append(String(format: "%x", value))
                index += 2
            }
            return groups.joined(separator: ":")
        }
    }
}
