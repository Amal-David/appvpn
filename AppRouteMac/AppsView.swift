import SwiftUI

struct AppsView: View {
    let rules: RoutingRules
    @State private var apps: [InstalledApp] = []
    @State private var search = ""

    var body: some View {
        NavigationStack {
            content
                .navigationDestination(for: String.self) { bundleID in
                    AppRuleDetailView(rules: rules, bundleID: bundleID)
                }
        }
        .task { apps = await Task.detached { InstalledApps.all() }.value }
    }

    /// Apps with at least one exit, in rule order. A rule whose app is no longer installed still gets a row so it can be removed.
    private var routed: [InstalledApp] {
        let installed = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleID, $0) })
        return rules.rules
            .filter { $0.exitIDs.isEmpty == false }
            .map { installed[$0.bundleID] ?? InstalledApps.app(bundleID: $0.bundleID) ?? InstalledApp(bundleID: $0.bundleID, name: $0.bundleID, url: URL(filePath: "/")) }
            .filter(matchesSearch)
    }

    private var direct: [InstalledApp] {
        let taken = Set(rules.rules.filter { $0.exitIDs.isEmpty == false }.map(\.bundleID))
        return apps.filter { taken.contains($0.bundleID) == false && matchesSearch($0) }
    }

    private func matchesSearch(_ app: InstalledApp) -> Bool {
        search.isEmpty || app.name.localizedCaseInsensitiveContains(search)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(rules.exits.isEmpty
                ? "Add an exit in the Exits tab, then choose which apps use it."
                : "Rules are saved. They are not enforced until the extension is installed.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            TextField("Search apps", text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            List {
                if routed.isEmpty == false {
                    Section("Through an exit") {
                        ForEach(routed) { app in
                            AppRow(rules: rules, app: app)
                        }
                    }
                }
                Section("Normal connection") {
                    ForEach(direct) { app in
                        AppRow(rules: rules, app: app)
                    }
                }
            }
        }
    }
}

private struct AppRow: View {
    let rules: RoutingRules
    let app: InstalledApp
    @State private var isConfirmingRemoval = false

    private var rule: AppRule? { rules.rules.first { $0.bundleID == app.bundleID } }
    private var firstExit: Exit? { rule?.exitIDs.first.flatMap(rules.exit) }

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: InstalledApps.icon(for: app))
                .resizable()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).fontWeight(.medium)
                if let rule, rule.exitIDs.count > 1 {
                    Text("then \(rule.exitIDs.count - 1) more")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let firstExit {
                ConnectTimeBadge(time: rules.connectTimes[firstExit.id])
            }
            if rules.exits.isEmpty == false || rule != nil {
                Picker("Exit for \(app.name)", selection: Binding(
                    get: { firstExit?.id },
                    set: { exitID in
                        // Going back to the normal connection deletes the rule, so ask first when it holds more than one choice.
                        if exitID == nil, let rule, rule.exitIDs.count > 1 || rule.failPolicy != .keepOffline {
                            isConfirmingRemoval = true
                        } else {
                            rules.setPrimaryExit(exitID, for: app.bundleID)
                        }
                    }
                )) {
                    Text("Normal connection").tag(UUID?.none)
                    ForEach(rules.exits) { exit in
                        Text(exit.name).tag(UUID?.some(exit.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            NavigationLink(value: app.bundleID) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Fallback exits for \(app.name)")
            .opacity(rule == nil ? 0 : 1)
            .disabled(rule == nil)
            .accessibilityHidden(rule == nil)
        }
        .padding(.vertical, 2)
        .confirmationDialog("Put \(app.name) back on the normal connection?", isPresented: $isConfirmingRemoval) {
            Button("Remove its exits", role: .destructive) { rules.setPrimaryExit(nil, for: app.bundleID) }
        } message: {
            Text("Its fallback exits and fail choice will be removed.")
        }
    }
}

struct ConnectTimeBadge: View {
    let time: ConnectTime?

    var body: some View {
        switch time {
        case .reachable(let duration):
            badge(Self.text(for: duration), color: AppTheme.vpn)
        case .unreachable:
            badge("Unreachable", color: AppTheme.caution)
        case nil:
            badge("Checking", color: AppTheme.direct)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .accessibilityLabel("Connect time: \(text)")
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: .capsule)
    }

    private static func text(for duration: Duration) -> String {
        let milliseconds = duration / .milliseconds(1)
        return milliseconds < 1 ? "<1 ms" : "\(Int(milliseconds.rounded())) ms"
    }
}
