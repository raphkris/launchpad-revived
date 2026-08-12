import SwiftUI

/// Paginated 5×7 app grid (LAY-01, LAY-02, LAY-04, LAY-07, LAY-08, LAY-10, LAY-12).
///
/// Keyboard and scroll page-turn handling live on `LaunchpadRootView` so focus stays
/// on the root surface (LAY-05, LAY-06, LAY-08).
struct AppGridView: View {
    @Bindable var viewModel: LaunchpadViewModel
    var onSelect: (DiscoveredApp) -> Void

    @State private var gridSize: CGSize = .zero

    var body: some View {
        ZStack {
            if gridSize.width > 0, gridSize.height > 0 {
                let metrics = GridLayout.metrics(for: gridSize)
                let pageWidth = gridSize.width

                VStack(spacing: 0) {
                    pageStrip(pageWidth: pageWidth, metrics: metrics)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    PageIndicatorView(
                        pageCount: viewModel.pageCount,
                        currentPage: viewModel.currentPage,
                        onSelect: { viewModel.goToPage($0) }
                    )
                    .padding(.bottom, max(16, metrics.bottomPadding * 0.35))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .allowsHitTesting(false)
                    .onAppear { gridSize = geometry.size }
                    .onChange(of: geometry.size) { _, newSize in
                        gridSize = newSize
                    }
            }
        }
        .onChange(of: viewModel.pageCount) { _, newCount in
            if viewModel.currentPage >= newCount {
                viewModel.goToPage(max(0, newCount - 1))
            }
        }
    }

    @ViewBuilder
    private func pageStrip(pageWidth: CGFloat, metrics: GridLayout.Metrics) -> some View {
        let first = max(0, viewModel.currentPage - 1)
        let last = min(viewModel.pageCount - 1, viewModel.currentPage + 1)
        let currentIndex = viewModel.currentPage - first
        let offset =
            -CGFloat(currentIndex) * pageWidth
            + viewModel.visualPageOffset(pageWidth: pageWidth)

        HStack(spacing: 0) {
            ForEach(first...last, id: \.self) { page in
                pageContent(page: page, metrics: metrics)
                    .frame(width: pageWidth)
            }
        }
        .offset(x: offset)
        .frame(width: pageWidth, alignment: .leading)
        .clipped()
    }

    @ViewBuilder
    private func pageContent(page: Int, metrics: GridLayout.Metrics) -> some View {
        let pageApps = viewModel.appsForPage(page)

        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(minimum: 0),
                    spacing: metrics.interItemSpacing,
                    alignment: .top
                ),
                count: GridLayout.columns
            ),
            alignment: .center,
            spacing: metrics.interItemSpacing
        ) {
            ForEach(Array(pageApps.enumerated()), id: \.element.id) { cellIndex, app in
                let focused =
                    page == viewModel.currentPage
                    && viewModel.focusedCellIndex == cellIndex
                cell(app: app, isFocused: focused, metrics: metrics)
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func cell(
        app: DiscoveredApp,
        isFocused: Bool,
        metrics: GridLayout.Metrics
    ) -> some View {
        // Clear cell frame does not hit-test; only the icon+label button does (LAY-10).
        ZStack(alignment: .top) {
            Color.clear
                .frame(width: metrics.cellWidth, height: metrics.cellHeight)
                .allowsHitTesting(false)

            AppIconView(
                app: app,
                badge: nil,
                iconSize: metrics.iconSize,
                isFocused: isFocused,
                action: { onSelect(app) }
            )
        }
        .frame(width: metrics.cellWidth, height: metrics.cellHeight, alignment: .top)
    }
}
