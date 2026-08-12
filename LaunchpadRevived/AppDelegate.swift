import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let session = LaunchpadSessionController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.app.info("Application launched")
        session.present()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        session.present()
        return true
    }

    /// WIN-14: covers `⌘⇥`, Mission Control, Spotlight, and any other app taking over.
    func applicationDidResignActive(_ notification: Notification) {
        session.dismiss(reason: .resignActive)
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.app.info("Application will terminate — restoring presentationOptions")
        // WIN-17: restore first and synchronously; the dismissal below skips the fade.
        session.restorePresentationOptionsIfNeeded()
        session.dismiss(reason: .terminating)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        session.restorePresentationOptionsIfNeeded()
        session.dismiss(reason: .terminating)
        return .terminateNow
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
