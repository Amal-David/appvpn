import SwiftUI

struct ExactAppRoutingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Future path · gated",
                    title: "Exact App Routing is not available",
                    subtitle: "True “only this installed app uses VPN” routing on iOS requires Apple MDM, managed apps, and Per-App VPN. AppRoute V1 does not implement that control plane."
                )

                TrustPanel(
                    title: "Why this is blocked",
                    bodyText: "Profile-based Device Enrolment can take over an already installed app and assign it a VPN UUID. Apple permits only one enrolment profile. Removing that profile can also remove managed apps. AppRoute will not fake an installed-app inventory or pretend to enrol this iPhone.",
                    systemImage: "lock.trianglebadge.exclamationmark"
                )

                TrustPanel(
                    title: "What V1 actually does",
                    bodyText: "Smart Routing classifies destinations and DNS names against a curated service catalogue. Traffic matching those rules uses your VPN configuration. Other apps that happen to contact the same destinations may also match.",
                    systemImage: "arrow.triangle.branch"
                )

                Text("There is no MDM server, no APNs command queue, and no device-wipe capability in this app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .navigationTitle("Exact App Routing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
