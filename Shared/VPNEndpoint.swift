import Foundation

struct VPNEndpoint: Codable, Sendable, Hashable, Identifiable {
    var id: UUID
    var displayName: String
    var country: String
    var city: String
    var hostname: String
    var port: Int
    var isExample: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        country: String,
        city: String,
        hostname: String,
        port: Int,
        isExample: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.country = country
        self.city = city
        self.hostname = hostname
        self.port = port
        self.isExample = isExample
    }
}
