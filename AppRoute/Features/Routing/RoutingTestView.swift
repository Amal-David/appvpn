import SwiftUI

struct RoutingTestView: View {
    @Environment(AppSession.self) private var session
    var isOnboarding = false
    @Environment(\.openURL) private var openURL
    @State private var note: String?

    private let vpnCheck = URL(string: "https://ifconfig.co/ip")!
    private let safariHint = "Open Safari separately and compare. Direct traffic should show your ISP address; a selected service path should show the VPN exit once the handshake is complete."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Guided test",
                    title: "Compare a selected service with Safari",
                    subtitle: "This checks the idea of two paths — not a guarantee that a specific app binary is bound to the tunnel."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected services")
                        .font(.headline)
                    if session.policy.selectedServices.isEmpty {
                        Text("Add at least one service first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.policy.selectedServices) { service in
                            Label(service.name, systemImage: service.systemImage)
                        }
                    }
                }
                .padding(18)
                .background(.background.secondary, in: .rect(cornerRadius: 20))

                TrustPanel(
                    title: "How to read the result",
                    bodyText: safariHint,
                    systemImage: "safari"
                )

                LiquidGlassContainer {
                    Button("Open IP check") {
                        session.record(.routeTestStarted)
                        openURL(vpnCheck)
                        note = "If Network Extension entitlements are missing, the tunnel will not install and both paths stay direct."
                    }
                    .buttonStyle(.glassProminent)

                    Button("Mark test as understood") {
                        session.record(.routeTestPassed, selectedServiceCount: session.policy.selectedServiceIDs.count)
                        note = "Saved. You can re-run this from the dashboard at any time."
                    }
                    .buttonStyle(.glass)
                }

                if let note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            if isOnboarding {
                Button("Go to dashboard") {
                    Task { await session.completeOnboarding() }
                }
                .buttonStyle(.glassProminent)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Routing test")
        .navigationBarTitleDisplayMode(.inline)
    }
}
