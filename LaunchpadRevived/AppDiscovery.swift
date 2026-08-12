import CryptoKit
import Foundation
import OSLog

/// Scans standard application roots and returns launchable app bundles (DISC-01–DISC-10).
///
/// Pure filesystem work with no UI state, so the whole type opts out of the
/// project-wide `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` default.
nonisolated enum AppDiscovery {
    private static let maxDepthBelowRoot = 3

    /// Roots in scan order (DISC-01). Earlier roots win when bundle IDs collide.
    static var roots: [URL] {
        let homeApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeApps,
        ]
    }

    /// Discovers apps across all roots, flattened, sorted alphabetically by display name.
    static func discover() -> [DiscoveredApp] {
        var seenBundleIDs = Set<String>()
        var results: [DiscoveredApp] = []

        for root in roots {
            for app in scan(root: root) {
                guard !seenBundleIDs.contains(app.bundleID) else { continue }
                seenBundleIDs.insert(app.bundleID)
                results.append(app)
            }
        }

        results.sort {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
        AppLogger.discovery.info("Discovered \(results.count, privacy: .public) apps")
        return results
    }

    private static func scan(root: URL) -> [DiscoveredApp] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            AppLogger.discovery.debug("Skipping missing root \(root.path, privacy: .public)")
            return []
        }

        guard
            let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [
                    .isApplicationKey,
                    .isDirectoryKey,
                    .isPackageKey,
                    .localizedNameKey,
                ],
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            )
        else {
            return []
        }

        var found: [DiscoveredApp] = []

        for case let url as URL in enumerator {
            let depth = relativeDepth(of: url, below: root)
            if depth > maxDepthBelowRoot {
                enumerator.skipDescendants()
                continue
            }

            guard url.pathExtension == "app" else { continue }
            guard let app = makeApp(from: url) else { continue }
            found.append(app)
        }

        return found
    }

    /// Number of path components of `url` below `root` (DISC-03).
    private static func relativeDepth(of url: URL, below root: URL) -> Int {
        let rootCount = root.standardizedFileURL.pathComponents.count
        let urlCount = url.standardizedFileURL.pathComponents.count
        return max(0, urlCount - rootCount)
    }

    private static func makeApp(from url: URL) -> DiscoveredApp? {
        guard let values = try? url.resourceValues(forKeys: [.isApplicationKey, .isPackageKey]),
            values.isApplication == true || values.isPackage == true || url.pathExtension == "app"
        else {
            return nil
        }

        if isBackgroundAgent(at: url) {
            return nil
        }

        let bundleID = Bundle(url: url)?.bundleIdentifier ?? pathHashIdentity(for: url)
        let displayName = localizedDisplayName(for: url)
        guard !displayName.isEmpty else { return nil }

        let isFromAppStore = FileManager.default.fileExists(
            atPath: url
                .appendingPathComponent("Contents/_MASReceipt/receipt", isDirectory: false)
                .path
        )

        return DiscoveredApp(
            bundleID: bundleID,
            displayName: displayName,
            url: url,
            isFromAppStore: isFromAppStore
        )
    }

    private static func localizedDisplayName(for url: URL) -> String {
        if let name = try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName,
            !name.isEmpty
        {
            return name
        }
        return url.deletingPathExtension().lastPathComponent
    }

    private static func isBackgroundAgent(at url: URL) -> Bool {
        guard let info = Bundle(url: url)?.infoDictionary else { return false }
        return boolInfoValue(info, key: "LSUIElement")
            || boolInfoValue(info, key: "LSBackgroundOnly")
    }

    private static func boolInfoValue(_ info: [String: Any], key: String) -> Bool {
        if let value = info[key] as? Bool {
            return value
        }
        if let number = info[key] as? NSNumber {
            return number.boolValue
        }
        if let string = info[key] as? String {
            return (string as NSString).boolValue
        }
        return false
    }

    private static func pathHashIdentity(for url: URL) -> String {
        let path = url.resolvingSymlinksInPath().path
        let digest = SHA256.hash(data: Data(path.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "path:\(hex)"
    }
}
