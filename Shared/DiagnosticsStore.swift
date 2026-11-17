import Foundation

actor DiagnosticsStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func load() -> TunnelDiagnosticsSnapshot {
        guard let url = fileURL(),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let snapshot = try? decoder.decode(TunnelDiagnosticsSnapshot.self, from: data) else {
            return TunnelDiagnosticsSnapshot(
                lastStarted: nil,
                lastError: nil,
                classifiedVPNCount: 0,
                classifiedDirectCount: 0,
                handshakeTODO: "Provider handshake is not completed in V1.",
                ipv6Enabled: true
            )
        }
        return snapshot
    }

    func save(_ snapshot: TunnelDiagnosticsSnapshot) throws {
        guard let url = fileURL() else { return }
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }

    private func fileURL() -> URL? {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppRouteConstants.appGroupIdentifier) {
            return group.appendingPathComponent("tunnel-diagnostics.json")
        }
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppRoute", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("tunnel-diagnostics.json")
    }
}
