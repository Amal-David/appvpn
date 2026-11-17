import Foundation

struct ServiceDefinition: Codable, Sendable, Hashable, Identifiable {
    var id: String
    var name: String
    var systemImage: String
    var summary: String
    var rule: RoutingRule

    var domainCount: Int { rule.domains.count }
}
