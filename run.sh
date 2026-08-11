#!/usr/bin/env bash
#
# Build, relaunch, and log. The only sanctioned build command (ENV-02).
#
#   ./run.sh             build + relaunch
#   ./run.sh --build     build only, don't launch
#   ./run.sh --discover  build, then run binary with --discover (no window)
#
# On failure, the full log is at .build/last-build.log — read it before
# guessing at the cause.

set -uo pipefail

SCHEME="LaunchpadRevived"
CONFIG="Debug"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT/.build"
LOG="$BUILD_DIR/last-build.log"
APP="$BUILD_DIR/Build/Products/$CONFIG/$SCHEME.app"
BINARY="$APP/Contents/MacOS/$SCHEME"

mkdir -p "$BUILD_DIR"

echo "==> Building $SCHEME ($CONFIG)"

if ! xcodebuild \
      -scheme "$SCHEME" \
      -configuration "$CONFIG" \
      -derivedDataPath "$BUILD_DIR" \
      -destination 'platform=macOS' \
      build > "$LOG" 2>&1; then
  echo "==> BUILD FAILED"
  echo
  grep -E "(error|warning):" "$LOG" | head -40
  echo
  echo "==> full log: $LOG"
  exit 1
fi

WARNINGS=$(grep -c "warning:" "$LOG" || true)
echo "==> Build succeeded (${WARNINGS} warnings)"

if [[ "${1:-}" == "--build" ]]; then
  exit 0
fi

if [[ ! -d "$APP" ]]; then
  echo "==> Built, but no app at $APP"
  exit 1
fi

if [[ "${1:-}" == "--discover" ]]; then
  if [[ ! -x "$BINARY" ]]; then
    echo "==> Built, but no binary at $BINARY"
    exit 1
  fi
  echo "==> Running --discover"
  exec "$BINARY" --discover
fi

echo "==> Relaunching"
killall "$SCHEME" 2>/dev/null || true
sleep 0.3
open "$APP"
