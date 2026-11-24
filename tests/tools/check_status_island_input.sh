#!/usr/bin/env bash
set -euo pipefail

# Non-destructive status-island input verification driver.
# Modes are added incrementally; unimplemented modes fail loudly rather than
# pretending to pass. Never runs make clean/install, the daemon, or configs.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

OUT="$ROOT/bin/island-input"
mkdir -p "$OUT"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-27.0.0-Beta.6.app/Contents/Developer}"
export DEVELOPER_DIR

FRAMEWORKS="-framework Carbon -framework Cocoa -framework CoreServices -framework CoreVideo -framework SkyLight -framework QuartzCore"

mode="${1:-}"

run_geometry() {
    xcrun clang tests/tools/status_island_geometry_tests.c \
        -o "$OUT/status_island_geometry_tests" \
        -std=c11 -F/System/Library/PrivateFrameworks \
        -framework CoreGraphics -framework Foundation
    "$OUT/status_island_geometry_tests"
}

run_panels() {
    xcrun clang tests/tools/status_island_panels_tests.m \
        -o "$OUT/status_island_panels_tests" \
        -DTESTS -DPROFILE=1 -std=c11 -fno-objc-arc \
        -mmacosx-version-min=11.0 -arch arm64 -F/System/Library/PrivateFrameworks \
        -framework Carbon -framework Cocoa -framework CoreServices \
        -framework CoreVideo -framework SkyLight -framework QuartzCore \
        -framework CoreGraphics -framework Foundation
    "$OUT/status_island_panels_tests"
}

run_native() {
    xcrun clang tests/tools/status_island_native_tests.m \
        -o "$OUT/status_island_native_tests" \
        -DTESTS -DPROFILE=1 -std=c11 -fno-objc-arc \
        -mmacosx-version-min=11.0 -arch arm64 -F/System/Library/PrivateFrameworks \
        -framework Carbon -framework Cocoa -framework CoreServices \
        -framework CoreVideo -framework SkyLight -framework QuartzCore \
        -framework CoreGraphics -framework Foundation \
        -framework ApplicationServices
    "$OUT/status_island_native_tests"
}

run_regressions() {
    xcrun clang tests/src/tests.m \
        -o "$OUT/tests-regressions" \
        -DTESTS -DPROFILE=1 -F/System/Library/PrivateFrameworks \
        -framework Carbon -framework Cocoa -framework CoreServices \
        -framework CoreVideo -framework SkyLight -framework QuartzCore
    "$OUT/tests-regressions"
    run_geometry
    run_panels
}

run_build() {
    xcrun clang src/manifest.m src/osax/payload_bin.c src/osax/loader_bin.c \
        -std=c11 -Wall -Wextra -g -O0 -fvisibility=hidden \
        -mmacosx-version-min=11.0 -fno-objc-arc -arch arm64 \
        -sectcreate __TEXT __info_plist assets/Info.plist \
        -F/System/Library/PrivateFrameworks \
        -framework Carbon -framework Cocoa -framework CoreServices \
        -framework CoreVideo -framework SkyLight -framework QuartzCore \
        -o "$OUT/yabai"
    "$OUT/yabai" --version
}

case "$mode" in
    --geometry)
        run_geometry
        ;;
    --panels)
        run_panels
        ;;
    --native)
        run_native
        ;;
    --regressions)
        run_regressions
        ;;
    --build)
        run_build
        ;;
    --verify-restored)
        echo "check_status_island_input.sh: mode '$mode' is not implemented yet" >&2
        exit 2
        ;;
    *)
        echo "Usage: $0 [--geometry|--panels|--native|--regressions|--build|--verify-restored]" >&2
        exit 2
        ;;
esac
