import OSLog

/// Shared `os.Logger` instances for Launchpad Revived (PRJ-10).
enum AppLogger {
    static let subsystem = "lol.omg.rkm.LaunchpadRevived"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let discovery = Logger(subsystem: subsystem, category: "discovery")
    static let window = Logger(subsystem: subsystem, category: "window")
    static let launch = Logger(subsystem: subsystem, category: "launch")
}
