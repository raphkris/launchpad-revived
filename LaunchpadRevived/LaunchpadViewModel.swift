import AppKit
import Observation

/// Observable UI state for the Launchpad grid session.
@MainActor
@Observable
final class LaunchpadViewModel {
    var apps: [DiscoveredApp] = []
    var wallpaper: NSImage?

    /// Horizontal page index. Any change clears keyboard focus (LAY-08(g)).
    var currentPage = 0 {
        didSet {
            if oldValue != currentPage {
                focusedCellIndex = nil
            }
        }
    }

    /// Optional cell index scoped to the current page (LAY-08). `nil` means nothing focused.
    var focusedCellIndex: Int?

    /// Live drag offset for background page dragging (LAY-09). Zero when not dragging.
    var pageDragOffset: CGFloat = 0

    var pageCount: Int {
        max(1, (apps.count + GridLayout.cellsPerPage - 1) / GridLayout.cellsPerPage)
    }

    /// Number of real apps on `currentPage` (not empty trailing slots).
    var populatedCellCount: Int {
        populatedCellCount(on: currentPage)
    }

    func reload() {
        apps = AppDiscovery.discover()
        currentPage = min(currentPage, max(0, pageCount - 1))
        focusedCellIndex = nil
        pageDragOffset = 0
    }

    func goToNextPage() {
        guard currentPage < pageCount - 1 else { return }
        currentPage += 1
    }

    func goToPreviousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func goToPage(_ page: Int) {
        let clamped = min(max(0, page), max(0, pageCount - 1))
        currentPage = clamped
    }

    /// Clears focus when present. Returns `true` if focus was cleared (LAY-11).
    @discardableResult
    func clearFocusIfNeeded() -> Bool {
        guard focusedCellIndex != nil else { return false }
        focusedCellIndex = nil
        return true
    }

    func moveFocus(_ direction: GridFocusDirection) {
        let count = populatedCellCount
        guard count > 0 else { return }

        guard let current = focusedCellIndex else {
            switch direction {
            case .right, .down:
                focusedCellIndex = 0
            case .left, .up:
                focusedCellIndex = count - 1
            }
            return
        }

        let columns = GridLayout.columns
        let next: Int
        switch direction {
        case .left:
            next = max(0, current - 1)
        case .right:
            next = min(count - 1, current + 1)
        case .up:
            next = current >= columns ? current - columns : current
        case .down:
            let candidate = current + columns
            next = candidate < count ? candidate : count - 1
        }
        focusedCellIndex = next
    }

    func focusedApp() -> DiscoveredApp? {
        guard let focusedCellIndex else { return nil }
        return app(atCell: focusedCellIndex, on: currentPage)
    }

    func appsForPage(_ page: Int) -> [DiscoveredApp] {
        let start = page * GridLayout.cellsPerPage
        guard start < apps.count else { return [] }
        let end = min(start + GridLayout.cellsPerPage, apps.count)
        return Array(apps[start..<end])
    }

    func populatedCellCount(on page: Int) -> Int {
        appsForPage(page).count
    }

    func app(atCell cellIndex: Int, on page: Int) -> DiscoveredApp? {
        let pageApps = appsForPage(page)
        guard pageApps.indices.contains(cellIndex) else { return nil }
        return pageApps[cellIndex]
    }

    /// Rubber-banded visual offset while dragging pages (LAY-09).
    func visualPageOffset(pageWidth: CGFloat) -> CGFloat {
        let raw = pageDragOffset
        let atFirst = currentPage == 0 && raw > 0
        let atLast = currentPage >= pageCount - 1 && raw < 0
        guard atFirst || atLast else { return raw }
        return rubberBand(offset: raw, pageWidth: pageWidth)
    }

    /// Commits or springs back after a background drag (LAY-09).
    func endPageDrag(
        translation: CGFloat,
        velocity: CGFloat,
        pageWidth: CGFloat
    ) -> PageDragEndResult {
        defer { pageDragOffset = 0 }

        if abs(translation) < GridLayout.pageDragClickSlop {
            return .dismiss
        }

        let passedDistance = abs(translation) >= pageWidth * GridLayout.pageDragCommitFraction
        let passedFlick = abs(velocity) >= GridLayout.pageDragFlickVelocity
        guard passedDistance || passedFlick else {
            return .springBack
        }

        // Prefer translation when it cleared the distance bar; otherwise use flick velocity.
        let direction = passedDistance ? translation : velocity
        if direction > 0, currentPage > 0 {
            currentPage -= 1
            return .committed
        }
        if direction < 0, currentPage < pageCount - 1 {
            currentPage += 1
            return .committed
        }
        return .springBack
    }

    private func rubberBand(offset: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let dimension = max(pageWidth, 1)
        let sign: CGFloat = offset < 0 ? -1 : 1
        let magnitude = abs(offset)
        let damped = (1 - (1 / ((magnitude * 0.55 / dimension) + 1))) * dimension
        return sign * damped
    }
}
