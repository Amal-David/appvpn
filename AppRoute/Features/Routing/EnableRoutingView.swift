import SwiftUI

struct EnableRoutingView: View {
    @Environment(AppSession.self) private var session
    @State private var errorMessage: String?
    @State private var isBusy = false

    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "VPN",
                    title: enableTitle,
                    subtitle: "iOS will ask to add a VPN configuration. Allow it. That is not device management and not Exact App Routing."
                )

                TrustPanel(
                    title: "What happens next",
                    bodyText: nordExplanation,
                    systemImage: "lock.square"
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("If the tunnel fails")
                        .font(.headline)
                    Picker("Failure policy", selection: $session.policy.failurePolicy) {
                        ForEach(TunnelFailurePolicy.allCases) { policy in
                            Text(policy.title).tag(policy)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(session.policy.failurePolicy.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(.background.secondary, in: .rect(cornerRadius: 20))

                if let readiness = session.policy.tunnelConfiguration?.protocolReadiness {
                    Text(readiness.userFacingNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                StatusBadge(
                    text: session.connectionStatus.title,
                    tint: session.connectionStatus.isActive ? AppTheme.vpn : AppTheme.direct
                )

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button(isBusy ? "Starting…" : "Enable Routing") {
                Task { await enable() }
            }
            .buttonStyle(.glassProminent)
            .disabled(isBusy)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Enable routing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.tunnelController.refresh()
            session.connectionStatus = session.tunnelController.status
        }
        .onChange(of: session.tunnelController.status) {
            session.connectionStatus = session.tunnelController.status
        }
    }

    private var enableTitle: String {
        switch session.policy.providerKind {
        case .nordManual:
            "Start Nord IKEv2"
        case .wireGuard, .openVPN, .none:
            "Traffic matching these service rules uses VPN"
        }
    }

    private var nordExplanation: String {
        switch session.policy.providerKind {
        case .nordManual:
            "AppRoute starts Apple's IKEv2 client with your Nord service username and a Keychain password reference. Status shows Connected only when iOS reports NEVPNStatus.connected. Nord service credentials come from nordaccount.com manual setup, not your account email."
        case .wireGuard:
            "iOS adds AppRoute's packet tunnel. Destination rules from the service catalogue are applied. A complete WireGuard handshake is not in this build, so this path will not claim a provider session."
        case .openVPN:
            "OpenVPN metadata is stored, but a full OpenVPN stack is not wired. AppRoute will not claim Connected."
        case .none:
            "Choose a provider before enabling routing."
        }
    }

    private func enable() async {
        isBusy = true
        defer { isBusy = false }
        await session.connectVPN()
        session.connectionStatus = session.tunnelController.status
        if let error = session.lastError {
            errorMessage = error.userFacingMessage
            session.policy.isRoutingEnabled = false
            return
        }
        session.record(.routingEnabled)
        session.onboardingPath.append(.routingTest)
    }
}
