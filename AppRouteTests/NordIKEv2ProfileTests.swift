import Foundation
import NetworkExtension
import Testing
@testable import AppRoute

struct NordIKEv2ProfileTests {
    @Test func configuresManualNordIKEv2() {
        let passwordReference = Data([0x01, 0x02, 0x03, 0x04])
        let proto = NordIKEv2Profile.makeProtocol(
            hostname: "us8246.nordvpn.com",
            username: "nordUser12",
            passwordReference: passwordReference
        )
        #expect(proto.serverAddress == "us8246.nordvpn.com")
        #expect(proto.remoteIdentifier == "us8246.nordvpn.com")
        #expect(proto.localIdentifier == "nordUser12")
        #expect(proto.username == "nordUser12")
        #expect(proto.passwordReference == passwordReference)
        #expect(proto.useExtendedAuthentication == true)
        #expect(proto.authenticationMethod == .none)
    }
}

struct ConnectionStatusTests {
    @Test func connectedTitleIsConnected() {
        #expect(ConnectionStatus(vpnStatus: .connected).title == "Connected")
        #expect(ConnectionStatus(vpnStatus: .connecting).title == "Connecting")
        #expect(ConnectionStatus(vpnStatus: .disconnected).title == "Disconnected")
        #expect(ConnectionStatus(vpnStatus: .connected).isActive)
        #expect(ConnectionStatus.disconnected.isActive == false)
    }
}
