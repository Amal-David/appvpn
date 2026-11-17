import SwiftUI

struct ProviderSettingsView: View {
    @Environment(AppSession.self) private var session
    @State private var message: String?
    @State private var isBusy = false

    var body: some View {
        @Bindable var session = session
        Form {
            Section("Current") {
                LabeledContent("Provider", value: session.policy.providerKind?.displayName ?? "None")
                LabeledContent("Host", value: session.policy.endpoint?.hostname ?? "None")
                LabeledContent("Status", value: session.connectionStatus.title)
            }

            Section("VPN") {
                Button(connectTitle) {
                    Task { await toggleTunnel() }
                }
                .disabled(isBusy || session.connectionStatus == .connecting)
                Picker("On tunnel failure", selection: $session.policy.failurePolicy) {
                    ForEach(TunnelFailurePolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                .onChange(of: session.policy.failurePolicy) {
                    Task { await session.persistPolicy() }
                }
                Text("Nord uses Apple IKEv2 (Personal VPN) for the whole device. WireGuard uses the packet tunnel for destination rules. OpenVPN cannot connect in this build.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let message {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }

            if let readiness = session.policy.tunnelConfiguration?.protocolReadiness {
                Section("Protocol") {
                    Text(readiness.userFacingNote)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Provider")
        .onChange(of: session.tunnelController.status) {
            session.connectionStatus = session.tunnelController.status
        }
    }

    private var connectTitle: String {
        switch session.connectionStatus {
        case .connected:
            "Disconnect"
        case .connecting, .reasserting:
            "Connecting…"
        case .disconnecting:
            "Disconnecting…"
        case .invalid, .disconnected, .unknown:
            "Connect"
        }
    }

    private func toggleTunnel() async {
        isBusy = true
        defer { isBusy = false }
        if session.connectionStatus.isActive {
            await session.tunnelController.stop()
        } else {
            await session.connectVPN()
            if let error = session.lastError {
                message = error.userFacingMessage
                session.connectionStatus = session.tunnelController.status
                return
            }
        }
        session.connectionStatus = session.tunnelController.status
        message = session.tunnelController.lastMessage
    }
}
