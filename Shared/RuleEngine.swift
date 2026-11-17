import Foundation

struct RuleEngine: Sendable {
    var policy: RoutingPolicy

    func classify(host: String) -> DestinationMatch {
        let normalized = Self.normalize(host)
        for service in policy.selectedServices {
            if service.rule.domains.contains(where: { Self.host(normalized, matchesDomain: $0) }) {
                return .vpnService(id: service.id)
            }
        }
        return .direct
    }

    func classify(ip: String) -> DestinationMatch {
        for service in policy.selectedServices {
            if service.rule.allCIDRs.contains(where: { $0.contains(ip: ip) }) {
                return .vpnService(id: service.id)
            }
        }
        return .direct
    }

    func shouldUseVPN(host: String?, ip: String?) -> Bool {
        if let host, case .vpnService = classify(host: host) {
            return true
        }
        if let ip, case .vpnService = classify(ip: ip) {
            return true
        }
        return false
    }

    func includesIPv6() -> Bool {
        policy.combinedRule.ipv6CIDRs.isEmpty == false
            || policy.selectedServices.isEmpty == false
    }

    static func normalize(_ host: String) -> String {
        host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    static func host(_ host: String, matchesDomain domain: String) -> Bool {
        let domain = normalize(domain)
        if host == domain { return true }
        return host.hasSuffix("." + domain)
    }
}
