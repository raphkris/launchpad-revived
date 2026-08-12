import Foundation

/// A discovered application candidate (DISC-07–DISC-10).
struct DiscoveredApp: Identifiable, Sendable, Hashable {
    /// Bundle identifier, or a stable path-hash fallback when the bundle ID is missing (DISC-07).
    let bundleID: String
    var id: String { bundleID }

    let displayName: String
    let url: URL
    let isFromAppStore: Bool
}
