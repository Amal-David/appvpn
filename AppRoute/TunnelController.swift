import Foundation
import NetworkExtension
import Observation

@Observable
@MainActor
final class TunnelController {
    var status: ConnectionStatus = .invalid
    var lastMessage: String?
    var lastError: AppRouteError?

    private let credentials: CredentialStore
    private var packetTunnelManager: NETunnelProviderManager?
    private var statusObserverTask: Task<Void, Never>?

    init(credentials: CredentialStore) {
        self.credentials = credentials
        statusObserverTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .NEVPNStatusDidChange)
            for await notification in notifications {
                guard let self else { break }
                self.applyStatus(from: notification)
            }
        }
    }

    func refresh() async {
        let ikeManager = NEVPNManager.shared()
        do {
            try await ikeManager.loadFromPreferences()
        } catch {
            lastError = AppRouteError.fromVPN(error)
            lastMessage = lastError?.userFacingMessage
        }

        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            packetTunnelManager = managers.first
        } catch {
            lastError = AppRouteError.fromVPN(error)
            lastMessage = lastError?.userFacingMessage
        }

        status = resolvedStatus(ikeManager: ikeManager, packetTunnelManager: packetTunnelManager)
        if status == .disconnected {
            await captureDisconnectError(ikeManager.connection)
        }
    }

    func start(policy: RoutingPolicy) async throws {
        lastError = nil
        guard let kind = policy.providerKind else {
            throw AppRouteError.invalidCredentialInput
        }
        switch kind {
        case .nordManual:
            guard let endpoint = policy.endpoint else { throw AppRouteError.endpointMissing }
            guard let nord = try await credentials.loadNord() else {
                throw AppRouteError.nordCredentialsMissing
            }
            let passwordReference = try await credentials.nordPasswordPersistentReference()
            try await startNordIKEv2(
                endpoint: endpoint,
                username: nord.username,
                passwordReference: passwordReference
            )
        case .wireGuard:
            try await installPacketTunnel(policy: policy)
            try await startPacketTunnel()
        case .openVPN:
            throw AppRouteError.openVPNNotWiredIntoTunnel
        }
    }

    func enableAndStart(policy: RoutingPolicy, nordPasswordReference: Data?, nordUsername: String?) async throws {
        _ = nordPasswordReference
        _ = nordUsername
        try await start(policy: policy)
    }

    func startNordIKEv2(endpoint: VPNEndpoint, username: String, passwordReference: Data) async throws {
        lastError = nil
        let manager = NEVPNManager.shared()
        do {
            try await manager.loadFromPreferences()
            manager.protocolConfiguration = NordIKEv2Profile.makeProtocol(
                hostname: endpoint.hostname,
                username: username,
                passwordReference: passwordReference
            )
            manager.localizedDescription = AppRouteConstants.ikev2Description
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            if manager.isEnabled == false {
                manager.isEnabled = true
                try await manager.saveToPreferences()
                try await manager.loadFromPreferences()
            }
            status = ConnectionStatus(vpnStatus: manager.connection.status)
            if manager.connection.status != .connected && manager.connection.status != .connecting {
                try manager.connection.startVPNTunnel()
            }
            status = ConnectionStatus(vpnStatus: manager.connection.status)
            lastMessage = status.title
        } catch {
            let mapped = AppRouteError.fromVPN(error)
            lastError = mapped
            lastMessage = mapped.userFacingMessage
            let systemStatus = ConnectionStatus(vpnStatus: manager.connection.status)
            status = systemStatus
            throw mapped
        }
    }

    func installPacketTunnel(policy: RoutingPolicy) async throws {
        do {
            let existing = try await NETunnelProviderManager.loadAllFromPreferences()
            let manager = existing.first ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = AppRouteConstants.tunnelBundleIdentifier
            proto.serverAddress = policy.endpoint?.hostname ?? "Smart Routing"
            proto.excludeLocalNetworks = true
            manager.localizedDescription = AppRouteConstants.tunnelProviderDescription
            manager.protocolConfiguration = proto
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            packetTunnelManager = manager
            status = ConnectionStatus(vpnStatus: manager.connection.status)
        } catch {
            let mapped = AppRouteError.fromVPN(error)
            lastError = mapped
            lastMessage = mapped.userFacingMessage
            throw mapped
        }
    }

    func startPacketTunnel() async throws {
        try await refresh()
        guard let packetTunnelManager else {
            throw AppRouteError.tunnelStartFailed("Install Smart Routing before connecting.")
        }
        if packetTunnelManager.connection.status == .connected || packetTunnelManager.connection.status == .connecting {
            status = ConnectionStatus(vpnStatus: packetTunnelManager.connection.status)
            return
        }
        do {
            try packetTunnelManager.connection.startVPNTunnel()
            status = ConnectionStatus(vpnStatus: packetTunnelManager.connection.status)
            lastMessage = status.title
        } catch {
            let mapped = AppRouteError.fromVPN(error)
            lastError = mapped
            lastMessage = mapped.userFacingMessage
            throw mapped
        }
    }

    func stop() async {
        NEVPNManager.shared().connection.stopVPNTunnel()
        packetTunnelManager?.connection.stopVPNTunnel()
        status = .disconnected
        lastMessage = status.title
    }

    private func applyStatus(from notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else {
            Task { await refresh() }
            return
        }
        let next = ConnectionStatus(vpnStatus: connection.status)
        status = next
        lastMessage = next.title
        if next == .disconnected {
            Task { await captureDisconnectError(connection) }
        }
    }

    private func captureDisconnectError(_ connection: NEVPNConnection) async {
        do {
            try await connection.fetchLastDisconnectError()
        } catch {
            let text = (error as NSError).localizedDescription.lowercased()
            if text.contains("no error") || text.contains("not available") {
                return
            }
            let mapped = AppRouteError.fromVPN(error)
            lastError = mapped
            lastMessage = mapped.userFacingMessage
        }
    }

    private func resolvedStatus(
        ikeManager: NEVPNManager,
        packetTunnelManager: NETunnelProviderManager?
    ) -> ConnectionStatus {
        let ikeStatus = ConnectionStatus(vpnStatus: ikeManager.connection.status)
        if ikeManager.protocolConfiguration is NEVPNProtocolIKEv2, ikeStatus.isActive {
            return ikeStatus
        }
        if let packetTunnelManager {
            let tunnelStatus = ConnectionStatus(vpnStatus: packetTunnelManager.connection.status)
            if tunnelStatus.isActive {
                return tunnelStatus
            }
        }
        if ikeManager.protocolConfiguration is NEVPNProtocolIKEv2 {
            return ikeStatus
        }
        if let packetTunnelManager {
            return ConnectionStatus(vpnStatus: packetTunnelManager.connection.status)
        }
        return .invalid
    }
}
