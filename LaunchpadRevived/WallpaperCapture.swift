import AppKit

enum WallpaperCapture {
    @MainActor
    static func image(for screen: NSScreen) -> NSImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else {
            AppLogger.window.error("No desktop image URL for main display")
            return nil
        }
        guard let image = NSImage(contentsOf: url) else {
            AppLogger.window.error("Failed to load wallpaper at \(url.path, privacy: .public)")
            return nil
        }
        return image
    }
}
