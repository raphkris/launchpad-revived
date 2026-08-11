import AppKit

/// Borderless full-screen Launchpad window on the main display (WIN-01, WIN-02, WIN-04).
final class LaunchpadWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// - Parameter screen: Must be `NSScreen.screens.first` (menu-bar display, WIN-01).
    convenience init(screen: NSScreen) {
        let frame = screen.frame
        self.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        setFrame(frame, display: true)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenNone]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        collectionBehavior.insert(.fullScreenNone)
    }
}
