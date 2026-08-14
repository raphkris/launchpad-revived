# Launchpad Revived

macOS 26 (Tahoe) reimplementation of Launchpad. AppKit shell (`NSApplicationDelegate` +
borderless `NSWindow`) hosting SwiftUI content via `NSHostingView`, using system Liquid Glass APIs.

- Requirements spec: `docs/spec/260730.01.md` (source of truth; implement `[D]` only).
- Working rules: `.cursor/rules/00-project.mdc`.
- Sanctioned build command: `./run.sh --build` (wraps `xcodebuild`). Never run bare `./run.sh` or launch the app yourself.

## Cursor Cloud specific instructions

### Platform reality: this is a macOS-only app; it cannot be built or run on the Linux Cloud VM

- The Cloud Agent VM is Linux x86_64. This app targets **macOS 26.0** and depends on Apple-only
  frameworks (`AppKit`, `SwiftUI`, Liquid Glass, `CryptoKit`, `OSLog`). The only sanctioned build is
  `xcodebuild` via `./run.sh`, which does not exist on Linux.
- Therefore **build, run, and any compile/test of the app are impossible on this VM.** They require
  a macOS Tahoe machine with Xcode 26.4+ (see `ENV-01`). Do not attempt `./run.sh` here — it will
  fail at `xcodebuild`, not because of a fixable env issue.
- Never launch the built app anywhere except on a developer's Mac while present: `WIN-03` hides the
  menu bar and Dock system-wide.

### What IS runnable on Linux: `swift-format` (lint/format, PRJ-03)

- The startup update script installs the Swift 6.2.1 toolchain to `/opt/swift` and symlinks
  `swift`, `swiftc`, `swift-format` into `/usr/local/bin`. This is the toolchain's bundled
  `swift-format`; it is syntactic and works on the source without needing Apple frameworks.
- Lint with the committed config:
  `swift-format lint --strict --recursive --configuration .swift-format LaunchpadRevived`
- Format in place before finishing (per the project rules):
  `swift-format format --in-place --recursive --configuration .swift-format LaunchpadRevived`
- Gotcha: `swift-format` output can differ slightly between toolchain versions. The Linux 6.2.1
  build flags one cosmetic `[AddLines]` break in `AppDiscovery.swift` that the repo's macOS
  toolchain did not. Do not "fix" cosmetic version-drift findings unless the diff is on code you
  actually changed — match whatever Xcode's bundled `swift-format` produces on the Mac.
- The toolchain install is best-effort and guarded (`command -v swift-format`); if the download ever
  fails, the VM still boots but `swift-format` will be unavailable until it succeeds.
