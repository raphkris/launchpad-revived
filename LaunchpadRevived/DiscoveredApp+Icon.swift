import AppKit

extension DiscoveredApp {
    /// Icon for this app via `NSWorkspace` (DISC-09).
    @MainActor
    func icon(size: CGFloat = 128) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: size, height: size)
        return image
    }
}
