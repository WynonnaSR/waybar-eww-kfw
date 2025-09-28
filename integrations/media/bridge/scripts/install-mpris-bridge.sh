#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-WynonnaSR/mpris-bridge}"

# 1) Install latest binaries + unit from the mpris-bridge repo
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required." >&2
  exit 1
fi
curl -sSL "https://raw.githubusercontent.com/${REPO}/main/scripts/install-from-release.sh" | bash -s -- "${REPO}"

# 2) Ensure user config exists; if not, seed from example in this repo
CFG_DIR="${HOME}/.config/mpris-bridge"
CFG_FILE="${CFG_DIR}/config.toml"
EXAMPLE_REL="integrations/media/bridge/.config/mpris-bridge/config.toml.example"

mkdir -p "${CFG_DIR}"

if [ ! -f "${CFG_FILE}" ]; then
  if [ -f "${EXAMPLE_REL}" ]; then
    cp -n "${EXAMPLE_REL}" "${CFG_FILE}"
    echo "[install-mpris-bridge] Seeded ${CFG_FILE} from example."
  else
    echo "[install-mpris-bridge] Warning: example config not found at ${EXAMPLE_REL}. Create ${CFG_FILE} manually."
  fi
else
  echo "[install-mpris-bridge] ${CFG_FILE} already exists; not overwriting."
fi

# 3) Start/Restart the service to be safe
systemctl --user daemon-reload
systemctl --user enable --now mpris-bridged
systemctl --user restart mpris-bridged || true

echo "[install-mpris-bridge] Done. Edit ${CFG_FILE} and run: systemctl --user restart mpris-bridged"