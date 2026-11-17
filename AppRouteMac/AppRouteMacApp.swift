import NetworkExtension
import SwiftUI

@main
struct AppRouteMacApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        Window("AppRoute", id: "main") {
            RoutingView(controller: delegate.controller)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = ProxyController()

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await controller.stopBeforeQuit()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

private struct RoutingView: View {
    let controller: ProxyController
    @AppStorage("exitHost") private var exitHost = "127.0.0.1"
    @AppStorage("exitPort") private var exitPort = 1080

    private var isOn: Bool {
        switch controller.status {
        case .connected, .connecting, .reasserting: true
        default: false
        }
    }

    var body: some View {
        Form {
            Section("SOCKS5 exit") {
                TextField("Host", text: $exitHost)
                TextField("Port", value: $exitPort, format: .number.grouping(.never))
            }
            .disabled(isOn)

            Section {
                Toggle("Route curl through the exit", isOn: Binding(
                    get: { isOn },
                    set: { $0 ? controller.turnOn(exitHost: exitHost, exitPort: exitPort) : controller.turnOff() }
                ))
                LabeledContent("Status", value: statusText)
                if let message = controller.message {
                    Text(message).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }

    private var statusText: String {
        switch controller.status {
        case .connected: "On"
        case .connecting, .reasserting: "Starting"
        case .disconnecting: "Stopping"
        default: "Off"
        }
    }
}
