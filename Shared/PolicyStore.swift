import Foundation

actor PolicyStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        decoder = JSONDecoder()
    }

    func load() throws -> RoutingPolicy {
        guard let url = fileURL() else { return .empty }
        guard FileManager.default.fileExists(atPath: url.path) else { return .empty }
        let data = try Data(contentsOf: url)
        return try decoder.decode(RoutingPolicy.self, from: data)
    }

    func save(_ policy: RoutingPolicy) throws {
        guard let url = fileURL() else {
            throw AppRouteError.policyUnavailable
        }
        let data = try encoder.encode(policy)
        try data.write(to: url, options: [.atomic])
        UserDefaults(suiteName: AppRouteConstants.appGroupIdentifier)?
            .set(policy.isRoutingEnabled, forKey: "isRoutingEnabled")
    }

    func delete() throws {
        guard let url = fileURL() else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        UserDefaults(suiteName: AppRouteConstants.appGroupIdentifier)?
            .removeObject(forKey: "isRoutingEnabled")
    }

    private func fileURL() -> URL? {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppRouteConstants.appGroupIdentifier) {
            return group.appendingPathComponent(AppRouteConstants.policyFileName)
        }
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppRoute", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(AppRouteConstants.policyFileName)
    }
}
