import SwiftUI

struct DiagnosticsView: View {
    @Environment(AppSession.self) private var session
    @State private var snapshot = TunnelDiagnosticsSnapshot(
        lastStarted: nil,
        lastError: nil,
        classifiedVPNCount: 0,
        classifiedDirectCount: 0,
        handshakeTODO: "Not loaded",
        ipv6Enabled: true
    )

    var body: some View {
        List {
            Section("Tunnel") {
                LabeledContent("Connection", value: session.connectionStatus.title)
                LabeledContent("IPv6 policy", value: snapshot.ipv6Enabled ? "Included" : "Missing")
                LabeledContent("VPN classifications", value: "\(snapshot.classifiedVPNCount)")
                LabeledContent("Direct classifications", value: "\(snapshot.classifiedDirectCount)")
            }
            Section("Handshake") {
                Text(snapshot.handshakeTODO)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Honest limits") {
                Text("Packet payloads, DNS history, and credentials are never written here. A successful classification count does not mean the provider handshake completed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Diagnostics")
        .task {
            snapshot = await DiagnosticsStore().load()
            await session.tunnelController.refresh()
            session.connectionStatus = session.tunnelController.status
        }
    }
}
