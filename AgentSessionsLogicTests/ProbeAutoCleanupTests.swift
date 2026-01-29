import XCTest
import Foundation

final class ProbeAutoCleanupTests: XCTestCase {
    private func setEnv(_ key: String, _ value: String) { setenv(key, value, 1) }
    private func mkdtemp(prefix: String = "as-probe-auto") -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testCleanupNowIfAutoDeletesQuarantineDir() throws {
        let configDir = mkdtemp(prefix: "as-probe-config")
        setEnv("AS_TEST_PROBE_CONFIG_DIR", configDir.path)

        // Create a fake session file inside the quarantine dir
        let projectsDir = configDir.appendingPathComponent("projects/test-proj")
        try FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        try "{}".write(to: projectsDir.appendingPathComponent("one.jsonl"), atomically: true, encoding: .utf8)

        // Enable auto mode and execute immediate cleanup
        ClaudeProbeProject.setCleanupMode(.auto)
        let status = ClaudeProbeProject.cleanupNowIfAuto()
        switch status {
        case .success: break
        default: XCTFail("Expected success, got: \(status)")
        }
        // The config dir should be recreated empty
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: configDir.path, isDirectory: &isDir))
        // But session files should be gone
        XCTAssertFalse(FileManager.default.fileExists(atPath: projectsDir.path, isDirectory: &isDir))
    }
}
