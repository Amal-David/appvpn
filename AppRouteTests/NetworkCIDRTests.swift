import Foundation
import Testing
@testable import AppRoute

struct NetworkCIDRTests {
    @Test func ipv4Prefix24ContainsHosts() throws {
        let cidr = try #require(NetworkCIDR(presentation: "192.168.1.0/24"))
        #expect(cidr.contains(ip: "192.168.1.20"))
        #expect(cidr.contains(ip: "192.168.2.1") == false)
    }

    @Test func ipv6PrefixMatches() throws {
        let cidr = try #require(NetworkCIDR(presentation: "2606:4700::/32"))
        #expect(cidr.contains(ip: "2606:4700:90:0:0:0:0:1"))
        #expect(cidr.contains(ip: "2607:4700::1") == false)
    }
}

struct NordCredentialTests {
    @Test func rejectsAccountEmails() {
        #expect(throws: AppRouteError.nordCredentialsRejected) {
            try NordCredentialValidator.validateFormat(
                NordCredentials(username: "user@example.com", password: "password12")
            )
        }
    }

    @Test func acceptsServiceUsername() throws {
        try NordCredentialValidator.validateFormat(
            NordCredentials(username: "nordServiceUser", password: "password12")
        )
    }
}

struct RoutingPolicyTests {
    @Test func emptyPolicyHasPrivacyFirstFailureMode() {
        #expect(RoutingPolicy.empty.failurePolicy == .keepOffline)
        #expect(RoutingPolicy.empty.isRoutingEnabled == false)
        #expect(RoutingPolicy.empty.selectedServiceIDs.isEmpty)
    }
}
