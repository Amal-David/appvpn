import SwiftUI

struct AppRuleDetailView: View {
    let rules: RoutingRules
    let bundleID: String

    @Environment(\.dismiss) private var dismiss

    private var index: Int? { rules.rules.firstIndex { $0.bundleID == bundleID } }
    private var app: InstalledApp? { InstalledApps.app(bundleID: bundleID) }

    var body: some View {
        if let index {
            let rule = rules.rules[index]
            Form {
                if let app {
                    // The window's toolbar holds the tab bar, so the navigation title is not shown there.
                    Label {
                        Text(app.name).font(.title3.weight(.semibold))
                    } icon: {
                        Image(nsImage: InstalledApps.icon(for: app))
                            .resizable()
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                    }
                }
                Section("Exits, tried in order") {
                    if rule.exitIDs.isEmpty {
                        Text("No exit: this app uses the normal connection.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(rule.exitIDs.enumerated()), id: \.element) { position, exitID in
                        exitRow(position: position, exitID: exitID, ruleIndex: index)
                    }
                    .onMove { rules.rules[index].exitIDs.move(fromOffsets: $0, toOffset: $1) }

                    let unused = rules.exits.filter { rule.exitIDs.contains($0.id) == false }
                    if unused.isEmpty == false {
                        Menu("Add exit") {
                            ForEach(unused) { exit in
                                Button(exit.name) { rules.rules[index].exitIDs.append(exit.id) }
                            }
                        }
                        .fixedSize()
                    }
                }

                Section("If every exit fails") {
                    Picker("If every exit fails", selection: Binding(
                        get: { rule.failPolicy },
                        set: { rules.rules[index].failPolicy = $0 }
                    )) {
                        Text("Block").tag(TunnelFailurePolicy.keepOffline)
                        Text("Go direct").tag(TunnelFailurePolicy.allowDirect)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text(rule.failPolicy == .keepOffline
                        ? "The app gets no connection rather than use your normal one."
                        : "The app falls back to your normal connection.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Button("Remove app", role: .destructive) {
                    dismiss()
                    rules.rules.removeAll { $0.bundleID == bundleID }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(app?.name ?? bundleID)
        }
    }

    private func exitRow(position: Int, exitID: UUID, ruleIndex: Int) -> some View {
        let count = rules.rules[ruleIndex].exitIDs.count
        let name = rules.exit(exitID)?.name ?? "Removed exit"
        return HStack(spacing: 8) {
            Text(verbatim: "\(position + 1). \(name)")
            Spacer()
            ConnectTimeBadge(time: rules.connectTimes[exitID])
            Button("Move \(name) up", systemImage: "chevron.up") {
                rules.rules[ruleIndex].exitIDs.swapAt(position, position - 1)
            }
            .disabled(position == 0)
            Button("Move \(name) down", systemImage: "chevron.down") {
                rules.rules[ruleIndex].exitIDs.swapAt(position, position + 1)
            }
            .disabled(position == count - 1)
            Button("Remove \(name)", systemImage: "minus.circle") {
                rules.rules[ruleIndex].exitIDs.remove(at: position)
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }
}
