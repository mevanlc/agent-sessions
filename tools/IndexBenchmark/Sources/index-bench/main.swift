import Foundation

// MARK: - Arg parsing

struct CLIConfig {
    var sources: Set<String> = ["codex", "claude", "gemini", "opencode", "copilot", "droid"]
    var dbPath: String? = nil
    var verbose: Bool = false
    var help: Bool = false
}

func parseArgs() -> CLIConfig {
    var cfg = CLIConfig()
    let args = Array(CommandLine.arguments.dropFirst())
    var i = 0
    while i < args.count {
        switch args[i] {
        case "--sources":
            if i + 1 < args.count {
                cfg.sources = Set(args[i + 1].split(separator: ",").map(String.init))
                i += 1
            }
        case "--db-path":
            if i + 1 < args.count {
                cfg.dbPath = args[i + 1]
                i += 1
            }
        case "--verbose", "-v":
            cfg.verbose = true
        case "--help", "-h":
            cfg.help = true
        default:
            break
        }
        i += 1
    }
    return cfg
}

func printUsage() {
    print("""
    index-bench — AgentSessions indexing benchmark

    Usage: index-bench [options]

    Options:
      --sources codex,claude   Comma-separated sources (default: all)
      --db-path /tmp/bench.db  Custom DB path (default: standard app location)
      -v, --verbose            Per-file timing output
      -h, --help               Show this help
    """)
}

// MARK: - Main

let cfg = parseArgs()
if cfg.help {
    printUsage()
    exit(0)
}

print("=== index-bench ===")
print("Sources: \(cfg.sources.sorted().joined(separator: ", "))")
print("Verbose: \(cfg.verbose)")
if let p = cfg.dbPath { print("DB path: \(p)") }
print()

let overallStart = Date()

// If custom DB path, we need to use it. For now IndexDB always uses the standard location.
// TODO: support custom DB path via IndexDB init parameter
if let dbPath = cfg.dbPath {
    print("Warning: --db-path not yet supported, using standard location")
    print("  (would use: \(dbPath))")
}

let db: IndexDB
do {
    db = try IndexDB()
} catch {
    print("Failed to open IndexDB: \(error)")
    exit(1)
}

let indexConfig = AnalyticsIndexer.Config(toolIOEnabled: true, verbose: cfg.verbose)
let indexer = AnalyticsIndexer(db: db, enabledSources: cfg.sources, config: indexConfig)

print("Starting fullBuild()...")
let buildStart = Date()

// Use a semaphore to block the main thread while async work runs
let sem = DispatchSemaphore(value: 0)
Task {
    await indexer.fullBuild()
    sem.signal()
}
sem.wait()

let buildDuration = Date().timeIntervalSince(buildStart)
let totalDuration = Date().timeIntervalSince(overallStart)

print()
print("=== Summary ===")
print(String(format: "Build:  %.2fs", buildDuration))
print(String(format: "Total:  %.2fs", totalDuration))

// Per-source session counts
let countSem = DispatchSemaphore(value: 0)
Task {
    for source in cfg.sources.sorted() {
        do {
            let meta = try await db.fetchSessionMeta(for: source)
            print("\(source): \(meta.count) sessions")
        } catch {
            print("\(source): error — \(error)")
        }
    }
    countSem.signal()
}
countSem.wait()
