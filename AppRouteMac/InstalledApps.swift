import AppKit

struct InstalledApp: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let url: URL

    var id: String { bundleID }
}

enum InstalledApps {
    static func all() -> [InstalledApp] {
        let folders = [
            URL(filePath: "/Applications"),
            URL(filePath: "/Applications/Utilities"),
            URL(filePath: "/System/Applications"),
            URL(filePath: "/System/Applications/Utilities"),
            URL.homeDirectory.appending(path: "Applications")
        ]
        var seen = Set<String>()
        return folders
            .flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? [] }
            .filter { $0.pathExtension == "app" }
            .compactMap { url in
                guard let bundleID = Bundle(url: url)?.bundleIdentifier, seen.insert(bundleID).inserted else { return nil }
                return InstalledApp(bundleID: bundleID, name: name(of: url), url: url)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Resolves a rule's bundle ID back to an app, which may have moved or been removed since the rule was made.
    static func app(bundleID: String) -> InstalledApp? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID).map {
            InstalledApp(bundleID: bundleID, name: name(of: $0), url: $0)
        }
    }

    static func icon(for app: InstalledApp) -> NSImage {
        NSWorkspace.shared.icon(forFile: app.url.path(percentEncoded: false))
    }

    private static func name(of url: URL) -> String {
        FileManager.default.displayName(atPath: url.path(percentEncoded: false)).replacing(/\.app$/, with: "")
    }
}
