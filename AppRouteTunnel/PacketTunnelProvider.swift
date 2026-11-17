import Darwin
import Foundation
import NetworkExtension
import os.log

@objc(PacketTunnelProvider)
final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private let log = Logger(subsystem: AppRouteConstants.tunnelBundleIdentifier, category: "tunnel")
    private let policyStore = PolicyStore()
    private let diagnosticsStore = DiagnosticsStore()
    private let state = TunnelRuntimeState()

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let completer = OnceCompletion<Error?>(completionHandler)
        let policyStore = policyStore
        let diagnosticsStore = diagnosticsStore
        let state = state
        let log = log
        Task {
            do {
                let policy = try await Self.preparePolicy(policyStore)
                let settings = TunnelNetworkSettingsFactory(policy: policy).makeSettings()
                try await self.setTunnelNetworkSettings(settings)
                await state.install(policy: policy)
                var snapshot = await diagnosticsStore.load()
                snapshot.lastStarted = Date()
                snapshot.lastError = nil
                snapshot.handshakeTODO = Self.handshakeMessage()
                snapshot.ipv6Enabled = true
                try await diagnosticsStore.save(snapshot)
        log.notice("Packet tunnel applied destination rules. Provider handshake is not completed for WireGuard in this build.")
                completer.finish(nil)
                self.readLoop()
            } catch {
                log.error("Tunnel start failed")
                completer.finish(error)
            }
        }
        _ = options
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        let completer = OnceCompletion<Void>({ _ in completionHandler() })
        let state = state
        let log = log
        Task {
            await state.cancel()
            log.notice("Stopping tunnel, reason logged without packet data")
            completer.finish(())
        }
        _ = reason
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        let completer = OnceCompletion<Data?>(completionHandler ?? { _ in })
        let state = state
        Task {
            let counts = await state.counts()
            let snapshot = TunnelDiagnosticsSnapshot(
                lastStarted: Date(),
                lastError: nil,
                classifiedVPNCount: counts.vpn,
                classifiedDirectCount: counts.direct,
                handshakeTODO: Self.handshakeMessage(),
                ipv6Enabled: true
            )
            completer.finish(try? JSONEncoder().encode(snapshot))
        }
        _ = messageData
    }

    private static func preparePolicy(_ store: PolicyStore) async throws -> RoutingPolicy {
        let policy = try await store.load()
        guard policy.isRoutingEnabled else {
            throw AppRouteError.policyUnavailable
        }
        if policy.tunnelConfiguration?.protocolReadiness.isFullyWired == false {
            throw AppRouteError.openVPNNotWiredIntoTunnel
        }
        return policy
    }

    private func readLoop() {
        let state = state
        packetFlow.readPackets { packets, protocols in
            Task {
                if await state.isCancelled() { return }
                await state.classify(packets: packets, protocols: protocols)
            }
            Task {
                if await state.isCancelled() == false {
                    self.readLoop()
                }
            }
        }
    }

    private static func handshakeMessage() -> String {
        "Packet tunnel installed IPv4+IPv6 destination rules. WireGuard handshake is not completed in this build. Secrets stay in Keychain and are never logged."
    }
}
