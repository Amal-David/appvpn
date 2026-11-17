import Foundation
import NetworkExtension
import Observation
import SystemExtensions

@Observable
@MainActor
final class ProxyController: NSObject, OSSystemExtensionRequestDelegate {
    static let extensionBundleIdentifier = "app.harena.AppRoute.Mac.Proxy"

    var status: NEVPNStatus = .invalid
    var message: String?

    private var manager: NETransparentProxyManager?
    private var pendingExit: (host: String, port: Int)?

    override init() {
        super.init()
        Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: .NEVPNStatusDidChange) {
                guard let connection = notification.object as? NEVPNConnection else { continue }
                self?.status = connection.status
            }
        }
        Task { await loadManager() }
    }

    func turnOn(exitHost: String, exitPort: Int) {
        message = nil
        pendingExit = (exitHost, exitPort)
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: Self.extensionBundleIdentifier,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }

    func turnOff() {
        manager?.connection.stopVPNTunnel()
    }

    /// The extension outlives the app, so quitting has to stop it and wait, or routed apps stay on the exit.
    func stopBeforeQuit() async {
        guard let connection = manager?.connection, connection.status != .disconnected, connection.status != .invalid else { return }
        connection.stopVPNTunnel()
        for _ in 0..<30 where connection.status != .disconnected {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func loadManager() async {
        do {
            manager = try await NETransparentProxyManager.loadAllFromPreferences().first
            status = manager?.connection.status ?? .invalid
        } catch {
            message = error.localizedDescription
        }
    }

    private func configureAndStart() async {
        guard let exit = pendingExit else { return }
        do {
            let manager = try await NETransparentProxyManager.loadAllFromPreferences().first ?? NETransparentProxyManager()
            let configuration = NETunnelProviderProtocol()
            configuration.providerBundleIdentifier = Self.extensionBundleIdentifier
            configuration.serverAddress = "\(exit.host):\(exit.port)"
            configuration.providerConfiguration = ["exitHost": exit.host, "exitPort": exit.port]
            manager.protocolConfiguration = configuration
            manager.localizedDescription = "AppRoute"
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            self.manager = manager
            try manager.connection.startVPNTunnel()
            status = manager.connection.status
        } catch {
            message = error.localizedDescription
        }
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        Task { @MainActor in
            message = "Allow AppRoute in System Settings > General > Login Items & Extensions > Network Extensions."
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        Task { @MainActor in
            guard result == .completed else {
                message = "Restart your Mac to finish installing the extension."
                return
            }
            message = nil
            await configureAndStart()
        }
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        let description = error.localizedDescription
        Task { @MainActor in message = description }
    }
}
