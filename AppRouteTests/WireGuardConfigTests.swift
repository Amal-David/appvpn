import Foundation
import Testing
@testable import AppRoute

struct WireGuardConfigTests {
    @Test func parsesInterfaceAndPeer() throws {
        let file = """
        [Interface]
        PrivateKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
        Address = 10.64.0.2/32, fd00::2/128
        DNS = 1.1.1.1

        [Peer]
        PublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=
        Endpoint = vpn.example.net:51820
        AllowedIPs = 0.0.0.0/0, ::/0
        PersistentKeepalive = 25
        """
        let parsed = try WireGuardConfigParser.parse(file)
        #expect(parsed.config.peer.endpointHost == "vpn.example.net")
        #expect(parsed.config.peer.endpointPort == 51820)
        #expect(parsed.config.hasPrivateKey)
        #expect(parsed.privateKey.isEmpty == false)
        #expect(parsed.config.address.contains("fd00::2/128"))
    }

    @Test func missingPrivateKeyFailsWithoutSaving() {
        let file = """
        [Interface]
        Address = 10.0.0.2/32
        [Peer]
        PublicKey = BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=
        Endpoint = vpn.example.net:51820
        """
        #expect(throws: AppRouteError.wireGuardPrivateKeyMissing) {
            try WireGuardConfigParser.parse(file)
        }
    }
}
