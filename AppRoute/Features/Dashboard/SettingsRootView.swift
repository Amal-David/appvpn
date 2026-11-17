import SwiftUI

struct SettingsRootView: View {
    var body: some View {
        List {
            Section("Provider") {
                NavigationLink("Provider settings", value: AppDestination.providerSettings)
                NavigationLink("Diagnostics", value: AppDestination.diagnostics)
            }
            Section("Account") {
                NavigationLink("AppRoute Pro", value: AppDestination.paywall)
                NavigationLink("Privacy and delete", value: AppDestination.privacyControls)
            }
            Section("Architecture") {
                NavigationLink("Exact App Routing (future)", value: AppDestination.exactAppRouting)
            }
            Section {
                Text("Compatible with NordVPN manual configurations. Not an official NordVPN product. NordLynx is out of scope.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
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
    }
}
