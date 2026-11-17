import SwiftUI

struct ProviderPickerView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Bring your own VPN",
                    title: "Choose a compatible configuration",
                    subtitle: "AppRoute talks to your provider with a manual configuration. It does not take over an installed VPN app."
                )

                ForEach(ProviderKind.allCases) { kind in
                    Button {
                        session.policy.providerKind = kind
                        session.record(.providerSelected)
                        session.onboardingPath.append(.credentialImport)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(kind.displayName, systemImage: kind.systemImage)
                                .font(.headline)
                            Text(kind.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background.secondary, in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(kind.summary)
                }
            }
            .padding(24)
        }
        .navigationTitle("Provider")
        .navigationBarTitleDisplayMode(.inline)
    }
}
