import Foundation
#if canImport(XCTest)
import AgentSessions
#endif

/// Shared configuration and helpers for identifying Agent Sessions' Claude usage probe sessions.
enum ClaudeProbeConfig {
    /// Absolute path to the dedicated working directory used for probe sessions.
    /// macOS: ~/Library/Application Support/AgentSessions/ClaudeProbeProject
    static func probeWorkingDirectory() -> String {
        // Test override support: AS_TEST_PROBE_WD
        if let override = envValue("AS_TEST_PROBE_WD"), !override.isEmpty {
            return (override as NSString).expandingTildeInPath
        }
        let home = NSHomeDirectory() as NSString
        return home.appendingPathComponent("Library/Application Support/AgentSessions/ClaudeProbeProject")
    }

    /// Quarantined CLAUDE_CONFIG_DIR for probe sessions.
    /// Setting this env var when launching Claude Code causes it to write session
    /// data under this directory instead of ~/.claude/, making probe sessions
    /// trivially identifiable by path prefix — no filesystem scanning needed.
    static func probeConfigDir() -> String {
        if let override = envValue("AS_TEST_PROBE_CONFIG_DIR"), !override.isEmpty {
            return (override as NSString).expandingTildeInPath
        }
        let home = NSHomeDirectory() as NSString
        return home.appendingPathComponent("Library/Application Support/AgentSessions/claude-probe-config")
    }

    /// Returns true if the given session appears to be an Agent Sessions probe session.
    static func isProbeSession(_ session: Session) -> Bool {
        guard session.source == .claude else { return false }

        // 1) Fast path: session file lives under our quarantined config dir (new probes)
        let configPrefix = probeConfigDir()
        if session.filePath.hasPrefix(configPrefix + "/") {
            return true
        }

        // 2) Legacy: session file lives under a previously-discovered probe project
        //    in ~/.claude/projects/. Uses a cached result to avoid repeated filesystem scans.
        if let projectID = ClaudeProbeProject.cachedProbeProjectId(), !projectID.isEmpty {
            let legacyRoot = (NSHomeDirectory() as NSString)
                .appendingPathComponent(".claude/projects/\(projectID)")
            if session.filePath.hasPrefix(legacyRoot + "/") {
                return true
            }
        }

        // 3) cwd match for lightweight sessions
        if let cwd = session.lightweightCwd, !cwd.isEmpty {
            if normalizePath(cwd) == normalizePath(probeWorkingDirectory()) { return true }
        }

        return false
    }

    private static func normalizePath(_ path: String) -> String {
        let expanded = (path as NSString).expandingTildeInPath
        return (expanded as NSString).standardizingPath
    }

    private static func envValue(_ key: String) -> String? {
        guard let value = getenv(key) else { return nil }
        return String(cString: value)
    }
}
