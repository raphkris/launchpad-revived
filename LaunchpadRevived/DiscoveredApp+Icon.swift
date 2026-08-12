import AppKit

extension DiscoveredApp {
    /// Icon for this app via `NSWorkspace` (DISC-09), downsampled and cached (LAY-17).
    @MainActor
    func icon(size: CGFloat = 128) -> NSImage {
        AppIconCache.shared.image(for: self, size: size)
    }
}
