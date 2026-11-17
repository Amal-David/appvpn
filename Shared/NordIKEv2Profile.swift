import Foundation
import NetworkExtension

enum NordIKEv2Profile: Sendable {
    static func makeProtocol(
        hostname: String,
        username: String,
        passwordReference: Data
    ) -> NEVPNProtocolIKEv2 {
        let proto = NEVPNProtocolIKEv2()
        proto.serverAddress = hostname
        proto.remoteIdentifier = hostname
        proto.localIdentifier = username
        proto.username = username
        proto.passwordReference = passwordReference
        proto.authenticationMethod = .none
        proto.useExtendedAuthentication = true
        proto.deadPeerDetectionRate = .medium
        proto.disconnectOnSleep = false
        proto.enablePFS = true
        proto.excludeLocalNetworks = true
        applyNordSecurityAssociation(proto.ikeSecurityAssociationParameters)
        applyNordSecurityAssociation(proto.childSecurityAssociationParameters)
        return proto
    }

    private static func applyNordSecurityAssociation(_ parameters: NEVPNIKEv2SecurityAssociationParameters) {
        parameters.encryptionAlgorithm = .algorithmAES256
        parameters.integrityAlgorithm = .SHA256
        parameters.diffieHellmanGroup = .group14
        parameters.lifetimeMinutes = 1440
    }
}
