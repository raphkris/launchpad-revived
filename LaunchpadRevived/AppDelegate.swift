import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Launchpad Revived"
        window.contentView = NSHostingView(rootView: EmptyRootView())
        window.makeKeyAndOrderFront(nil)
        self.window = window
        AppLogger.app.info("Application launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.app.info("Application will terminate")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
