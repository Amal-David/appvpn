import SwiftUI

struct HowRoutingWorksView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(
                    eyebrow: "Architecture B",
                    title: "Traffic matching these service rules uses VPN",
                    subtitle: "AppRoute never claims that only the TikTok process uses the VPN. It routes by domain, DNS mapping, and IP ranges — including IPv6."
                )

                VStack(alignment: .leading, spacing: 18) {
                    RouteLegendRow(
                        title: "TikTok domains",
                        detail: "tiktok.com, tiktokcdn.com, and related hosts",
                        usesVPN: true
                    )
                    RouteLegendRow(
                        title: "Safari and unmarked apps",
                        detail: "Stay on Wi-Fi or cellular unless they call a selected service",
                        usesVPN: false
                    )
                }
                .padding(18)
                .background(.background.secondary, in: .rect(cornerRadius: 20))

                TrustPanel(
                    title: "Edge cases stay visible",
                    bodyText: "If a service uses a new CDN AppRoute does not know yet, that traffic may go direct. If another app contacts a listed destination, it may use VPN. Shared CDNs and encrypted DNS inside an app are real limits of destination routing.",
                    systemImage: "info.circle"
                )
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                session.onboardingPath.append(.privacy)
            }
            .buttonStyle(.glassProminent)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("How routing works")
        .navigationBarTitleDisplayMode(.inline)
    }
}
