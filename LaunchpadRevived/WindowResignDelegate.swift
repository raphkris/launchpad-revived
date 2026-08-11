import AppKit

/// Forwards window resign-key to the session controller (WIN-11).
final class WindowResignDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowResignDelegate()

    @MainActor
    var onResignKey: (() -> Void)?

    func windowDidResignKey(_ notification: Notification) {
        Task { @MainActor in
            onResignKey?()
        }
    }
}
