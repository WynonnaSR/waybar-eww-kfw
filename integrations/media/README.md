# Media profiles: bridge vs legacy

This repo ships two media integration profiles:
- bridge: uses mpris-bridge (daemon + CLI), no shell wrappers
- legacy: original shell scripts (playerctl, fish, jq, etc.)

Install mpris-bridge binaries (once):
```bash
bash integrations/media/bridge/scripts/install-mpris-bridge.sh
```

Switch profile:
```bash
# bridge (recommended)
bash scripts/switch-media.sh bridge

# legacy
bash scripts/switch-media.sh legacy
```

Notes:
- The switcher symlinks your live configs to the chosen profile:
  - ~/.config/waybar/config.jsonc
  - ~/.config/eww/eww.yuck
- For bridge, the user service `mpris-bridged` is installed/enabled.
- After editing `~/.config/mpris-bridge/config.toml`, apply changes with:
```bash
systemctl --user restart mpris-bridged
```