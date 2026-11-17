import Foundation
import Testing
@testable import AppRoute

struct RuleEngineTests {
    private let engine: RuleEngine

    init() {
        var policy = RoutingPolicy.empty
        policy.selectedServiceIDs = ["tiktok", "youtube"]
        engine = RuleEngine(policy: policy)
    }

    @Test(arguments: [
        "tiktok.com",
        "www.tiktok.com",
        "pull-f5.tiktokcdn.com",
        "youtube.com",
        "googlevideo.com"
    ])
    func selectedServiceHostsUseVPN(host: String) {
        let match = engine.classify(host: host)
        guard case .vpnService = match else {
            Issue.record("\(host) should match a selected service")
            return
        }
        #expect(engine.shouldUseVPN(host: host, ip: nil))
    }

    @Test(arguments: [
        "apple.com",
        "bankofamerica.com",
        "wikipedia.org",
        "google.com"
    ])
    func unmarkedHostsStayDirect(host: String) {
        #expect(engine.classify(host: host) == .direct)
        #expect(engine.shouldUseVPN(host: host, ip: nil) == false)
    }

    @Test func ipv4CIDRMatchesTikTokExampleRange() {
        #expect(engine.classify(ip: "162.159.128.10") != .direct)
    }

    @Test func ipv6IsPartOfThePolicyModel() {
        #expect(engine.includesIPv6())
    }
}
