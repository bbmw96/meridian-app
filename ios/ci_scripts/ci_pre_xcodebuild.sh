#!/bin/bash
# Xcode Cloud pre-xcodebuild script.
# Runs immediately before every xcodebuild invocation.
# XcodeGen is installed in ci_post_clone.sh - this script only generates the project.
set -euo pipefail

echo "=== MERIDIAN pre-xcodebuild: generating Xcode project ==="

# ── Verify XcodeGen is available ─────────────────────────────────────────────
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found - installing now (fallback from post-clone)..."
    brew install xcodegen
fi

# ── Generate the Xcode project from project.yml ──────────────────────────────
# SCRIPT_DIR = ios/ci_scripts/  →  IOS_DIR = ios/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"

echo "Working directory: $IOS_DIR"
cd "$IOS_DIR"
xcodegen generate --spec project.yml --project .

echo "=== Project generated successfully ==="
ls -la MERIDIAN.xcodeproj/
