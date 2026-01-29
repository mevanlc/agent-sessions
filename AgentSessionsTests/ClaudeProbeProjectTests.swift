import XCTest
import Foundation

final class ClaudeProbeProjectTests: XCTestCase {
    private func setEnv(_ key: String, _ value: String) {
        setenv(key, value, 1)
    }

    private func mkdtemp(prefix: String = "as-probe-tests") -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testCleanupDeletesQuarantineContents() throws {
        let configDir = mkdtemp(prefix: "as-probe-config")
        setEnv("AS_TEST_PROBE_CONFIG_DIR", configDir.path)

        // Create fake session files
        let projectsDir = configDir.appendingPathComponent("projects/test-proj")
        try FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        try "{}".write(to: projectsDir.appendingPathComponent("session.jsonl"), atomically: true, encoding: .utf8)

        let status = ClaudeProbeProject.cleanupNowUserInitiated()
        switch status {
        case .success:
            break // expected
        default:
            XCTFail("Expected success, got: \(status)")
        }
        // Config dir should be recreated empty
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: configDir.path, isDirectory: &isDir))
        XCTAssertFalse(FileManager.default.fileExists(atPath: projectsDir.path, isDirectory: &isDir))
    }

    func testCleanupReportsNotFoundWhenEmpty() throws {
        let configDir = mkdtemp(prefix: "as-probe-config")
        setEnv("AS_TEST_PROBE_CONFIG_DIR", configDir.path)

        // Empty config dir — no session files
        let status = ClaudeProbeProject.cleanupNowUserInitiated()
        switch status {
        case .notFound:
            break // expected
        default:
            XCTFail("Expected notFound, got: \(status)")
        }
    }

    func testCleanupReportsNotFoundWhenDirMissing() throws {
        let configDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("as-probe-nonexistent-\(UUID().uuidString)")
        setEnv("AS_TEST_PROBE_CONFIG_DIR", configDir.path)

        let status = ClaudeProbeProject.cleanupNowUserInitiated()
        switch status {
        case .notFound:
            break // expected
        default:
            XCTFail("Expected notFound, got: \(status)")
        }
    }

    func testCleanupIfAutoDisabledByDefault() throws {
        ClaudeProbeProject.setCleanupMode(.none)
        let status = ClaudeProbeProject.cleanupNowIfAuto()
        switch status {
        case .disabled:
            break // expected
        default:
            XCTFail("Expected disabled, got: \(status)")
        }
    }

    func testNoteProbeRunIsNoOp() {
        // Should not crash or do any I/O
        ClaudeProbeProject.noteProbeRun()
    }
}
