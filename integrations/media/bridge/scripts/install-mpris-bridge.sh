#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-WynonnaSR/mpris-bridge}"

# 1) Install latest binaries via upstream installer
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required." >&2
  exit 1
fi
curl -sSL "https://raw.githubusercontent.com/${REPO}/main/scripts/install-from-release.sh" | bash -s -- "${REPO}"


# 3) Start/Restart the service to be safe
systemctl --user daemon-reload
systemctl --user enable --now mpris-bridged
systemctl --user restart mpris-bridged || true
