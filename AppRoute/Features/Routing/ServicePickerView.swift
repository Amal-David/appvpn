import SwiftUI

struct ServicePickerView: View {
    @Environment(AppSession.self) private var session
    var showsOnboardingContinue = false

    var body: some View {
        List {
            Section {
                Text("This is a curated catalogue of services, not a list of apps installed on this iPhone. AppRoute does not scan or persist installed apps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Services") {
                ForEach(ServiceCatalog.all) { service in
                    Toggle(isOn: binding(for: service.id)) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.name)
                                Text(service.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: service.systemImage)
                        }
                    }
                    .tint(AppTheme.vpn)
                    .accessibilityHint(service.summary)
                }
            }
        }
        .navigationTitle("Services")
        .onChange(of: session.policy.selectedServiceIDs) {
            if showsOnboardingContinue == false {
                Task { await session.persistPolicy() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showsOnboardingContinue {
                Button("Continue") {
                    Task { await saveAndContinue() }
                }
                .buttonStyle(.glassProminent)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { session.policy.selectedServiceIDs.contains(id) },
            set: { isOn in
                if isOn {
                    if session.policy.selectedServiceIDs.contains(id) == false {
                        session.policy.selectedServiceIDs.append(id)
                    }
                } else {
                    session.policy.selectedServiceIDs.removeAll { $0 == id }
                }
            }
        )
    }

    private func saveAndContinue() async {
        session.record(
            .serviceSelectionSaved,
            selectedServiceCount: session.policy.selectedServiceIDs.count
        )
        await session.persistPolicy()
        session.onboardingPath.append(.enableRouting)
    }
}
