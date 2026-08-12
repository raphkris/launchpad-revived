import AppKit
import OSLog
import SwiftUI

/// Owns the Launchpad window session: present, dismiss, presentationOptions (WIN-*).
@MainActor
final class LaunchpadSessionController {
    /// Why a session is ending. Determines focus handling (WIN-13) and fading (WIN-17).
    enum DismissReason: String {
        case escape
        case backgroundClick = "background-click"
        case resignKey = "resign-key"
        case resignActive = "resign-active"
        case launch
        case terminating

        /// INT-01 lets the launched app take focus itself; hiding would race it (WIN-13).
        var returnsFocusToPreviousApp: Bool {
            switch self {
            case .escape, .backgroundClick, .resignKey, .resignActive: true
            case .launch, .terminating: false
            }
        }

        /// WIN-12 outranks WIN-15: nothing animates between termination and a restored menu bar.
        var fades: Bool { self != .terminating }
    }

    /// Fade timing in seconds (WIN-16). Moves under `config` (JSN-09) in Slice 2.
    static let windowFadeInDuration: TimeInterval = 0.25
    static let windowFadeOutDuration: TimeInterval = 0.18

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
                self?.dismiss(reason: .backgroundClick)
            },
            onSelectApp: { [weak self] app in
                self?.launchAndDismiss(app)
            }
        )

        let window = LaunchpadWindow(screen: screen)
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = WindowResignDelegate.shared
        WindowResignDelegate.shared.onResignKey = { [weak self] in
            self?.dismiss(reason: .resignKey)
        }

        presentationGuard = PresentationOptionsGuard()
        self.window = window
        isPresented = true
        isDismissing = false

        installKeyMonitor()

        // WIN-15: fade in from fully transparent.
        window.alphaValue = 0
        NSApp.unhide(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.windowFadeInDuration
            window.animator().alphaValue = 1
        }
        AppLogger.window.info("Launchpad presented on main display")
    }

    /// Idempotent: WIN-11, WIN-14 and the resign-key path can all fire for one user action.
    func dismiss(reason: DismissReason) {
        guard isPresented, !isDismissing else { return }
        isDismissing = true
        AppLogger.window.info("Dismissing Launchpad (\(reason.rawValue, privacy: .public))")

        removeKeyMonitor()
        WindowResignDelegate.shared.onResignKey = nil

        guard let window, reason.fades else {
            finishDismissal(reason: reason)
            return
        }

        // WIN-15: presentationOptions stay applied until the fade completes, otherwise the
        // Dock and menu bar reappear while Launchpad is still on screen.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.windowFadeOutDuration
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.finishDismissal(reason: reason)
            }
        }
    }

    private func finishDismissal(reason: DismissReason) {
        window?.orderOut(nil)
        window?.contentView = nil
        window = nil

        presentationGuard?.restore()
        presentationGuard = nil

        isPresented = false
        isDismissing = false

        // WIN-13: ordering out alone leaves this app frontmost with an empty menu bar.
        if reason.returnsFocusToPreviousApp {
            NSApp.hide(nil)
        }
    }

    /// Restores presentation options without requiring a presented window (termination).
    func restorePresentationOptionsIfNeeded() {
        presentationGuard?.restore()
        presentationGuard = nil
    }

    private func launchAndDismiss(_ app: DiscoveredApp) {
        // The launched app takes focus itself, so this path fades out without hiding (WIN-13, INT-01).
        dismiss(reason: .launch)
        Task { @MainActor in
            await AppLauncher.launch(app)
        }
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            switch event.keyCode {
            case 53:  // Escape — clear focus first (LAY-11), else dismiss (WIN-11)
                if self.viewModel.clearFocusIfNeeded() {
                    return nil
                }
                self.dismiss(reason: .escape)
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
