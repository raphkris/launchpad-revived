import AppKit
import Observation
import SwiftUI

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

    /// Live drag offset for continuous page gestures (LAY-09, LAY-14). Zero when idle.
    var pageDragOffset: CGFloat = 0

    /// Width of one page in the strip; updated from layout (LAY-14).
    var pageWidth: CGFloat = 1

    var pageCount: Int {
        max(1, (apps.count + GridLayout.cellsPerPage - 1) / GridLayout.cellsPerPage)
    }

    /// Number of real apps on `currentPage` (not empty trailing slots).
    var populatedCellCount: Int {
        populatedCellCount(on: currentPage)
    }

    private var isSettling = false

    func reload() {
        apps = AppDiscovery.discover()
        currentPage = min(currentPage, max(0, pageCount - 1))
        focusedCellIndex = nil
        pageDragOffset = 0
        isSettling = false
    }

    func goToNextPage() {
        settle(to: .next, velocity: 0)
    }

    func goToPreviousPage() {
        settle(to: .previous, velocity: 0)
    }

    func goToPage(_ page: Int) {
        let clamped = min(max(0, page), max(0, pageCount - 1))
        let delta = clamped - currentPage
        if delta == 1 {
            settle(to: .next, velocity: 0)
        } else if delta == -1 {
            settle(to: .previous, velocity: 0)
        } else if delta != 0 {
            withoutAnimation {
                currentPage = clamped
                pageDragOffset = 0
            }
        }
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

    /// Rubber-banded visual offset while dragging pages (LAY-09, LAY-14(a)).
    func visualPageOffset(pageWidth: CGFloat) -> CGFloat {
        let raw = pageDragOffset
        let atFirst = currentPage == 0 && raw > 0
        let atLast = currentPage >= pageCount - 1 && raw < 0
        guard atFirst || atLast else { return raw }
        return rubberBand(offset: raw, pageWidth: pageWidth)
    }

    /// 1:1 tracking during a continuous gesture (LAY-14(a)).
    func setPageDragOffset(_ offset: CGFloat) {
        guard !isSettling else { return }
        withoutAnimation {
            pageDragOffset = offset
        }
    }

    /// Shared settle for trackpad scroll and background drag (LAY-14).
    func settlePageDrag(
        translation: CGFloat,
        velocity: CGFloat,
        allowsDismiss: Bool
    ) -> PageDragEndResult {
        if allowsDismiss, abs(translation) < GridLayout.pageDragClickSlop {
            withoutAnimation {
                pageDragOffset = 0
            }
            return .dismiss
        }

        let threshold =
            allowsDismiss
            ? pageWidth * GridLayout.pageDragCommitFraction
            : GridLayout.pageScrollThreshold
        let proposed: PageSettleTarget
        if abs(translation) >= threshold {
            proposed = translation > 0 ? .previous : .next
        } else {
            proposed = .springBack
        }
        let resolved = resolvedTarget(proposed)
        settle(to: resolved, velocity: velocity)
        return resolved == .springBack ? .springBack : .committed
    }

    /// One page-transition model for scroll, drag, keyboard, and dots (LAY-14).
    func settle(to target: PageSettleTarget, velocity: CGFloat) {
        let resolved = resolvedTarget(target)
        guard !isSettling else { return }

        let destinationOffset: CGFloat
        switch resolved {
        case .springBack:
            destinationOffset = 0
        case .previous:
            destinationOffset = pageWidth
        case .next:
            destinationOffset = -pageWidth
        }

        if pageWidth <= 1 {
            apply(resolved)
            pageDragOffset = 0
            return
        }

        isSettling = true
        let response = GridLayout.pageSettleResponse(velocity: velocity)
        withAnimation(.interactiveSpring(response: response, dampingFraction: 0.85)) {
            pageDragOffset = destinationOffset
        } completion: {
            guard self.isSettling else { return }
            self.withoutAnimation {
                self.apply(resolved)
                self.pageDragOffset = 0
                self.isSettling = false
            }
        }
    }

    private func resolvedTarget(_ target: PageSettleTarget) -> PageSettleTarget {
        switch target {
        case .previous where currentPage <= 0:
            return .springBack
        case .next where currentPage >= pageCount - 1:
            return .springBack
        default:
            return target
        }
    }

    private func apply(_ target: PageSettleTarget) {
        switch target {
        case .springBack:
            break
        case .previous:
            if currentPage > 0 { currentPage -= 1 }
        case .next:
            if currentPage < pageCount - 1 { currentPage += 1 }
        }
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }

    private func rubberBand(offset: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let dimension = max(pageWidth, 1)
        let sign: CGFloat = offset < 0 ? -1 : 1
        let magnitude = abs(offset)
        let damped = (1 - (1 / ((magnitude * 0.55 / dimension) + 1))) * dimension
        return sign * damped
    }
}
