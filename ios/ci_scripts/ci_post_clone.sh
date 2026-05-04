#!/bin/bash
# Xcode Cloud ci_post_clone script.
# Runs immediately after the repo is cloned on Apple's CI servers.
# Use this stage to install tools that must be present before xcodebuild runs.
set -euo pipefail

echo "=== MERIDIAN Xcode Cloud post-clone ==="
echo "CI_XCODE_PROJECT: ${CI_XCODE_PROJECT:-not set}"
echo "CI_WORKSPACE:     ${CI_WORKSPACE:-not set}"
echo "CI_BRANCH:        ${CI_BRANCH:-not set}"
echo "CI_BUILD_NUMBER:  ${CI_BUILD_NUMBER:-not set}"

# ── Install XcodeGen ──────────────────────────────────────────────────────────
# Install here (post-clone) so it is available for the pre-xcodebuild stage.
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen via Homebrew..."
    brew install xcodegen
    echo "XcodeGen installed: $(xcodegen version)"
else
    echo "XcodeGen already present: $(xcodegen version)"
fi

# ── Verify Swift version compatibility ────────────────────────────────────────
echo "Xcode version: $(xcodebuild -version | head -1)"
echo "Swift version: $(swift --version | head -1)"

echo "=== Post-clone complete ==="
