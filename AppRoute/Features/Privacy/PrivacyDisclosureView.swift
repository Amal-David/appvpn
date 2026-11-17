import SwiftUI

struct PrivacyDisclosureView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Trust",
                    title: "What AppRoute stores — and what it never sees",
                    subtitle: "Read this before adding credentials. VPN apps have to be explicit."
                )

                disclosure(
                    title: "On this iPhone",
                    items: [
                        "VPN service usernames, passwords, and WireGuard private keys in Keychain",
                        "The services you select, and the server hostname you choose",
                        "Local funnel events such as selected_service_count — never service names"
                    ]
                )

                disclosure(
                    title: "Never stored by AppRoute",
                    items: [
                        "Browsing history or DNS query logs",
                        "Packet payloads",
                        "A full list of installed apps",
                        "Your VPN data plane — traffic goes to your provider, not to us"
                    ]
                )

                TrustPanel(
                    title: "No AppRoute exit nodes",
                    bodyText: "AppRoute is a routing layer. It does not operate VPN servers. Compatible with NordVPN manual configurations — not an official NordVPN integration.",
                    systemImage: "server.rack"
                )
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("I understand") {
                session.record(.privacyDisclosureViewed)
                session.onboardingPath.append(.providerPicker)
            }
            .buttonStyle(.glassProminent)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func disclosure(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
    }
}
