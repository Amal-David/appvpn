import Foundation

struct RoutingPolicy: Codable, Sendable, Equatable {
    var providerKind: ProviderKind?
    var endpoint: VPNEndpoint?
    var selectedServiceIDs: [String]
    var failurePolicy: TunnelFailurePolicy
    var isRoutingEnabled: Bool
    var tunnelConfiguration: TunnelConfiguration?

    static let empty = RoutingPolicy(
        providerKind: nil,
        endpoint: nil,
        selectedServiceIDs: [],
        failurePolicy: .keepOffline,
        isRoutingEnabled: false,
        tunnelConfiguration: nil
    )

    var selectedServices: [ServiceDefinition] {
        ServiceCatalog.services(ids: selectedServiceIDs)
    }

    var combinedRule: RoutingRule {
        ServiceCatalog.combinedRule(for: selectedServiceIDs)
    }
}
