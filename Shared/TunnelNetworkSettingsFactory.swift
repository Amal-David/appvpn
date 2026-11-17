import Foundation
import NetworkExtension

struct TunnelNetworkSettingsFactory: Sendable {
    var policy: RoutingPolicy

    func makeSettings() -> NEPacketTunnelNetworkSettings {
        let remote = policy.endpoint?.hostname ?? "smart-routing.approute.invalid"
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: remote)
        settings.mtu = 1400
        settings.ipv4Settings = ipv4Settings()
        settings.ipv6Settings = ipv6Settings()
        settings.dnsSettings = dnsSettings()
        return settings
    }

    private func ipv4Settings() -> NEIPv4Settings {
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = includedIPv4Routes()
        ipv4.excludedRoutes = [
            NEIPv4Route.default()
        ]
        return ipv4
    }

    private func ipv6Settings() -> NEIPv6Settings {
        let ipv6 = NEIPv6Settings(addresses: ["fd00:a771::1"], networkPrefixLengths: [64])
        ipv6.includedRoutes = includedIPv6Routes()
        ipv6.excludedRoutes = [
            NEIPv6Route.default()
        ]
        return ipv6
    }

    private func dnsSettings() -> NEDNSSettings {
        let dns = NEDNSSettings(servers: ["198.18.0.1", "fd00:a771::1"])
        dns.matchDomains = policy.combinedRule.domains
        dns.matchDomainsNoSearch = true
        return dns
    }

    private func includedIPv4Routes() -> [NEIPv4Route] {
        var routes = policy.combinedRule.ipv4CIDRs.compactMap { cidr -> NEIPv4Route? in
            guard cidr.family == .ipv4 else { return nil }
            return NEIPv4Route(destinationAddress: cidr.address, subnetMask: Self.ipv4Mask(prefix: cidr.prefixLength))
        }
        routes.append(NEIPv4Route(destinationAddress: "198.18.0.0", subnetMask: "255.255.0.0"))
        return routes
    }

    private func includedIPv6Routes() -> [NEIPv6Route] {
        var routes = policy.combinedRule.ipv6CIDRs.compactMap { cidr -> NEIPv6Route? in
            guard cidr.family == .ipv6 else { return nil }
            return NEIPv6Route(destinationAddress: cidr.address, networkPrefixLength: NSNumber(value: cidr.prefixLength))
        }
        routes.append(NEIPv6Route(destinationAddress: "fd00:a771::", networkPrefixLength: 32))
        return routes
    }

    static func ipv4Mask(prefix: Int) -> String {
        let clamped = min(max(prefix, 0), 32)
        let mask: UInt32 = clamped == 0 ? 0 : ~UInt32((1 << (32 - clamped)) - 1)
        return [
            (mask >> 24) & 0xFF,
            (mask >> 16) & 0xFF,
            (mask >> 8) & 0xFF,
            mask & 0xFF
        ].map(String.init).joined(separator: ".")
    }
}
