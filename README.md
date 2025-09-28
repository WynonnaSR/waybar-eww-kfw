# waybar-eww-kfw

Hyprland + Waybar + Eww configuration with two interchangeable media profiles:
- bridge — modern integration using [mpris-bridge](https://github.com/WynonnaSR/mpris-bridge) (recommended)
- legacy — original shell-based setup (compatibility)

This repository keeps both profiles side by side and provides a simple switcher that:
- symlinks the “active” configs into your `~/.config` (Waybar and Eww)
- enables/disables the `mpris-bridged` user service when using the bridge profile

Profiles:
- Bridge profile docs: [integrations/media/bridge/README.md](integrations/media/bridge/README.md)
- Legacy profile docs: [integrations/media/legacy/README.md](integrations/media/legacy/README.md)

Links:
- mpris-bridge (daemon + CLI, docs, releases, examples): [WynonnaSR/mpris-bridge](https://github.com/WynonnaSR/mpris-bridge)

---

## Requirements

General:
- Hyprland, Waybar, Eww

Bridge profile:
- Packages: `playerctl`, `systemd` (for `busctl` user scope), `hyprctl` (for focus hints on Hyprland)
- Binaries installed from mpris-bridge releases: `mpris-bridged`, `mpris-bridgec`
- User unit: `mpris-bridged.service` (provided in this repo, installed by the switcher/installer)

Legacy profile:
- Whatever your shell scripts require (fish/jq/etc.) — see the legacy folder

---

## Quick start (bridge, recommended)

1) Install mpris-bridge (pulls latest release binaries and installs the user unit)
```bash
bash integrations/media/bridge/scripts/install-mpris-bridge.sh
```
This installer also seeds the daemon config if missing:
- If `~/.config/mpris-bridge/config.toml` does not exist, it is created from:
  `integrations/media/bridge/.config/mpris-bridge/config.toml.example`

2) Switch to the bridge profile
```bash
bash scripts/switch-media.sh bridge
```

3) Restart Waybar/Eww (or your session) if needed, then verify:
```bash
mpris-bridgec watch --truncate 80 --pango-escape
tail -f "$XDG_RUNTIME_DIR/mpris-bridge/events.jsonl" | head
```

Config changes (mpris-bridge):
- Edit `~/.config/mpris-bridge/config.toml`
- Apply changes:
```bash
systemctl --user restart mpris-bridged
```

Manual seeding (optional):
```bash
mkdir -p ~/.config/mpris-bridge
cp integrations/media/bridge/.config/mpris-bridge/config.toml.example ~/.config/mpris-bridge/config.toml
systemctl --user restart mpris-bridged
```

Notes:
- mpris-bridge uses `$XDG_RUNTIME_DIR/mpris-bridge/{state.json,events.jsonl,mpris-bridge.sock}`.
- Default cover image path in mpris-bridge can point to `~/.config/eww/scripts/cover.png`. Ensure the file exists or change the path in the mpris-bridge config.

---

## Switch back to legacy

```bash
bash scripts/switch-media.sh legacy
```

This disables the `mpris-bridged` service and symlinks the legacy configs back into `~/.config`.

---

## What’s inside

- integrations/media/bridge/.config/…
  - Waybar media module for bridge (exec uses `mpris-bridgec watch`)
  - Eww media widgets for bridge (listen to `$XDG_RUNTIME_DIR/mpris-bridge/events.jsonl`)
  - User unit: `mpris-bridged.service`
  - Example daemon config: `.config/mpris-bridge/config.toml.example`
- integrations/media/bridge/scripts/install-mpris-bridge.sh
  - One-shot installer that fetches latest mpris-bridge binaries, installs the unit, and seeds config if absent
- integrations/media/legacy/.config/…
  - Original shell-based configuration and scripts
- scripts/switch-media.sh
  - Profile switcher (bridge | legacy) that:
    - installs/updates the user unit for bridge,
    - symlinks active Waybar/Eww configs into `~/.config`,
    - enables/disables `mpris-bridged`

---

## Troubleshooting

- I changed `config.toml` but nothing happened
  - Run: `systemctl --user restart mpris-bridged`
  - `daemon-reload` only affects systemd unit files, not app config

- Waybar shows markup issues on special characters
  - Use `mpris-bridgec watch --pango-escape` (already set in the bridge example)

- No events appear for media
  - Check service: `systemctl --user status mpris-bridged`
  - Logs: `journalctl --user -u mpris-bridged -e -n 200`
  - Ensure `playerctl` is installed and at least one MPRIS-capable player is running

---

## Contributing

- Bridge integration lives here; the daemon/CLI code, issues, and releases live in [WynonnaSR/mpris-bridge](https://github.com/WynonnaSR/mpris-bridge).
- PRs improving the switcher, examples, and profile docs are welcome.

---

## License

- Repository-wide license: see [LICENSE](./LICENSE).