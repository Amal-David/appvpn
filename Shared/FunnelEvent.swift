import Foundation

enum FunnelEventName: String, Codable, Sendable {
    case install
    case compatibilityChecked
    case existingMDMReported
    case privacyDisclosureViewed
    case providerSelected
    case credentialsValidated
    case routingEnabled
    case serviceSelectionSaved
    case routeTestStarted
    case routeTestPassed
    case routeTestFailed
    case subscriptionStarted
    case privacyDeleted
}

struct FunnelEvent: Codable, Sendable, Equatable {
    var name: FunnelEventName
    var timestamp: Date
    var selectedServiceCount: Int?
}
