import SwiftUI

struct ServerPickerView: View {
    @Environment(AppSession.self) private var session
    @State private var endpoints: [VPNEndpoint] = []
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var session = session
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Location",
                    title: "Choose a server",
                    subtitle: subtitle
                )

                if session.policy.providerKind == .nordManual {
                    TextField("Or enter a hostname", text: $session.customHostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(.background.secondary, in: .rect(cornerRadius: 14))
                }

                ForEach(endpoints) { endpoint in
                    Button {
                        session.policy.endpoint = endpoint
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(endpoint.displayName)
                                    .font(.headline)
                                Text(endpoint.hostname)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if endpoint.isExample {
                                    Text("Example hostname · editable")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.caution)
                                }
                            }
                            Spacer()
                            if session.policy.endpoint == endpoint {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.vpn)
                            }
                        }
                        .padding(16)
                        .background(.background.secondary, in: .rect(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                Task { await continueWithSelection() }
            }
            .buttonStyle(.glassProminent)
            .disabled(session.policy.endpoint == nil && session.customHostname.isEmpty)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .task {
            await loadEndpoints()
        }
        .navigationTitle("Server")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subtitle: String {
        if session.policy.providerKind == .nordManual {
            return "These Nord hostnames follow the public {country}{number}.nordvpn.com pattern. They are examples you can edit, not a live Nord API."
        }
        return "The endpoint is taken from the file you imported."
    }

    private func loadEndpoints() async {
        guard let kind = session.policy.providerKind else { return }
        do {
            endpoints = try await session.provider(for: kind).listEndpoints()
            if session.policy.endpoint == nil {
                session.policy.endpoint = endpoints.first
            }
        } catch let error as AppRouteError {
            errorMessage = error.userFacingMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func continueWithSelection() async {
        if session.customHostname.trimmingCharacters(in: .whitespaces).isEmpty == false {
            let host = session.customHostname.trimmingCharacters(in: .whitespaces)
            session.policy.endpoint = VPNEndpoint(
                displayName: host,
                country: "Custom",
                city: "User entered",
                hostname: host,
                port: session.policy.providerKind == .wireGuard ? 51820 : 500,
                isExample: false
            )
        }
        guard let kind = session.policy.providerKind, let endpoint = session.policy.endpoint else { return }
        do {
            session.policy.tunnelConfiguration = try await session.provider(for: kind).buildTunnelConfiguration(endpoint: endpoint)
            await session.persistPolicy()
            session.onboardingPath.append(.servicePicker)
        } catch let error as AppRouteError {
            errorMessage = error.userFacingMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
