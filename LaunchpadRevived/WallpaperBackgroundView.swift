import AppKit
import SwiftUI

/// Main-display wallpaper, captured once at open, aspect-filled and blurred (WIN-06).
struct WallpaperBackgroundView: View {
    let image: NSImage?

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 24)
                        .overlay(Color.black.opacity(0.25))
                } else {
                    Color.black.opacity(0.85)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

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
