import Foundation

enum AppRouteConstants: Sendable {
    static let appGroupIdentifier = "group.app.harena.approute"
    /// The signing team prefix comes from the build (Info.plist), so no team ID lives in source.
    static let keychainAccessGroup =
        (Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String ?? "") + "app.harena.approute"
    static let hostBundleIdentifier = "app.harena.AppRoute"
    static let tunnelBundleIdentifier = "app.harena.AppRoute.Tunnel"
    static let policyFileName = "routing-policy.json"
    static let analyticsFileName = "local-funnel.json"
    static let tunnelProviderDescription = "AppRoute Smart Routing"
    static let ikev2Description = "AppRoute Nord IKEv2"
}
