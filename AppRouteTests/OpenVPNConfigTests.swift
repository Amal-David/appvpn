import Foundation
import Testing
@testable import AppRoute

struct OpenVPNConfigTests {
    @Test func parsesRemoteAndProto() throws {
        let file = """
        client
        proto udp
        remote vpn.example.net 1194
        cipher AES-256-GCM
        auth-user-pass
        <ca>
        -----BEGIN CERTIFICATE-----
        MIIB
        -----END CERTIFICATE-----
        </ca>
        """
        let config = try OpenVPNConfigParser.parse(file)
        #expect(config.remoteHost == "vpn.example.net")
        #expect(config.remotePort == 1194)
        #expect(config.proto == "udp")
        #expect(config.hasAuthUserPass)
        #expect(config.hasEmbeddedCertificate)
    }

    @Test func missingRemoteFails() {
        let file = "client\nproto udp\n"
        #expect(throws: AppRouteError.self) {
            try OpenVPNConfigParser.parse(file)
        }
    }
}
