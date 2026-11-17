import Foundation

struct RoutingRule: Codable, Sendable, Hashable, Identifiable {
    var id: String
    var domains: [String]
    var ipv4CIDRs: [NetworkCIDR]
    var ipv6CIDRs: [NetworkCIDR]

    var allCIDRs: [NetworkCIDR] {
        ipv4CIDRs + ipv6CIDRs
    }
}
