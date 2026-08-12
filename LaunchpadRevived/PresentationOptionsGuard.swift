import AppKit
import OSLog

/// Applies and restores `NSApp.presentationOptions` for a Launchpad session (WIN-03, WIN-12).
///
/// Restore is idempotent and must run on every session-ending path: normal dismissal,
/// termination, and best-effort process exit via `atexit` / cooperative signals.
@MainActor
final class PresentationOptionsGuard {
    private var didRestore = false

    init() {
        Self.installExitHandlerIfNeeded()
        let previousOptions = NSApp.presentationOptions
        Self.store(previousOptions)
        Self.sessionPreviousRaw = previousOptions.rawValue
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        AppLogger.window.info("Applied presentationOptions [.hideDock, .hideMenuBar]")
    }

    func restore() {
        guard !didRestore else { return }
        didRestore = true
        let previous = NSApplication.PresentationOptions(rawValue: Self.sessionPreviousRaw)
        NSApp.presentationOptions = previous
        Self.clearStore()
        AppLogger.window.info("Restored presentationOptions")
    }

    deinit {
        // Cannot touch MainActor state here; emergency path uses the process-wide store.
        PresentationOptionsGuard.restoreEmergencyIfNeeded()
    }

    // MARK: - Process-wide emergency restore (WIN-12)

    nonisolated(unsafe) private static var storedRaw: UInt = 0
    nonisolated(unsafe) private static var sessionPreviousRaw: UInt = 0
    nonisolated(unsafe) private static var hasStored = false
    nonisolated(unsafe) private static var exitHandlerInstalled = false

    nonisolated private static func store(_ options: NSApplication.PresentationOptions) {
        storedRaw = options.rawValue
        hasStored = true
    }

    nonisolated private static func clearStore() {
        hasStored = false
    }

    /// Best-effort restore for `atexit` / signal paths. AppKit is not async-signal-safe;
    /// this covers orderly `exit` and cooperative termination, not hard crashes (SIGSEGV).
    nonisolated static func restoreEmergencyIfNeeded() {
        guard hasStored else { return }
        let raw = storedRaw
        hasStored = false
        let options = NSApplication.PresentationOptions(rawValue: raw)
        applyPresentationOptionsFromEmergencyPath(options)
    }

    /// Crosses to the main actor deliberately for WIN-12 teardown outside normal MainActor calls.
    nonisolated private static func applyPresentationOptionsFromEmergencyPath(
        _ options: NSApplication.PresentationOptions
    ) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                NSApp.presentationOptions = options
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    NSApp.presentationOptions = options
                }
            }
        }
    }

    nonisolated private static func installExitHandlerIfNeeded() {
        guard !exitHandlerInstalled else { return }
        exitHandlerInstalled = true
        atexit {
            PresentationOptionsGuard.restoreEmergencyIfNeeded()
        }

        let handler: @convention(c) (Int32) -> Void = { signal in
            PresentationOptionsGuard.restoreEmergencyIfNeeded()
            Darwin.signal(signal, SIG_DFL)
            _ = Darwin.raise(signal)
        }
        Darwin.signal(SIGINT, handler)
        Darwin.signal(SIGTERM, handler)
        Darwin.signal(SIGHUP, handler)
    }
}
