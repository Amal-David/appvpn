import AppKit

struct InstalledApp: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let url: URL

    var id: String { bundleID }
}

enum InstalledApps {
    /// Every app in the standard folders, looking one folder deep so vendor folders and Utilities are included.
    static func all() -> [InstalledApp] {
        let folders = [
            URL(filePath: "/Applications"),
            URL(filePath: "/System/Applications"),
            // Safari lives here, not in /Applications, on current macOS.
            URL(filePath: "/System/Cryptexes/App/System/Applications"),
            URL.homeDirectory.appending(path: "Applications")
        ]
        var seen = Set<String>()
        return folders
            .flatMap(contents)
            .flatMap { $0.pathExtension == "app" ? [$0] : contents(of: $0) }
            .filter { $0.pathExtension == "app" }
            .compactMap { url in
                guard let bundleID = Bundle(url: url)?.bundleIdentifier, seen.insert(bundleID).inserted else { return nil }
                return InstalledApp(bundleID: bundleID, name: name(of: url), url: url)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func contents(of folder: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
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
