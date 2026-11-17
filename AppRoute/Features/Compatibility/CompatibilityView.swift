import SwiftUI

struct CompatibilityView: View {
    @Environment(AppSession.self) private var session
    @State private var answer: CompatibilityAnswer = .personal
    @State private var isShowingExactRouting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenHeader(
                    eyebrow: "Before we continue",
                    title: "Compatibility",
                    subtitle: "AppRoute cannot fully detect work MDM without Apple management APIs. Please tell us how this iPhone is set up."
                )

                Picker("This iPhone", selection: $answer) {
                    ForEach(CompatibilityAnswer.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if answer == .workOrSchool {
                    TrustPanel(
                        title: "Exact App Routing is unavailable",
                        bodyText: "Apple allows only one enrolment profile on a device. If work or school already manages this iPhone, AppRoute cannot become a second management authority. Smart Routing may still work because it does not enrol the device in MDM.",
                        systemImage: "building.columns"
                    )
                } else if answer == .unsure {
                    TrustPanel(
                        title: "If Settings mentions Device Management",
                        bodyText: "Open Settings → General → VPN & Device Management. If you see a work or school enrolment, Exact App Routing cannot be added. Smart Routing does not require enrolment.",
                        systemImage: "questionmark.circle"
                    )
                } else {
                    TrustPanel(
                        title: "Smart Routing works without MDM",
                        bodyText: "V1 uses a packet tunnel and destination rules. Exact App Routing — Apple Per-App VPN via MDM — is a gated future path, not part of this release.",
                        systemImage: "checkmark.circle"
                    )
                }

                Button("What is Exact App Routing?") {
                    isShowingExactRouting = true
                }
                .buttonStyle(.glass)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {
                session.compatibilityAnswer = answer
                session.record(.compatibilityChecked)
                if answer == .workOrSchool {
                    session.record(.existingMDMReported)
                }
                session.onboardingPath.append(.howRoutingWorks)
            }
            .buttonStyle(.glassProminent)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingExactRouting) {
            NavigationStack {
                ExactAppRoutingView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Close") { isShowingExactRouting = false }
                        }
                    }
            }
        }
    }
}
