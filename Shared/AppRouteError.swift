import Foundation
import NetworkExtension

enum AppRouteError: Error, Sendable, Equatable {
    case invalidCredentialInput
    case nordCredentialsRejected
    case nordCredentialsMissing
    case openVPNParseFailed(String)
    case openVPNNotWiredIntoTunnel
    case wireGuardParseFailed(String)
    case wireGuardPrivateKeyMissing
    case endpointMissing
    case policyUnavailable
    case keychainFailed
    case tunnelStartFailed(String)
    case vpnPermissionDenied
    case vpnConfigurationInvalid
    case authenticationFailed(String)
    case entitlementsUnavailable
    case subscriptionUnavailable(String)

    var userFacingTitle: String {
        switch self {
        case .invalidCredentialInput:
            "That configuration could not be read"
        case .nordCredentialsRejected:
            "Nord service credentials were not accepted"
        case .nordCredentialsMissing:
            "Nord service credentials are missing"
        case .openVPNParseFailed:
            "The OpenVPN file could not be parsed"
        case .openVPNNotWiredIntoTunnel:
            "OpenVPN is imported, but not fully wired"
        case .wireGuardParseFailed:
            "The WireGuard file could not be parsed"
        case .wireGuardPrivateKeyMissing:
            "A WireGuard private key is missing"
        case .endpointMissing:
            "Choose a server location"
        case .policyUnavailable:
            "Routing policy could not be loaded"
        case .keychainFailed:
            "Credentials could not be stored securely"
        case .tunnelStartFailed:
            "VPN could not start"
        case .vpnPermissionDenied:
            "VPN permission was not granted"
        case .vpnConfigurationInvalid:
            "The VPN configuration is invalid"
        case .authenticationFailed:
            "VPN authentication failed"
        case .entitlementsUnavailable:
            "Network Extension entitlements are required"
        case .subscriptionUnavailable:
            "Subscriptions are unavailable"
        }
    }

    var userFacingMessage: String {
        switch self {
        case .invalidCredentialInput:
            "AppRoute expected a different kind of credential for this provider. Nothing on your device was changed."
        case .nordCredentialsRejected:
            "Your Nord service username or password was rejected. These are the service credentials from Nord's manual setup, not your account login. Your normal internet connection has not been changed."
        case .nordCredentialsMissing:
            "Add the Nord service username and password from Nord's manual configuration page before continuing."
        case .openVPNParseFailed(let detail):
            "AppRoute could not read that .ovpn file. \(detail) Your normal internet connection has not been changed."
        case .openVPNNotWiredIntoTunnel:
            "The file was imported and stored locally. A full OpenVPN protocol stack is not part of V1, so this provider cannot yet carry traffic in the packet tunnel."
        case .wireGuardParseFailed(let detail):
            "AppRoute could not read that .conf file. \(detail) Your normal internet connection has not been changed."
        case .wireGuardPrivateKeyMissing:
            "The WireGuard configuration has no PrivateKey. AppRoute did not save an incomplete secret."
        case .endpointMissing:
            "Pick a server or enter a hostname before enabling routing."
        case .policyUnavailable:
            "The shared routing policy file was missing or unreadable. Try saving your services again."
        case .keychainFailed:
            "AppRoute stores secrets only in Keychain. If this keeps happening, check that the Keychain access group entitlement is present."
        case .tunnelStartFailed(let detail):
            "\(detail) The VPN did not connect. Status is not Connected."
        case .vpnPermissionDenied:
            "iOS asked to add a VPN configuration and it was declined. AppRoute cannot start a tunnel without that permission."
        case .vpnConfigurationInvalid:
            "iOS rejected the VPN profile. Check the Nord hostname and service credentials from nordaccount.com (manual setup), then try again."
        case .authenticationFailed(let detail):
            "Nord rejected the service username or password. Use IKEv2 credentials from nordaccount.com (manual setup), not your account email. \(detail)"
        case .entitlementsUnavailable:
            "Packet-tunnel and Personal VPN entitlements must be enabled on an Organization Apple Developer account (Harena) before a device can install a real tunnel. A personal team cannot provision these capabilities."
        case .subscriptionUnavailable(let detail):
            "StoreKit could not load AppRoute Pro. \(detail) The free compatibility checker still works."
        }
    }

    static func fromVPN(_ error: Error) -> AppRouteError {
        if let existing = error as? AppRouteError {
            return existing
        }
        let nsError = error as NSError
        if nsError.domain == "NEConfigurationErrorDomain" {
            return .vpnPermissionDenied
        }
        if nsError.domain == NEVPNErrorDomain {
            switch NEVPNError.Code(rawValue: nsError.code) {
            case .configurationReadWriteFailed:
                return .vpnPermissionDenied
            case .configurationInvalid, .configurationStale, .configurationUnknown:
                return .vpnConfigurationInvalid
            case .configurationDisabled:
                return .tunnelStartFailed("The VPN profile is disabled in Settings.")
            case .connectionFailed:
                break
            case .none:
                break
            @unknown default:
                break
            }
        }
        let text = (nsError.localizedDescription + " " + (nsError.localizedFailureReason ?? "")).lowercased()
        if text.contains("permission") || text.contains("denied") {
            return .vpnPermissionDenied
        }
        if text.contains("auth") || text.contains("password") || text.contains("credential") || text.contains("negotiate") {
            return .authenticationFailed(nsError.localizedDescription)
        }
        return .tunnelStartFailed(nsError.localizedDescription)
    }
}
