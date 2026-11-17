import SwiftUI

struct ExitsView: View {
    let rules: RoutingRules
    @State private var editing: Exit?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                ForEach(rules.exits) { exit in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exit.name).fontWeight(.medium)
                            Text(verbatim: "SOCKS5 · \(exit.host):\(exit.port)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ConnectTimeBadge(time: rules.connectTimes[exit.id])
                        Button("Edit") { editing = exit }
                            .accessibilityLabel("Edit \(exit.name)")
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("Remove", role: .destructive) { rules.removeExit(exit.id) }
                    }
                }
                .onDelete { offsets in
                    offsets.map { rules.exits[$0].id }.forEach(rules.removeExit)
                }
            }
            .overlay {
                if rules.exits.isEmpty {
                    ContentUnavailableView("No exits yet", systemImage: "arrow.triangle.branch", description: Text("An exit is a proxy that chosen apps send their traffic through."))
                }
            }

            Divider()
            Button("Add exit", systemImage: "plus") { editing = Exit(name: "", host: "", port: 1080) }
                .padding(12)
        }
        .sheet(item: $editing) { exit in
            ExitEditor(exit: exit) { saved in
                if let index = rules.exits.firstIndex(where: { $0.id == saved.id }) {
                    rules.exits[index] = saved
                } else {
                    rules.exits.append(saved)
                }
            }
        }
    }
}

private struct ExitEditor: View {
    @State var exit: Exit
    let onSave: (Exit) -> Void
    @Environment(\.dismiss) private var dismiss

    private var isValid: Bool {
        exit.name.isEmpty == false && exit.host.isEmpty == false && (1...65_535).contains(exit.port)
    }

    var body: some View {
        Form {
            TextField("Name", text: $exit.name)
            TextField("Host", text: $exit.host)
            TextField("Port", value: $exit.port, format: .number.grouping(.never))
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(exit)
                    dismiss()
                }
                .disabled(isValid == false)
            }
        }
    }
}
