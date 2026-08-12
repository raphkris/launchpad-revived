import AppKit
import OSLog

/// Launches apps via `NSWorkspace`, activating an existing instance when running (INT-01, INT-02).
enum AppLauncher {
    @MainActor
    static func launch(_ app: DiscoveredApp) async {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        do {
            _ = try await NSWorkspace.shared.openApplication(
                at: app.url,
                configuration: configuration
            )
            AppLogger.launch.info(
                "Launched \(app.bundleID, privacy: .public) (\(app.displayName, privacy: .public))"
            )
        } catch {
            AppLogger.launch.error(
                "Failed to launch \(app.bundleID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}
