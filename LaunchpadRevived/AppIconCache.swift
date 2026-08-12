import AppKit

/// Downsamples app icons once and caches them by bundle identifier (LAY-17).
@MainActor
final class AppIconCache {
    static let shared = AppIconCache()

    private struct Entry {
        let image: NSImage
        let pointSize: CGFloat
    }

    private var entries: [String: Entry] = [:]

    func image(for app: DiscoveredApp, size: CGFloat) -> NSImage {
        let pointSize = max(size, 1)
        if let entry = entries[app.bundleID], entry.pointSize >= pointSize - 0.5 {
            return entry.image
        }
        let source = NSWorkspace.shared.icon(forFile: app.url.path)
        let prepared = Self.downsample(source, to: pointSize)
        entries[app.bundleID] = Entry(image: prepared, pointSize: pointSize)
        return prepared
    }

    private static func downsample(_ source: NSImage, to pointSize: CGFloat) -> NSImage {
        let scale = NSScreen.screens.first?.backingScaleFactor ?? 2
        let pixels = max(1, Int((pointSize * scale).rounded()))
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixels,
                pixelsHigh: pixels,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            let fallback =
                (source.copy() as? NSImage)
                ?? NSImage(size: NSSize(width: pointSize, height: pointSize))
            fallback.size = NSSize(width: pointSize, height: pointSize)
            return fallback
        }

        rep.size = NSSize(width: pointSize, height: pointSize)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(
            in: NSRect(origin: .zero, size: NSSize(width: pointSize, height: pointSize)),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        image.addRepresentation(rep)
        return image
    }
}
