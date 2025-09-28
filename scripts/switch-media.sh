#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-bridge}"  # bridge | legacy

# Целевые файлы у пользователя
WAYBAR_CFG="${HOME}/.config/waybar/config.jsonc"
EWW_YUCK="${HOME}/.config/eww/eww.yuck"
UNIT_DIR="${HOME}/.config/systemd/user"

# Корень репозитория (из которого запускаем скрипт)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Источники профилей (под твою структуру)
SRC_BRIDGE_WAYBAR="${ROOT}/integrations/media/bridge/.config/waybar/config.jsonc"
SRC_BRIDGE_EWW="${ROOT}/integrations/media/bridge/.config/eww/eww.yuck"
SRC_BRIDGE_UNIT="${ROOT}/integrations/media/bridge/.config/systemd/user/mpris-bridged.service"

SRC_LEGACY_WAYBAR="${ROOT}/integrations/media/legacy/.config/waybar/config.jsonc"
SRC_LEGACY_EWW="${ROOT}/integrations/media/legacy/.config/eww/eww.yuck"

mkdir -p "$(dirname "$WAYBAR_CFG")" "$(dirname "$EWW_YUCK")" "$UNIT_DIR"

case "$MODE" in
  bridge)
    # Ставим/обновляем юнит и включаем сервис
    install -Dm644 "$SRC_BRIDGE_UNIT" "${UNIT_DIR}/mpris-bridged.service"
    systemctl --user daemon-reload
    systemctl --user enable --now mpris-bridged || true
    systemctl --user restart mpris-bridged || true

    # Симлинки конфигов
    ln -sf "$SRC_BRIDGE_WAYBAR" "$WAYBAR_CFG"
    ln -sf "$SRC_BRIDGE_EWW"    "$EWW_YUCK"

    echo "[switch-media] Switched to: bridge"
    ;;

  legacy)
    # Отключаем сервис моста
    systemctl --user disable --now mpris-bridged 2>/dev/null || true

    # Симлинки конфигов
    ln -sf "$SRC_LEGACY_WAYBAR" "$WAYBAR_CFG"
    ln -sf "$SRC_LEGACY_EWW"    "$EWW_YUCK"

    echo "[switch-media] Switched to: legacy"
    ;;

  *)
    echo "Usage: $0 {bridge|legacy}"
    exit 2
    ;;
esac

echo "Note: restart Waybar/Eww if needed."