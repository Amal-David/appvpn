import Foundation

enum OnboardingStep: String, Codable, Sendable, CaseIterable, Hashable {
    case welcome
    case compatibility
    case howRoutingWorks
    case privacy
    case providerPicker
    case credentialImport
    case serverPicker
    case enableRouting
    case servicePicker
    case routingTest
    case complete

    var title: String {
        switch self {
        case .welcome:
            "Welcome"
        case .compatibility:
            "Compatibility"
        case .howRoutingWorks:
            "How routing works"
        case .privacy:
            "Privacy"
        case .providerPicker:
            "Provider"
        case .credentialImport:
            "Credentials"
        case .serverPicker:
            "Location"
        case .enableRouting:
            "Enable routing"
        case .servicePicker:
            "Services"
        case .routingTest:
            "Test"
        case .complete:
            "Ready"
        }
    }
}
