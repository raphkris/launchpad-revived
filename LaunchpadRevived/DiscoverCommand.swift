import Foundation

/// Diagnostic mode: scan and print apps to stdout, then exit (PRJ-10 exception).
enum DiscoverCommand {
    nonisolated static func run() {
        let apps = AppDiscovery.discover()
        for app in apps {
            print("\(app.bundleID)\t\(app.displayName)\t\(app.url.path)")
        }
    }
}
