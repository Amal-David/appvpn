import Foundation
import Network
import Observation
import os

struct Exit: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var host: String
    var port: Int
}

/// One app's routing: exits to try in order, and what happens when none works.
struct AppRule: Codable, Identifiable, Hashable, Sendable {
    var bundleID: String
    var exitIDs: [UUID]
    var failPolicy: TunnelFailurePolicy = .keepOffline

    var id: String { bundleID }
}

enum ConnectTime: Hashable, Sendable {
    case reachable(Duration)
    case unreachable
}

@Observable
@MainActor
final class RoutingRules {
    var exits: [Exit] { didSet { save() } }
    var rules: [AppRule] { didSet { save() } }
    private(set) var connectTimes: [UUID: ConnectTime] = [:]

    private struct Stored: Codable {
        var exits: [Exit]
        var rules: [AppRule]
    }

    private static let fileURL = URL.applicationSupportDirectory
        .appending(path: "AppRoute", directoryHint: .isDirectory)
        .appending(path: "rules.json")

    init() {
        let stored = (try? Data(contentsOf: Self.fileURL)).flatMap { try? JSONDecoder().decode(Stored.self, from: $0) }
        exits = stored?.exits ?? []
        rules = stored?.rules ?? []
    }

    func exit(_ id: UUID) -> Exit? {
        exits.first { $0.id == id }
    }

    func removeExit(_ id: UUID) {
        exits.removeAll { $0.id == id }
        for index in rules.indices {
            rules[index].exitIDs.removeAll { $0 == id }
        }
    }

    func measureConnectTimes() async {
        let exits = exits
        let measured = await withTaskGroup(of: (UUID, ConnectTime).self) { group in
            for exit in exits {
                group.addTask { (exit.id, await Self.connectTime(host: exit.host, port: exit.port)) }
            }
            var times: [UUID: ConnectTime] = [:]
            for await (id, time) in group { times[id] = time }
            return times
        }
        connectTimes = measured
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: Self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(Stored(exits: exits, rules: rules)).write(to: Self.fileURL, options: .atomic)
        } catch {
            Logger(subsystem: "app.harena.AppRoute.Mac", category: "rules").error("Saving rules failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Time to complete a TCP handshake with the exit. Says the exit is listening, not that it relays traffic.
    private nonisolated static func connectTime(host: String, port: Int) async -> ConnectTime {
        guard let rawPort = UInt16(exactly: port), let port = NWEndpoint.Port(rawValue: rawPort), host.isEmpty == false else {
            return .unreachable
        }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .tcp)
        let start = ContinuousClock.now
        let finished = OSAllocatedUnfairLock(initialState: false)
        return await withCheckedContinuation { continuation in
            let finish: @Sendable (ConnectTime) -> Void = { result in
                let isFirst = finished.withLock { done in
                    defer { done = true }
                    return done == false
                }
                guard isFirst else { return }
                connection.cancel()
                continuation.resume(returning: result)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: finish(.reachable(ContinuousClock.now - start))
                case .failed, .waiting: finish(.unreachable)
                default: break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) { finish(.unreachable) }
        }
    }
}
