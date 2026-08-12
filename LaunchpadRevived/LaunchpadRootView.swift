import SwiftUI

/// Root SwiftUI content hosted in the Launchpad window (PRJ-02).
struct LaunchpadRootView: View {
    @Bindable var viewModel: LaunchpadViewModel
    var onBackgroundClick: () -> Void
    var onSelectApp: (DiscoveredApp) -> Void

    var body: some View {
        ZStack {
            WallpaperBackgroundView(image: viewModel.wallpaper)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onBackgroundClick()
                }

            AppGridView(
                apps: viewModel.apps,
                currentPage: $viewModel.currentPage,
                onSelect: onSelectApp
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
