import OSLog

/// Shared `os.Logger` instances for Launchpad Revived (PRJ-10).
enum AppLogger: Sendable {
    nonisolated static let subsystem = "lol.omg.rkm.LaunchpadRevived"

    nonisolated static let app = Logger(subsystem: subsystem, category: "app")
    nonisolated static let discovery = Logger(subsystem: subsystem, category: "discovery")
    nonisolated static let window = Logger(subsystem: subsystem, category: "window")
    nonisolated static let launch = Logger(subsystem: subsystem, category: "launch")
}
