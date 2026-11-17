import Foundation

actor LocalAnalytics {
    private var events: [FunnelEvent] = []
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        events = Self.readFromDisk(decoder: decoder)
    }

    func record(_ name: FunnelEventName, selectedServiceCount: Int? = nil) {
        let event = FunnelEvent(
            name: name,
            timestamp: Date(),
            selectedServiceCount: selectedServiceCount
        )
        events.append(event)
        try? persist()
    }

    func snapshot() -> [FunnelEvent] {
        events
    }

    func deleteAll() {
        events = []
        try? persist()
    }

    private func persist() throws {
        guard let url = Self.fileURL() else { return }
        let data = try encoder.encode(events)
        try data.write(to: url, options: [.atomic])
    }

    private static func readFromDisk(decoder: JSONDecoder) -> [FunnelEvent] {
        guard let url = fileURL(), FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([FunnelEvent].self, from: data)) ?? []
    }

    private static func fileURL() -> URL? {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppRouteConstants.appGroupIdentifier) {
            return group.appendingPathComponent(AppRouteConstants.analyticsFileName)
        }
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AppRoute", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(AppRouteConstants.analyticsFileName)
    }
}
