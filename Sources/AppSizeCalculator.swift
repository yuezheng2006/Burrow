//
//  AppSizeCalculator.swift
//  Fuchen
//
//  Bundle size via `du -sk`. URLResourceValues.totalFileAllocatedSize is nil
//  for .app directories on macOS, so du is the reliable path (same as mole).
//

import Foundation

enum AppSizeCalculator {
    private static let perAppTimeout: TimeInterval = 2  // 进一步减少超时到 2 秒

    static func allocatedBytes(at path: String, timeout: TimeInterval = perAppTimeout) -> Int64 {
        var bytes: Int64 = 0
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer { group.leave() }
            bytes = duBytes(at: path)
        }
        guard group.wait(timeout: .now() + timeout) == .success else { return 0 }
        return bytes
    }

    /// Runs `/usr/bin/du -sk <path>` and returns allocated bytes (1024-based KB).
    private static func duBytes(at path: String) -> Int64 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        process.arguments = ["-sk", path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return 0 }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let line = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !line.isEmpty else { return 0 }
            let kbToken = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: true).first
            guard let kbToken, let kb = Int64(kbToken), kb > 0 else { return 0 }
            return kb * 1024
        } catch {
            return 0
        }
    }

    static func sizedApp(_ app: InstalledApp) -> InstalledApp {
        let bytes = allocatedBytes(at: app.path)
        guard bytes > 0 else { return app }
        return InstalledApp(
            id: app.id,
            name: app.name,
            bundleId: app.bundleId,
            source: app.source,
            uninstallName: app.uninstallName,
            path: app.path,
            sizeStr: Fmt.bytes(bytes),
            sizeBytes: bytes,
            lastUsed: app.lastUsed)
    }

    /// Size many apps with bounded parallelism; `onSized` is called on the
    /// caller's queue once per app (may be out of order).
    static func sizeApps(
        _ apps: [InstalledApp],
        maxConcurrent: Int = 12,  // 进一步增加并发到 12
        onSized: @escaping (InstalledApp) -> Void
    ) {
        let lock = NSLock()
        var index = 0
        let workers = max(1, min(maxConcurrent, apps.count))
        DispatchQueue.concurrentPerform(iterations: workers) { _ in
            while true {
                let i: Int
                lock.lock()
                if index >= apps.count {
                    lock.unlock()
                    break
                }
                i = index
                index += 1
                lock.unlock()
                onSized(sizedApp(apps[i]))
            }
        }
    }
}
