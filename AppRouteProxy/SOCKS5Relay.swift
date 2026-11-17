import Foundation
import Network
import NetworkExtension

/// Carries one intercepted TCP flow through a SOCKS5 exit (RFC 1928, no authentication).
final class SOCKS5Relay: @unchecked Sendable {
    enum Destination {
        case name(String)
        case ipv4(IPv4Address)
        case ipv6(IPv6Address)
    }

    private let flow: NEAppProxyTCPFlow
    private let connection: NWConnection
    private let destination: Destination
    private let port: UInt16
    private let onFinish: @Sendable (Error?) -> Void
    private let queue = DispatchQueue(label: "app.harena.AppRoute.Mac.Proxy.relay")
    // Mutated only on `queue`.
    private var finished = false

    init(
        flow: NEAppProxyTCPFlow,
        exit: Network.NWEndpoint,
        destination: Destination,
        port: UInt16,
        onFinish: @escaping @Sendable (Error?) -> Void
    ) {
        self.flow = flow
        self.connection = NWConnection(to: exit, using: .tcp)
        self.destination = destination
        self.port = port
        self.onFinish = onFinish
    }

    func start() {
        connection.stateUpdateHandler = { [self] state in
            switch state {
            case .ready:
                connection.stateUpdateHandler = { [self] state in
                    if case .failed(let error) = state { finish(error) }
                }
                sendGreeting()
            case .failed(let error), .waiting(let error):
                // `.waiting` means the exit is unreachable right now; fail the flow instead of hanging the app.
                finish(error)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    func cancel() {
        finish(RelayError.cancelled)
    }

    private func sendGreeting() {
        send(Data([0x05, 0x01, 0x00])) { [self] in
            receive(exactly: 2) { [self] reply in
                guard reply == Data([0x05, 0x00]) else { return finish(RelayError.exitRefusedGreeting) }
                sendConnect()
            }
        }
    }

    private func sendConnect() {
        var request = Data([0x05, 0x01, 0x00])
        switch destination {
        case .name(let name):
            let bytes = Data(name.utf8)
            guard bytes.count <= 255 else { return finish(RelayError.hostnameTooLong) }
            request.append(0x03)
            request.append(UInt8(bytes.count))
            request.append(bytes)
        case .ipv4(let address):
            request.append(0x01)
            request.append(address.rawValue)
        case .ipv6(let address):
            request.append(0x04)
            request.append(address.rawValue)
        }
        request.append(UInt8(port >> 8))
        request.append(UInt8(port & 0xFF))
        send(request) { [self] in
            receive(exactly: 4) { [self] head in
                guard head[0] == 0x05, head[1] == 0x00 else { return finish(RelayError.exitRefusedConnect(head[1])) }
                switch head[3] {
                case 0x01: skipBoundAddress(length: 4 + 2)
                case 0x04: skipBoundAddress(length: 16 + 2)
                case 0x03:
                    receive(exactly: 1) { [self] length in skipBoundAddress(length: Int(length[0]) + 2) }
                default:
                    finish(RelayError.malformedReply)
                }
            }
        }
    }

    private func skipBoundAddress(length: Int) {
        receive(exactly: length) { [self] _ in
            flow.open(withLocalFlowEndpoint: nil) { [self] error in
                queue.async { [self] in
                    if let error { return finish(error) }
                    pumpFlowToExit()
                    pumpExitToFlow()
                }
            }
        }
    }

    // Each direction reads the next chunk only after the previous one was written, which is the back-pressure.
    private func pumpFlowToExit() {
        flow.readData { [self] data, error in
            queue.async { [self] in
                if let error { return finish(error) }
                guard let data, data.isEmpty == false else {
                    connection.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in })
                    return
                }
                send(data) { [self] in pumpFlowToExit() }
            }
        }
    }

    private func pumpExitToFlow() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [self] data, _, isComplete, error in
            if let error { return finish(error) }
            guard let data, data.isEmpty == false else {
                if isComplete { finish(nil) }
                return
            }
            flow.write(data) { [self] error in
                queue.async { [self] in
                    if let error { return finish(error) }
                    if isComplete { return finish(nil) }
                    pumpExitToFlow()
                }
            }
        }
    }

    private func send(_ data: Data, then next: @escaping @Sendable () -> Void) {
        connection.send(content: data, completion: .contentProcessed { [self] error in
            if let error { return finish(error) }
            next()
        })
    }

    private func receive(exactly count: Int, then next: @escaping @Sendable (Data) -> Void) {
        connection.receive(minimumIncompleteLength: count, maximumLength: count) { [self] data, _, _, error in
            guard let data, data.count == count else { return finish(error ?? RelayError.exitClosedEarly) }
            next(data)
        }
    }

    private func finish(_ error: Error?) {
        queue.async { [self] in
            guard finished == false else { return }
            finished = true
            connection.stateUpdateHandler = nil
            connection.cancel()
            flow.closeReadWithError(error)
            flow.closeWriteWithError(error)
            onFinish(error)
        }
    }
}

enum RelayError: Error {
    case exitRefusedGreeting
    case exitRefusedConnect(UInt8)
    case exitClosedEarly
    case malformedReply
    case hostnameTooLong
    case cancelled
}
