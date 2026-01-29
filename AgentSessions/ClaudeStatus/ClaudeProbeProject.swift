import Foundation

/// Cleanup for the quarantined Claude probe config directory.
///
/// Probes are launched with CLAUDE_CONFIG_DIR pointed at a dedicated directory
/// under Application Support, so all probe session data is isolated there.
/// Cleanup simply removes the contents of that directory — no scanning of
/// ~/.claude/projects/ is needed.
enum ClaudeProbeProject {
    static let didRunCleanupNotification = Notification.Name("ClaudeProbeCleanupDidRun")
    private enum Keys {
        static let cleanupMode = "ClaudeProbeCleanupMode"      // "none" | "auto"
    }

    enum CleanupMode: String { case none, auto }

    enum ResultStatus {
        case success
        case disabled(String)
        case notFound(String)
        case unsafe(String)
        case ioError(String)
    }

    // MARK: - Public API

    static func cleanupMode() -> CleanupMode {
        let raw = UserDefaults.standard.string(forKey: Keys.cleanupMode) ?? CleanupMode.none.rawValue
        return CleanupMode(rawValue: raw) ?? .none
    }

    static func setCleanupMode(_ mode: CleanupMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: Keys.cleanupMode)
    }

    /// Convenience: run cleanup only when mode is .auto (used after each probe).
    @discardableResult
    static func cleanupNowIfAuto() -> ResultStatus {
        guard cleanupMode() == .auto else {
            return .disabled("Cleanup mode is not auto")
        }
        return performCleanup(mode: "auto")
    }

    /// Manual cleanup independent of mode; posts with mode "manual".
    static func cleanupNowUserInitiated() -> ResultStatus {
        return performCleanup(mode: "manual")
    }

    /// No-op. Marker files are no longer written; probe sessions live in a
    /// quarantined CLAUDE_CONFIG_DIR and are identified by path prefix.
    static func noteProbeRun() {}

    // MARK: - Cleanup

    private static func performCleanup(mode: String) -> ResultStatus {
        let configDir = URL(fileURLWithPath: ClaudeProbeConfig.probeConfigDir())
        let fm = FileManager.default

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: configDir.path, isDirectory: &isDir), isDir.boolValue else {
            let status: ResultStatus = .notFound("No probe config directory found")
            postCleanupStatus(status, mode: mode)
            return status
        }

        // Count session files before deleting (for reporting)
        let sessionFiles = countSessionFiles(in: configDir)
        guard sessionFiles > 0 else {
            let status: ResultStatus = .notFound("No probe sessions found")
            postCleanupStatus(status, mode: mode)
            return status
        }

        // Delete the entire quarantine config dir contents and recreate the empty dir.
        // This is safe because the directory is exclusively owned by Agent Sessions probes.
        do {
            try fm.removeItem(at: configDir)
            try fm.createDirectory(at: configDir, withIntermediateDirectories: true)
            let status: ResultStatus = .success
            postCleanupStatus(status, mode: mode, extra: ["deleted": sessionFiles])
            return status
        } catch {
            let status: ResultStatus = .ioError("Failed to clean probe config dir: \(error.localizedDescription)")
            postCleanupStatus(status, mode: mode)
            return status
        }
    }

    private static func countSessionFiles(in root: URL) -> Int {
        guard let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return 0 }
        var n = 0
        for case let url as URL in e {
            if ["jsonl", "ndjson"].contains(url.pathExtension.lowercased()) { n += 1 }
        }
        return n
    }

    private static func postCleanupStatus(_ status: ResultStatus, mode: String, extra: [String: Any] = [:]) {
        var info: [String: Any] = [
            "mode": mode,
            "status": status.kind,
            "message": status.message ?? ""
        ]
        for (k, v) in extra { info[k] = v }
        if Thread.isMainThread {
            NotificationCenter.default.post(name: didRunCleanupNotification, object: nil, userInfo: info)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: didRunCleanupNotification, object: nil, userInfo: info)
            }
        }
    }
}

private extension ClaudeProbeProject.ResultStatus {
    var kind: String {
        switch self {
        case .success: return "success"
        case .disabled: return "disabled"
        case .notFound: return "not_found"
        case .unsafe: return "unsafe"
        case .ioError: return "io_error"
        }
    }
    var message: String? {
        switch self {
        case .success: return nil
        case .disabled(let s): return s
        case .notFound(let s): return s
        case .unsafe(let s): return s
        case .ioError(let s): return s
        }
    }
}
