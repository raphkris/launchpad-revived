import AppKit
import SwiftUI

/// Owns the Launchpad window session: present, dismiss, presentationOptions (WIN-*).
@MainActor
final class LaunchpadSessionController {
    private var window: LaunchpadWindow?
    private var presentationGuard: PresentationOptionsGuard?
    private var keyDownMonitor: Any?
    private var resignKeyObserver: NSObjectProtocol?
    private var isPresented = false
    private var isDismissing = false

    /// Apps from the most recent present (DISC-12). Populated for later grid phases.
    private(set) var apps: [DiscoveredApp] = []

    func present() {
        if isPresented {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard let screen = NSScreen.screens.first else {
            AppLogger.window.error("No main display (NSScreen.screens.first is nil)")
            return
        }

        apps = AppDiscovery.discover()
        let wallpaper = WallpaperCapture.image(for: screen)

        let rootView = LaunchpadRootView(
            wallpaper: wallpaper,
            onBackgroundClick: { [weak self] in
                self?.dismiss(reason: "background-click")
            }
        )

        let window = LaunchpadWindow(screen: screen)
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = WindowResignDelegate.shared
        WindowResignDelegate.shared.onResignKey = { [weak self] in
            self?.dismiss(reason: "resign-key")
        }

        presentationGuard = PresentationOptionsGuard()
        self.window = window
        isPresented = true
        isDismissing = false

        installKeyMonitor()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        AppLogger.window.info("Launchpad presented on main display")
    }

    func dismiss(reason: String) {
        guard isPresented, !isDismissing else { return }
        isDismissing = true
        AppLogger.window.info("Dismissing Launchpad (\(reason, privacy: .public))")

        removeKeyMonitor()
        WindowResignDelegate.shared.onResignKey = nil

        presentationGuard?.restore()
        presentationGuard = nil

        window?.orderOut(nil)
        window?.contentView = nil
        window = nil
        isPresented = false
        isDismissing = false
    }

    /// Restores presentation options without requiring a presented window (termination).
    func restorePresentationOptionsIfNeeded() {
        presentationGuard?.restore()
        presentationGuard = nil
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {  // Escape
                self.dismiss(reason: "escape")
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
            self.keyDownMonitor = nil
        }
    }
}

/// Forwards window resign-key to the session controller (WIN-11).
final class WindowResignDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowResignDelegate()

    var onResignKey: (() -> Void)?

    func windowDidResignKey(_ notification: Notification) {
        onResignKey?()
    }
}
