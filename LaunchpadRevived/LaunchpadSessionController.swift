import AppKit
import OSLog
import SwiftUI

/// Owns the Launchpad window session: present, dismiss, presentationOptions (WIN-*).
@MainActor
final class LaunchpadSessionController {
    private var window: LaunchpadWindow?
    private var presentationGuard: PresentationOptionsGuard?
    private var keyDownMonitor: Any?
    private var isPresented = false
    private var isDismissing = false

    private let viewModel = LaunchpadViewModel()

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

        // DISC-12: rescan on every open.
        viewModel.reload()
        viewModel.wallpaper = WallpaperCapture.image(for: screen)

        let rootView = LaunchpadRootView(
            viewModel: viewModel,
            onBackgroundClick: { [weak self] in
                self?.dismiss(reason: "background-click")
            },
            onSelectApp: { [weak self] app in
                self?.launchAndDismiss(app)
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

    private func launchAndDismiss(_ app: DiscoveredApp) {
        // Dismiss first so presentationOptions are restored before the target activates (WIN-11, INT-01).
        dismiss(reason: "launch")
        Task { @MainActor in
            await AppLauncher.launch(app)
        }
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            switch event.keyCode {
            case 53:  // Escape
                self.dismiss(reason: "escape")
                return nil
            case 123:  // Left arrow (LAY-05)
                self.viewModel.goToPreviousPage()
                return nil
            case 124:  // Right arrow (LAY-05)
                self.viewModel.goToNextPage()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
            self.keyDownMonitor = nil
        }
    }
}
