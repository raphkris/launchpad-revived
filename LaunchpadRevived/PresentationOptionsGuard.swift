import AppKit

/// Applies and restores `NSApp.presentationOptions` for a Launchpad session (WIN-03, WIN-12).
///
/// Restore is idempotent and must run on every session-ending path: normal dismissal,
/// termination, and best-effort process exit via `atexit`.
@MainActor
final class PresentationOptionsGuard {
    private let previousOptions: NSApplication.PresentationOptions
    private var didRestore = false

    init() {
        Self.installExitHandlerIfNeeded()
        previousOptions = NSApp.presentationOptions
        Self.store(previousOptions)
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        AppLogger.window.info("Applied presentationOptions [.hideDock, .hideMenuBar]")
    }

    func restore() {
        guard !didRestore else { return }
        didRestore = true
        NSApp.presentationOptions = previousOptions
        Self.clearStore()
        AppLogger.window.info("Restored presentationOptions")
    }

    deinit {
        // Best-effort if the owner forgot an explicit restore. AppKit access from deinit
        // under MainActor isolation uses the stored emergency path when needed.
        if !didRestore {
            let previous = previousOptions
            PresentationOptionsGuard.restoreStored(previous)
        }
    }

    // MARK: - Process-wide emergency restore (WIN-12)

    nonisolated(unsafe) private static var storedRaw: UInt = 0
    nonisolated(unsafe) private static var hasStored = false
    nonisolated(unsafe) private static var exitHandlerInstalled = false

    nonisolated private static func store(_ options: NSApplication.PresentationOptions) {
        storedRaw = options.rawValue
        hasStored = true
    }

    nonisolated private static func clearStore() {
        hasStored = false
    }

    nonisolated private static func restoreStored(_ options: NSApplication.PresentationOptions) {
        NSApp.presentationOptions = options
        clearStore()
    }

    /// Best-effort restore for `atexit` / signal paths. AppKit is not async-signal-safe;
    /// this covers orderly `exit` and cooperative termination, not hard crashes.
    nonisolated static func restoreEmergencyIfNeeded() {
        guard hasStored else { return }
        let options = NSApplication.PresentationOptions(rawValue: storedRaw)
        hasStored = false
        NSApp.presentationOptions = options
    }

    nonisolated private static func installExitHandlerIfNeeded() {
        guard !exitHandlerInstalled else { return }
        exitHandlerInstalled = true
        atexit {
            PresentationOptionsGuard.restoreEmergencyIfNeeded()
        }

        let handler: @convention(c) (Int32) -> Void = { signal in
            PresentationOptionsGuard.restoreEmergencyIfNeeded()
            // Re-raise with default disposition so the process still terminates.
            Darwin.signal(signal, SIG_DFL)
            _ = Darwin.raise(signal)
        }
        Darwin.signal(SIGINT, handler)
        Darwin.signal(SIGTERM, handler)
        Darwin.signal(SIGHUP, handler)
    }
}
