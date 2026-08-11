import SwiftUI

/// Root SwiftUI content hosted in the Launchpad window (PRJ-02).
struct LaunchpadRootView: View {
    var wallpaper: NSImage?
    var onBackgroundClick: () -> Void

    var body: some View {
        ZStack {
            WallpaperBackgroundView(image: wallpaper)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onBackgroundClick()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
