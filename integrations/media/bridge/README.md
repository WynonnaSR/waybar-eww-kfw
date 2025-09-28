# Media profile: bridge

Modern media integration based on [mpris-bridge](https://github.com/WynonnaSR/mpris-bridge).
This profile replaces shell scripts with a small daemon (`mpris-bridged`) and a CLI (`mpris-bridgec`) and wires Waybar/Eww directly to them.

Key benefits:
- Single source of truth: JSON snapshot and event stream in `$XDG_RUNTIME_DIR/mpris-bridge/`
- Reliable controls via CLI (no jq/socat), Pango-safe output for Waybar
- Smart player selection (D‑Bus + optional Hyprland focus), cover art handling

---

## Requirements

- Packages: `playerctl`, `systemd` (for `busctl` user scope), `hyprctl` (optional; Hyprland focus hints)
- Binaries from releases: `mpris-bridged`, `mpris-bridgec` (installed by the script below)

---

## Files in this profile

- `.config/waybar/config.jsonc` — Media module wired to `mpris-bridgec watch`
- `.config/eww/eww.yuck` — Listens to `$XDG_RUNTIME_DIR/mpris-bridge/events.jsonl` and uses CLI for controls
- `.config/systemd/user/mpris-bridged.service` — User service for the daemon
- `.config/mpris-bridge/config.toml.example` — Example daemon config (copied to `~/.config/mpris-bridge/config.toml` if missing)
- `scripts/install-mpris-bridge.sh` — Installer that fetches binaries, installs the unit, and seeds config if absent

These are example configs intended to be symlinked into `~/.config` by the repository switcher script.

---

## Install and switch

1) Install mpris-bridge binaries, unit, and seed config (once):
```bash
bash integrations/media/bridge/scripts/install-mpris-bridge.sh
```

2) Select the bridge profile (from the repo root):
```bash
bash scripts/switch-media.sh bridge
```

This will:
- install/update `~/.config/systemd/user/mpris-bridged.service`
- symlink Waybar/Eww configs into `~/.config`
- enable and start `mpris-bridged`

3) Restart Waybar/Eww (or your session) if needed.

Switch back to legacy:
```bash
bash scripts/switch-media.sh legacy
```

---

## Configure the daemon

- Config path: `~/.config/mpris-bridge/config.toml`
- An example is included here: `.config/mpris-bridge/config.toml.example`. The installer copies it if the real config is missing.
- Apply changes by restarting the service:
```bash
systemctl --user restart mpris-bridged
```

Notes:
- Runtime paths (snapshot, events, socket) live under `$XDG_RUNTIME_DIR/mpris-bridge/`.
- Cover fallback is optional. If you use it, point `default_image` to an existing file (e.g. `~/.config/eww/scripts/cover.png`) or adjust the path in the config.

---

## Verify

- Live label in terminal:
```bash
mpris-bridgec watch --truncate 80 --pango-escape
```

- Event stream:
```bash
tail -f "$XDG_RUNTIME_DIR/mpris-bridge/events.jsonl" | head
```

- Service:
```bash
systemctl --user status mpris-bridged
journalctl --user -u mpris-bridged -e -n 200
```

---

## Troubleshooting

- “Config changes not applied”
  - Run `systemctl --user restart mpris-bridged` (daemon reads config at startup)
- “Nothing shows in Waybar/Eww”
  - Ensure an MPRIS player is running (Spotify, VLC, Firefox YT tab, etc.)
  - Check `systemctl --user status mpris-bridged` and logs
- “Waybar complains about markup”
  - The bridge config already uses `--pango-escape` in `watch`

---

## See also

- Project root overview and profile switcher:
  - `../../../README.md`
- Legacy profile (shell):
  - `../legacy/README.md`
- mpris-bridge code, docs and releases:
  - https://github.com/WynonnaSR/mpris-bridge