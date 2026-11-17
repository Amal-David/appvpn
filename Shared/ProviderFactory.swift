import Foundation

enum ProviderFactory: Sendable {
    static func make(kind: ProviderKind, store: CredentialStore) -> any VPNProvider {
        switch kind {
        case .nordManual:
            NordAdapter(store: store)
        case .openVPN:
            OpenVPNAdapter(store: store)
        case .wireGuard:
            WireGuardAdapter(store: store)
        }
    }
}
