import Foundation
import NetworkExtension
import Testing
@testable import AppRoute

struct VPNErrorMappingTests {
    @Test func permissionDeniedDomainMapsToVPNPermission() {
        let error = NSError(domain: "NEConfigurationErrorDomain", code: 5, userInfo: [
            NSLocalizedDescriptionKey: "permission denied"
        ])
        #expect(AppRouteError.fromVPN(error) == .vpnPermissionDenied)
    }

    @Test func authWordingMapsToAuthenticationFailed() {
        let error = NSError(domain: NEVPNErrorDomain, code: NEVPNError.Code.connectionFailed.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "IKE authentication failed"
        ])
        guard case .authenticationFailed = AppRouteError.fromVPN(error) else {
            Issue.record("Expected authenticationFailed")
            return
        }
    }

    @Test func connectionStatusDoesNotInventConnected() {
        #expect(ConnectionStatus(vpnStatus: .connecting) == .connecting)
        #expect(ConnectionStatus(vpnStatus: .disconnected) == .disconnected)
        #expect(ConnectionStatus(vpnStatus: .connected) == .connected)
        #expect(ConnectionStatus(vpnStatus: .invalid) != .connected)
    }
}
