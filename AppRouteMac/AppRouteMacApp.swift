import NetworkExtension
import SwiftUI

@main
struct AppRouteMacApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var rules = RoutingRules()

    var body: some Scene {
        Window("AppRoute", id: "main") {
            TabView {
                Tab("Apps", systemImage: "square.grid.2x2") { AppsView(rules: rules) }
                Tab("Exits", systemImage: "arrow.triangle.branch") { ExitsView(rules: rules) }
                Tab("Proof", systemImage: "hammer") { RoutingView(controller: delegate.controller) }
            }
            .frame(width: 520, height: 440)
            .task {
                while Task.isCancelled == false {
                    await rules.measureConnectTimes()
                    try? await Task.sleep(for: .seconds(30))
                }
            }
            .onChange(of: rules.exits) {
                Task { await rules.measureConnectTimes() }
            }
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
