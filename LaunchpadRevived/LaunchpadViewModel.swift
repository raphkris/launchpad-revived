import AppKit
import Observation

/// Observable UI state for the Launchpad grid session.
@MainActor
@Observable
final class LaunchpadViewModel {
    var apps: [DiscoveredApp] = []
    var wallpaper: NSImage?
    var currentPage = 0

    var pageCount: Int {
        max(1, (apps.count + GridLayout.cellsPerPage - 1) / GridLayout.cellsPerPage)
    }

    func reload() {
        apps = AppDiscovery.discover()
        currentPage = min(currentPage, max(0, pageCount - 1))
    }

    func goToNextPage() {
        guard pageCount > 0 else { return }
        currentPage = min(currentPage + 1, pageCount - 1)
    }

    func goToPreviousPage() {
        currentPage = max(currentPage - 1, 0)
    }
}
