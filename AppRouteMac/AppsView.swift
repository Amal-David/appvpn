import SwiftUI

struct AppsView: View {
    let rules: RoutingRules
    @State private var isAddingApp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Rules are saved. They are not enforced until the extension is installed.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            List {
                ForEach(rules.rules) { rule in
                    AppRuleRow(rules: rules, rule: rule)
                }
                .onDelete { rules.rules.remove(atOffsets: $0) }
            }
            .overlay {
                if rules.rules.isEmpty {
                    ContentUnavailableView("No apps yet", systemImage: "app.dashed", description: Text("Add an app to choose which exit it uses."))
                }
            }

            Divider()
            Button("Add app", systemImage: "plus") { isAddingApp = true }
                .padding(12)
        }
        .sheet(isPresented: $isAddingApp) {
            AddAppSheet(rules: rules)
        }
    }
}

private struct AppRuleRow: View {
    let rules: RoutingRules
    let rule: AppRule

    private var app: InstalledApp? { InstalledApps.app(bundleID: rule.bundleID) }
    private var firstExit: Exit? { rule.exitIDs.first.flatMap(rules.exit) }

    var body: some View {
        HStack(spacing: 12) {
            if let app {
                Image(nsImage: InstalledApps.icon(for: app))
                    .resizable()
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app?.name ?? rule.bundleID).fontWeight(.medium)
                Text(firstExit?.name ?? "No exit: normal connection")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let firstExit {
                ConnectTimeBadge(time: rules.connectTimes[firstExit.id])
            }
            Picker("Exit", selection: exitSelection) {
                Text("None").tag(UUID?.none)
                ForEach(rules.exits) { exit in
                    Text(exit.name).tag(UUID?.some(exit.id))
                }
            }
            .labelsHidden()
            .fixedSize()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Remove", role: .destructive) { rules.rules.removeAll { $0.id == rule.id } }
        }
    }

    private var exitSelection: Binding<UUID?> {
        Binding(
            get: { rule.exitIDs.first },
            set: { newValue in
                guard let index = rules.rules.firstIndex(where: { $0.id == rule.id }) else { return }
                rules.rules[index].exitIDs = newValue.map { [$0] } ?? []
            }
        )
    }
}

private struct AddAppSheet: View {
    let rules: RoutingRules
    @Environment(\.dismiss) private var dismiss
    @State private var apps: [InstalledApp] = []
    @State private var search = ""

    private var matches: [InstalledApp] {
        let taken = Set(rules.rules.map(\.bundleID))
        return apps.filter { taken.contains($0.bundleID) == false && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps", text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(12)
            List(matches) { app in
                Button {
                    rules.rules.append(AppRule(bundleID: app.bundleID, exitIDs: rules.exits.first.map { [$0.id] } ?? []))
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(nsImage: InstalledApps.icon(for: app))
                            .resizable()
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        Text(app.name)
                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            Divider()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 360, height: 420)
        .task { apps = InstalledApps.all() }
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
