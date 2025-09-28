#!/usr/bin/env bash
set -euo pipefail

# Unified installer for legacy | bridge modes
# Usage:
#   bash scripts/install-media.sh legacy
#   bash scripts/install-media.sh bridge

MODE="${1:-bridge}"  # bridge | legacy

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Target user locations
CFG_DIR="${HOME}/.config"
WAYBAR_DIR="${CFG_DIR}/waybar"
EWW_DIR="${CFG_DIR}/eww"
HYPR_DIR="${CFG_DIR}/hypr"
UNIT_DIR="${CFG_DIR}/systemd/user"
BIN_DIR="${HOME}/.local/bin"
MB_CFG_DIR="${CFG_DIR}/mpris-bridge"
MB_CFG_FILE="${MB_CFG_DIR}/config.toml"

# Source trees
LEGACY_ROOT="${ROOT}/integrations/media/legacy"
BRIDGE_ROOT="${ROOT}/integrations/media/bridge"

## Helpers
ensure_dirs() {
  mkdir -p "${WAYBAR_DIR}" "${WAYBAR_DIR}/scripts" \
           "${EWW_DIR}" "${EWW_DIR}/scripts" \
           "${UNIT_DIR}" "${BIN_DIR}" "${MB_CFG_DIR}"
}

# Copy directory contents (not the directory itself) into dst
copy_dir() {
  # copy_dir <src_dir> <dst_dir>
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    # Copy contents of src into dst (no --delete to avoid removing user's files)
    rsync -a "$src"/ "$dst"/ 2>/dev/null || true
  else
    # emulate minimal rsync -a (no delete)
    cp -a "$src"/. "$dst"/ || true
  fi
}

# Copy directory contents with excludes (patterns are relative names)
copy_dir_exclude() {
  # copy_dir_exclude <src_dir> <dst_dir> <exclude1> [<exclude2> ...]
  local src="$1" dst="$2"; shift 2
  local excludes=("$@")
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    local args=(-a)
    for p in "${excludes[@]}"; do
      args+=(--exclude="$p")
    done
    rsync "${args[@]}" "$src"/ "$dst"/ 2>/dev/null || true
  else
    cp -a "$src"/. "$dst"/ || true
    # remove excluded after copy
    for p in "${excludes[@]}"; do
      rm -f "$dst/$p" || true
    done
  fi
}

# Helper: chmod +x if file exists
mark_exec() {
  for f in "$@"; do
    if [ -f "$f" ]; then chmod +x "$f" || true; fi
  done
}

# Helper: recursively mark executables in a directory (files only, depth 1)
mark_exec_in_dir() {
  local d="$1"
  [ -d "$d" ] || return 0
  # shellcheck disable=SC2045
  for f in $(ls -1 "$d" 2>/dev/null || true); do
    if [ -f "$d/$f" ]; then chmod +x "$d/$f" || true; fi
  done
}

case "${MODE}" in
  legacy)
    echo "[install-media] Mode: legacy"
    ensure_dirs

    # 1) Copy legacy configs and scripts (overwrite allowed). Exclude hyprland.conf.
    # Waybar
    cp -f "${LEGACY_ROOT}/.config/waybar/config.jsonc" "${WAYBAR_DIR}/config.jsonc"
    [ -f "${LEGACY_ROOT}/.config/waybar/style.css" ] && cp -f "${LEGACY_ROOT}/.config/waybar/style.css" "${WAYBAR_DIR}/style.css"
    [ -d "${LEGACY_ROOT}/.config/waybar/img" ] && copy_dir "${LEGACY_ROOT}/.config/waybar/img" "${WAYBAR_DIR}/img"
    # Waybar scripts (e.g., weather.fish)
    if [ -d "${LEGACY_ROOT}/.config/waybar/scripts" ]; then
      copy_dir "${LEGACY_ROOT}/.config/waybar/scripts" "${WAYBAR_DIR}/scripts"
      mark_exec_in_dir "${WAYBAR_DIR}/scripts"
    fi

    # Eww
    cp -f "${LEGACY_ROOT}/.config/eww/eww.yuck" "${EWW_DIR}/eww.yuck"
    [ -f "${LEGACY_ROOT}/.config/eww/eww.scss" ] && cp -f "${LEGACY_ROOT}/.config/eww/eww.scss" "${EWW_DIR}/eww.scss"
    [ -f "${LEGACY_ROOT}/.config/eww/image.jpg" ] && cp -f "${LEGACY_ROOT}/.config/eww/image.jpg" "${EWW_DIR}/image.jpg"
    [ -f "${LEGACY_ROOT}/.config/eww/user.jpg" ] && cp -f "${LEGACY_ROOT}/.config/eww/user.jpg" "${EWW_DIR}/user.jpg"
    if [ -d "${LEGACY_ROOT}/.config/eww/scripts" ]; then
      copy_dir "${LEGACY_ROOT}/.config/eww/scripts" "${EWW_DIR}/scripts"
      mark_exec_in_dir "${EWW_DIR}/scripts"
    fi

    # Hyprland: do not copy hyprland.conf automatically; notify user
    echo "[install-media] Skipped Hyprland config. Please review and copy from ${LEGACY_ROOT}/.config/hypr/ if desired."

    # .local/bin tools
    if [ -d "${LEGACY_ROOT}/.local/bin" ]; then
      copy_dir "${LEGACY_ROOT}/.local/bin" "${BIN_DIR}"
      mark_exec_in_dir "${BIN_DIR}"
    fi

    # 3) Ensure mpris-bridged is disabled for legacy flow.
    systemctl --user disable --now mpris-bridged 2>/dev/null || true
    echo "[install-media] Legacy install complete. Restart Waybar/Eww if needed."
    ;;

  bridge)
    echo "[install-media] Mode: bridge"
    ensure_dirs

    # 1) Remove deprecated scripts whose functionality is replaced by mpris-bridge
    for f in "${BIN_DIR}/pmusic_poll.fish" "${BIN_DIR}/mediactl.fish" "${BIN_DIR}/select_player.fish"; do
      [ -f "$f" ] && rm -f "$f" && echo "Removed obsolete: $f" || true
    done
    # Also remove eww legacy media poller if present
    [ -f "${EWW_DIR}/scripts/pmusic_poll.fish" ] && rm -f "${EWW_DIR}/scripts/pmusic_poll.fish" || true

    # 2) Copy legacy assets similarly to legacy mode, but exclude deprecated scripts
    # Waybar base files and scripts (weather.fish etc.)
    [ -f "${LEGACY_ROOT}/.config/waybar/style.css" ] && cp -f "${LEGACY_ROOT}/.config/waybar/style.css" "${WAYBAR_DIR}/style.css"
    [ -d "${LEGACY_ROOT}/.config/waybar/img" ] && copy_dir "${LEGACY_ROOT}/.config/waybar/img" "${WAYBAR_DIR}/img"
    if [ -d "${LEGACY_ROOT}/.config/waybar/scripts" ]; then
      copy_dir "${LEGACY_ROOT}/.config/waybar/scripts" "${WAYBAR_DIR}/scripts"
      mark_exec_in_dir "${WAYBAR_DIR}/scripts"
    fi

    # Eww supporting files
    [ -f "${LEGACY_ROOT}/.config/eww/eww.scss" ] && cp -f "${LEGACY_ROOT}/.config/eww/eww.scss" "${EWW_DIR}/eww.scss"
    [ -f "${LEGACY_ROOT}/.config/eww/image.jpg" ] && cp -f "${LEGACY_ROOT}/.config/eww/image.jpg" "${EWW_DIR}/image.jpg"
    [ -f "${LEGACY_ROOT}/.config/eww/user.jpg" ] && cp -f "${LEGACY_ROOT}/.config/eww/user.jpg" "${EWW_DIR}/user.jpg"
    if [ -d "${LEGACY_ROOT}/.config/eww/scripts" ]; then
      # Exclude only pmusic_poll.fish from eww/scripts
      copy_dir_exclude "${LEGACY_ROOT}/.config/eww/scripts" "${EWW_DIR}/scripts" "pmusic_poll.fish"
      mark_exec_in_dir "${EWW_DIR}/scripts"
    fi

    # .local/bin: copy but exclude deprecated scripts
    if [ -d "${LEGACY_ROOT}/.local/bin" ]; then
      copy_dir_exclude "${LEGACY_ROOT}/.local/bin" "${BIN_DIR}" "pmusic_poll.fish" "mediactl.fish" "select_player.fish"
      mark_exec_in_dir "${BIN_DIR}"
    fi

    # Double-check removal in case excluded files slipped in by other means
    for f in "${BIN_DIR}/pmusic_poll.fish" "${BIN_DIR}/mediactl.fish" "${BIN_DIR}/select_player.fish" \
             "${EWW_DIR}/scripts/pmusic_poll.fish"; do
      [ -f "$f" ] && rm -f "$f" || true
    done

    # 3) Copy bridge-integrated configs with overwrite
    cp -f "${BRIDGE_ROOT}/.config/waybar/config.jsonc" "${WAYBAR_DIR}/config.jsonc"
    cp -f "${BRIDGE_ROOT}/.config/eww/eww.yuck" "${EWW_DIR}/eww.yuck"

    # 4) Seed mpris-bridge config if missing
    if [ ! -f "${MB_CFG_FILE}" ]; then
      cp -f "${BRIDGE_ROOT}/.config/mpris-bridge/config.toml.example" "${MB_CFG_FILE}" || true
      echo "[install-media] Seeded ${MB_CFG_FILE} from bridge example."
    fi

    # 5) Install mpris-bridge via dedicated script
    "${ROOT}/integrations/media/bridge/scripts/install-mpris-bridge.sh" || {
      echo "[install-media] ERROR: mpris-bridge install failed."
      echo "→ Try running scripts/install-mpris-bridge.sh manually."
      exit 1
    }

    # 6) Ensure service is enabled and running
    systemctl --user daemon-reload
    systemctl --user enable --now mpris-bridged || true
    systemctl --user restart mpris-bridged || true

    echo "[install-media] Bridge install complete. Edit ${MB_CFG_FILE} if needed and restart service."
    ;;

  *)
    echo "Usage: $0 {bridge|legacy}"
    exit 2
    ;;
esac