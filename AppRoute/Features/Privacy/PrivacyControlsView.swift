import SwiftUI

struct PrivacyControlsView: View {
    @Environment(AppSession.self) private var session
    @State private var isConfirming = false

    var body: some View {
        List {
            Section("Stored on this iPhone") {
                LabeledContent("Selected services", value: "\(session.policy.selectedServiceIDs.count)")
                LabeledContent("Provider", value: session.policy.providerKind?.displayName ?? "None")
                Text("Credentials live in Keychain. Funnel events store counts, not service names. AppRoute does not keep an installed-app inventory.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Delete") {
                Button("Delete credentials, policy, and local events", role: .destructive) {
                    isConfirming = true
                }
            }
        }
        .navigationTitle("Privacy")
        .confirmationDialog(
            "Delete local AppRoute data?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Delete everything stored by AppRoute", role: .destructive) {
                Task { await session.resetLocalData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes Keychain secrets, routing policy, and local funnel events. It cannot uninstall a VPN configuration from Settings for you.")
        }
    }
}
