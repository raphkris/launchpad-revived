import CoreGraphics

/// Fixed 5×7 Launchpad grid geometry (LAY-01, LAY-02, LAY-07).
enum GridLayout {
    static let rows = 5
    static let columns = 7
    static let cellsPerPage = rows * columns

    /// Horizontal scroll accumulation before a page turn commits (LAY-06).
    static let pageScrollThreshold: CGFloat = 40
    /// Max displacement still treated as a background click, not a drag (LAY-09).
    static let pageDragClickSlop: CGFloat = 5
    /// Fraction of page width required to commit a drag-turn (LAY-09).
    static let pageDragCommitFraction: CGFloat = 0.25
    /// Release velocity (pt/s) that commits a page flick (LAY-09).
    static let pageDragFlickVelocity: CGFloat = 800

    struct Metrics: Sendable {
        let cellWidth: CGFloat
        let cellHeight: CGFloat
        let iconSize: CGFloat
        let interItemSpacing: CGFloat
        let horizontalPadding: CGFloat
        let topPadding: CGFloat
        let bottomPadding: CGFloat
    }

    /// Cell metrics scale to the display; grid dimensions stay fixed (LAY-02).
    static func metrics(for size: CGSize) -> Metrics {
        let horizontalPadding = max(48, size.width * 0.06)
        let topPadding = max(48, size.height * 0.08)
        let bottomPadding = max(56, size.height * 0.1)
        let interItemSpacing = max(12, min(24, size.width * 0.012))

        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let usableHeight = max(1, size.height - topPadding - bottomPadding)

        let cellWidth =
            (usableWidth - interItemSpacing * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight =
            (usableHeight - interItemSpacing * CGFloat(rows - 1)) / CGFloat(rows)
        let iconSize = min(cellWidth, cellHeight * 0.62)

        return Metrics(
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            iconSize: iconSize,
            interItemSpacing: interItemSpacing,
            horizontalPadding: horizontalPadding,
            topPadding: topPadding,
            bottomPadding: bottomPadding
        )
    }
}
