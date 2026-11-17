import Foundation
import Network
import NetworkExtension
import os.log

final class TransparentProxyProvider: NETransparentProxyProvider, @unchecked Sendable {
    static let routedSigningIdentifiers: Set<String> = ["com.apple.curl"]

    private let log = Logger(subsystem: "app.harena.AppRoute.Mac.Proxy", category: "proxy")
    private let state = OSAllocatedUnfairLock<State>(initialState: State())

    private struct State {
        var exit: Network.NWEndpoint?
        var relays: [ObjectIdentifier: SOCKS5Relay] = [:]
    }

    override func startProxy(options: [String: Any]? = nil) async throws {
        guard
            let configuration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
            let host = configuration["exitHost"] as? String, host.isEmpty == false,
            let portNumber = configuration["exitPort"] as? Int,
            let port = Network.NWEndpoint.Port(rawValue: UInt16(clamping: portNumber))
        else {
            log.error("Start refused: no exit host and port in the configuration")
            throw NEVPNError(.configurationInvalid)
        }
        state.withLock { $0.exit = .hostPort(host: Network.NWEndpoint.Host(host), port: port) }

        let settings = NETransparentProxyNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.includedNetworkRules = [
            NENetworkRule(remoteNetworkEndpoint: nil, remotePrefix: 0, localNetworkEndpoint: nil, localPrefix: 0, protocol: .TCP, direction: .outbound),
            NENetworkRule(remoteNetworkEndpoint: nil, remotePrefix: 0, localNetworkEndpoint: nil, localPrefix: 0, protocol: .UDP, direction: .outbound)
        ]
        try await setTunnelNetworkSettings(settings)
    }

    override func stopProxy(with reason: NEProviderStopReason) async {
        let relays = state.withLock { state in
            defer { state.relays.removeAll() }
            return Array(state.relays.values)
        }
        relays.forEach { $0.cancel() }
    }

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        let source = flow.metaData.sourceAppSigningIdentifier
        guard Self.routedSigningIdentifiers.contains(source) else { return false }

        // A routed app's flow never returns false: the system would send it from the real address.
        // That includes its UDP, which is refused so QUIC falls back to TCP.
        guard
            let tcp = flow as? NEAppProxyTCPFlow,
            let exit = state.withLock({ $0.exit }),
            case .hostPort(let host, let port) = tcp.remoteFlowEndpoint
        else { return refuse(flow) }

        let destination: SOCKS5Relay.Destination
        if let name = tcp.remoteHostname {
            destination = .name(name)
        } else {
            switch host {
            case .name(let name, _): destination = .name(name)
            case .ipv4(let address): destination = .ipv4(address)
            case .ipv6(let address): destination = .ipv6(address)
            @unknown default: return refuse(flow)
            }
        }

        let key = ObjectIdentifier(tcp)
        let relay = SOCKS5Relay(flow: tcp, exit: exit, destination: destination, port: port.rawValue) { [state, log] error in
            state.withLock { _ = $0.relays.removeValue(forKey: key) }
            if let error { log.debug("Flow from \(source, privacy: .public) ended: \(error.localizedDescription, privacy: .public)") }
        }
        state.withLock { $0.relays[key] = relay }
        log.debug("Routing a flow from \(source, privacy: .public) through the exit")
        relay.start()
        return true
    }

    private func refuse(_ flow: NEAppProxyFlow) -> Bool {
        let refused = NEAppProxyFlowError(.refused)
        flow.closeReadWithError(refused)
        flow.closeWriteWithError(refused)
        return true
    }
}
