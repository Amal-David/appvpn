import SwiftUI

struct WelcomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ScreenHeader(
                    eyebrow: "AppRoute",
                    title: "Use your VPN only where you need it.",
                    subtitle: "Bring an existing VPN subscription, choose which services use it, and leave everything else on the normal connection."
                )

                TrustPanel(
                    title: "The routing layer, not another VPN",
                    bodyText: "Your encrypted traffic goes to the provider you already pay for. It never passes through AppRoute servers.",
                    systemImage: "arrow.triangle.branch"
                )

                VStack(alignment: .leading, spacing: 16) {
                    RouteLegendRow(
                        title: "Selected services",
                        detail: "Traffic matching those service rules uses your VPN.",
                        usesVPN: true
                    )
                    RouteLegendRow(
                        title: "Everything else",
                        detail: "Safari, banking, and unmarked destinations stay direct.",
                        usesVPN: false
                    )
                }
                .padding(18)
                .background(.background.secondary, in: .rect(cornerRadius: 20))

                Text("AppRoute does not claim that only a specific installed app process uses the VPN. V1 routes by destination and DNS rules.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Get started") {
                session.onboardingPath.append(.compatibility)
            }
            .buttonStyle(.glassProminent)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }
}
