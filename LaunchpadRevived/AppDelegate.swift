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

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.app.info("Application will terminate — restoring presentationOptions")
        session.dismiss(reason: "will-terminate")
        session.restorePresentationOptionsIfNeeded()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        session.dismiss(reason: "should-terminate")
        session.restorePresentationOptionsIfNeeded()
        return .terminateNow
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
