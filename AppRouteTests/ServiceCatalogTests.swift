import Foundation
import Testing
@testable import AppRoute

struct ServiceCatalogTests {
    @Test func catalogueIsServicesNotInstalledApps() {
        #expect(ServiceCatalog.all.count >= 8)
        #expect(ServiceCatalog.all.contains { $0.id == "tiktok" })
        #expect(ServiceCatalog.all.contains { $0.name == "YouTube" })
    }

    @Test func youtubeDoesNotClaimAllOfGoogle() throws {
        let youtube = try #require(ServiceCatalog.service(id: "youtube"))
        #expect(youtube.rule.domains.contains("google.com") == false)
        #expect(youtube.rule.domains.contains("googleapis.com") == false)
        #expect(youtube.rule.domains.contains("youtube.com"))
        #expect(youtube.rule.domains.contains("googlevideo.com"))
    }

    @Test func combinedRuleUnionsSelectedDomains() {
        let rule = ServiceCatalog.combinedRule(for: ["instagram", "x"])
        #expect(rule.domains.contains("instagram.com"))
        #expect(rule.domains.contains("x.com"))
        #expect(rule.domains.contains("tiktok.com") == false)
    }
}
