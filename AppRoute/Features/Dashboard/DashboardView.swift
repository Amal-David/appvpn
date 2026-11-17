import SwiftUI

struct DashboardView: View {
    @Environment(AppSession.self) private var session
    @State private var path: [AppDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    networkCard
                    servicesCard
                    directCard
                    actions
                    connectControl
                    if let message = session.tunnelController.lastMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(session.tunnelController.lastError == nil ? Color.secondary : Color.red)
                    }
                    TrustPanel(
                        title: "Privacy",
                        bodyText: "Your VPN traffic never passes through our servers. AppRoute is a routing layer for the VPN you already have.",
                        systemImage: "hand.raised"
                    )
                    if session.subscriptionStore.isPro == false {
                        Button("AppRoute Pro") {
                            path.append(.paywall)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Your network")
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .exactAppRouting:
                    ExactAppRoutingView()
                case .providerSettings:
                    ProviderSettingsView()
                case .diagnostics:
                    DiagnosticsView()
                case .privacyControls:
                    PrivacyControlsView()
                case .paywall:
                    PaywallView()
                case .servicePicker:
                    ServicePickerView()
                case .routingTest:
                    RoutingTestView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StatusBadge(
                        text: session.connectionStatus.title,
                        tint: session.connectionStatus.isActive ? AppTheme.vpn : AppTheme.direct
                    )
                }
            }
            .task {
                await session.tunnelController.refresh()
                session.connectionStatus = session.tunnelController.status
            }
            .onChange(of: session.tunnelController.status) {
                session.connectionStatus = session.tunnelController.status
            }
        }
    }

    private var connectControl: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: 12) {
                Button(session.connectionStatus.isActive ? "Disconnect" : "Connect") {
                    Task { await toggleConnection() }
                }
                .buttonStyle(.glassProminent)
                .disabled(session.policy.providerKind == nil)
                Text("Status comes from iOS VPN, not a placeholder. Connected appears only after the system reports it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func toggleConnection() async {
        if session.connectionStatus.isActive {
            await session.tunnelController.stop()
            session.connectionStatus = session.tunnelController.status
            return
        }
        await session.connectVPN()
    }

    private var header: some View {
        Text("Traffic matching selected service rules uses VPN. Everything else stays direct.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var networkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.policy.providerKind?.displayName ?? "No provider")
                    .font(.headline)
                Spacer()
                Image(systemName: session.connectionStatus.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(session.connectionStatus.isActive ? AppTheme.vpn : .secondary)
                    .accessibilityLabel(session.connectionStatus.title)
            }
            HStack {
                Text(session.policy.endpoint?.country ?? "Location")
                Spacer()
                Text(session.policy.endpoint?.city ?? "Not set")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(18)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
    }

    private var servicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services using VPN")
                .font(.headline)
            if session.policy.selectedServices.isEmpty {
                Text("None selected yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(session.policy.selectedServices) { service in
                    Label(service.name, systemImage: service.systemImage)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
    }

    private var directCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direct")
                .font(.headline)
            Text("Everything else")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
    }

    private var actions: some View {
        LiquidGlassContainer {
            HStack(spacing: 12) {
                Button("Add a service") {
                    path.append(.servicePicker)
                }
                .buttonStyle(.glassProminent)
                Button("Test routing") {
                    path.append(.routingTest)
                }
                .buttonStyle(.glass)
            }
        }
    }
}
