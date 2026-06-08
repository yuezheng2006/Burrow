//
//  AppListCache.swift
//  Fuchen
//
//  Persists the last app list + sizes so the Software tab can restore
//  instantly on the next visit.
//

import Foundation

enum AppListCache {
    private static let fileName = "app-list-cache.json"

    struct Entry: Codable {
        let fetchedAt: Date
        let apps: [[String: String]]
    }

    static func load() -> Entry? {
        guard let url = cacheURL(),
              let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(Entry.self, from: data) else { return nil }
        return entry
    }

    static func loadApps() -> [InstalledApp] {
        guard let entry = load(), !entry.apps.isEmpty else { return [] }
        return AppListParser.parseMoleRows(entry.apps.map {
            Dictionary(uniqueKeysWithValues: $0.map { ($0.key, $0.value as Any) })
        })
    }

    static func save(apps: [InstalledApp]) {
        let rows: [[String: String]] = apps.map { app in
            [
                "name": app.name,
                "bundle_id": app.bundleId,
                "source": app.source,
                "uninstall_name": app.uninstallName,
                "path": app.path,
                "size": app.sizeStr,
            ]
        }
        let entry = Entry(fetchedAt: Date(), apps: rows)
        guard let url = cacheURL(),
              let data = try? JSONEncoder().encode(entry) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    static func save(apps: [[String: Any]]) {
        let parsed = AppListParser.parseMoleRows(apps)
        save(apps: parsed)
    }

    private static func cacheURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Fuchen", isDirectory: true)
            .appendingPathComponent(fileName)
    }
}
