//
//  AppScanner.swift
//  Fuchen
//
//  Fast installed-app discovery without `mo uninstall --list` or
//  `Bundle(path:)` — both can block for minutes on large / broken bundles.
//

import Foundation

enum AppScanner {
    static let applicationDirectories = [
        "/Applications",
        NSHomeDirectory() + "/Applications",
        "/System/Applications",
    ]

    static func scan(directories: [String]? = nil) -> [InstalledApp] {
        let dirs = directories ?? applicationDirectories
        var seen = Set<String>()
        var out: [InstalledApp] = []
        for dir in dirs {
            guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for name in names where name.hasSuffix(".app") {
                let path = (dir as NSString).appendingPathComponent(name)
                guard seen.insert(path).inserted else { continue }
                if let info = readInfoPlist(at: path) {
                    out.append(makeApp(path: path, name: info.name, bundleId: info.bundleId,
                                       source: sourceLabel(dir)))
                } else {
                    let stem = (name as NSString).deletingPathExtension
                    out.append(makeApp(path: path, name: stem, bundleId: "",
                                       source: sourceLabel(dir)))
                }
            }
        }
        return out.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    static func readInfoPlist(at appPath: String) -> (name: String, bundleId: String)? {
        let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")
        guard FileManager.default.isReadableFile(atPath: plistPath),
              let data = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        let bundleId = plist["CFBundleIdentifier"] as? String ?? ""
        let fallback = ((appPath as NSString).lastPathComponent as NSString).deletingPathExtension
        let name = plist["CFBundleDisplayName"] as? String
            ?? plist["CFBundleName"] as? String
            ?? fallback
        return (name, bundleId)
    }

    private static func sourceLabel(_ dir: String) -> String {
        dir.contains("/System/") ? "System" : "App"
    }

    private static func makeApp(path: String, name: String, bundleId: String, source: String) -> InstalledApp {
        let stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        return InstalledApp(
            id: bundleId.isEmpty ? path : bundleId + "|" + path,
            name: name,
            bundleId: bundleId,
            source: source,
            uninstallName: stem.lowercased(),
            path: path,
            sizeStr: "—",
            sizeBytes: 0,
            lastUsed: nil)
    }
}

enum AppListParser {
    static func parseMoleRows(_ arr: [[String: Any]]) -> [InstalledApp] {
        arr.compactMap { d in
            guard let name = d["name"] as? String,
                  let path = d["path"] as? String else { return nil }
            let sizeStr = d["size"] as? String ?? "—"
            return InstalledApp(
                id: (d["bundle_id"] as? String).map { $0 + "|" + path } ?? path,
                name: name,
                bundleId: d["bundle_id"] as? String ?? "",
                source: d["source"] as? String ?? "App",
                uninstallName: d["uninstall_name"] as? String ?? name,
                path: path,
                sizeStr: sizeStr,
                sizeBytes: parseSize(sizeStr),
                lastUsed: nil)
        }
    }

    static func merge(existing: [InstalledApp], fresh: [InstalledApp]) -> [InstalledApp] {
        let byPath = Dictionary(uniqueKeysWithValues: fresh.map { ($0.path, $0) })
        if existing.isEmpty { return fresh }
        var out: [InstalledApp] = []
        var used = Set<String>()
        for app in existing {
            if let updated = byPath[app.path] {
                out.append(updated)
                used.insert(app.path)
            } else {
                out.append(app)
            }
        }
        for app in fresh where !used.contains(app.path) {
            out.append(app)
        }
        return out
    }

    static func parseSize(_ s: String) -> Int64 {
        let t = s.trimmingCharacters(in: .whitespaces).uppercased()
        if t == "--" || t == "—" || t.isEmpty { return 0 }
        let units: [(String, Double)] = [("TB", 1_099_511_627_776), ("GB", 1_073_741_824),
                                         ("MB", 1_048_576), ("KB", 1024), ("B", 1)]
        for (u, mult) in units where t.hasSuffix(u) {
            let num = Double(t.dropLast(u.count).trimmingCharacters(in: .whitespaces)) ?? 0
            return Int64(num * mult)
        }
        return Int64(Double(t) ?? 0)
    }
}
