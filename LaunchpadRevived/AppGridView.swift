import SwiftUI

/// Paginated 5×7 app grid (LAY-01, LAY-02, LAY-04, LAY-05, LAY-07).
struct AppGridView: View {
    let apps: [DiscoveredApp]
    @Binding var currentPage: Int
    var onSelect: (DiscoveredApp) -> Void

    private var pageCount: Int {
        max(1, (apps.count + GridLayout.cellsPerPage - 1) / GridLayout.cellsPerPage)
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = GridLayout.metrics(for: geometry.size)

            VStack(spacing: 0) {
                pageContent(metrics: metrics)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                PageIndicatorView(pageCount: pageCount, currentPage: $currentPage)
                    .padding(.bottom, max(16, metrics.bottomPadding * 0.35))
            }
            .onChange(of: pageCount) { _, newCount in
                if currentPage >= newCount {
                    currentPage = max(0, newCount - 1)
                }
            }
        }
    }

    @ViewBuilder
    private func pageContent(metrics: GridLayout.Metrics) -> some View {
        let pageApps = appsForPage(currentPage)

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
            ForEach(pageApps) { app in
                AppIconView(
                    app: app,
                    badge: nil,
                    iconSize: metrics.iconSize,
                    action: { onSelect(app) }
                )
                .frame(width: metrics.cellWidth, height: metrics.cellHeight)
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func appsForPage(_ page: Int) -> [DiscoveredApp] {
        let start = page * GridLayout.cellsPerPage
        guard start < apps.count else { return [] }
        let end = min(start + GridLayout.cellsPerPage, apps.count)
        return Array(apps[start..<end])
    }
}
