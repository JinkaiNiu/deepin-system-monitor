#!/usr/bin/env bash
# Automated deb build for deepin-system-monitor with issue #585 fix (PR #740)
# Runs as devcontainer postCreateCommand inside GitHub Codespaces.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
LOG="$REPO_DIR/../build.log"

{
echo "=== [1/5] Environment ==="
date -u
echo "CPUs: $(nproc) | OS: $(grep PRETTY_NAME /etc/os-release)"

echo "=== [2/5] Switching apt sources to deepin crimson (same as Deepin 25) ==="
sudo rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true
echo "deb [trusted=yes] https://community-packages.deepin.com/beige/ crimson main commercial community" | sudo tee /etc/apt/sources.list
sudo apt-get update -o Acquire::Retries=3

echo "=== [3/5] Installing build dependencies from deepin crimson ==="
sudo apt-get install -y --no-install-recommends devscripts fakeroot libdistro-info-perl
sudo apt-get build-dep -y .

echo "=== [4/5] Bumping version and building binary packages ==="
export DEBEMAIL="niujinkai1997@qq.com"
export DEBFULLNAME="JinkaiNiu"
if ! head -n 6 debian/changelog | grep -q "6.5.49+fix585"; then
  dch -v 6.5.49+fix585 -D unstable --force-distribution "Local build: display network speed and traffic in byte units (fixes #585, PR #740)"
fi
dpkg-buildpackage -us -uc -b -j"$(nproc)"

echo "=== [5/5] Uploading artifacts as a GitHub release ==="
ls -la "$REPO_DIR"/../
if command -v gh >/dev/null 2>&1; then
  gh release create deb-fix585-6.5.49 --repo JinkaiNiu/deepin-system-monitor \
    --target "$(git rev-parse --abbrev-ref HEAD)" \
    --title "deb 6.5.49+fix585 (network byte-unit fix for #585)" \
    --notes "Local build of deepin-system-monitor with issue #585 fix (PR #740). Version 6.5.49+fix585, built on Debian bookworm against deepin crimson packages. For local installation on Deepin 25 (crimson)." \
    "$REPO_DIR"/../deepin-system-monitor_*.deb
  echo "RELEASE_OK"
else
  echo "gh CLI not available. Built .deb files are in $REPO_DIR/../ - download them from the VS Code explorer, or run: python3 -m http.server 8000"
fi
echo "BUILD_DONE"
} 2>&1 | tee "$LOG"
