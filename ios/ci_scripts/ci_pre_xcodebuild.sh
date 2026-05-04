#!/bin/bash
# Xcode Cloud pre-xcodebuild script.
# Runs before every build action. Installs XcodeGen and generates the .xcodeproj
# from ios/project.yml so we never commit a binary project file to git.
set -euo pipefail

echo "=== MERIDIAN Xcode Cloud pre-build ==="
echo "CI_XCODE_PROJECT: ${CI_XCODE_PROJECT:-not set}"
echo "CI_WORKSPACE:     ${CI_WORKSPACE:-not set}"

# ── Install XcodeGen via Homebrew ──────────────────────────────────────────────
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
else
    echo "XcodeGen already installed: $(xcodegen version)"
fi

# ── Generate the Xcode project ─────────────────────────────────────────────────
# CI_WORKSPACE is the directory that contains the ios/ folder
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"   # ios/ is one level above ci_scripts/

echo "Generating MERIDIAN.xcodeproj from project.yml..."
cd "$IOS_DIR"
xcodegen generate --spec project.yml --project .

echo "=== Project generated successfully ==="
ls -la MERIDIAN.xcodeproj/
