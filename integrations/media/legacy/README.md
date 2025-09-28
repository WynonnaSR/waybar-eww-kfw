[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

Note: This setup is based on and slightly modified from Maxi-gasti’s repo:
https://github.com/Maxi-gasti/My-Linux-Rice-hypr-waybar-eww — big thanks to them for the great Waybar and EWW widget!

Use at your own risk: configs and scripts are provided as-is without warranties.

# Hyprland + Waybar + EWW (Kitty/Fish/Wofi)

Opinionated Wayland setup powered by Hyprland, Waybar, and EWW. It includes media widgets, system monitoring, wallpaper controls, and a few handy scripts written for Fish shell.

- **Waybar preview**:
  <br><img width="1600" height="45" alt="Waybar" src="https://github.com/user-attachments/assets/aaf18d67-04f7-4b0c-902f-b0706a1c43cf" />
- **EWW preview**:
  <br><img width="263" height="483" alt="EWW" style="margin: auto" src="https://github.com/user-attachments/assets/05f63f10-26fa-43c7-9d05-40c350380b22" />

Demo video: https://youtu.be/96BC5EuXEQc?si=sCzbWejNkBqxM-xl

## About

This is a tailored setup for:
- **Kitty** (terminal)
- **Fish** (shell)
- **Wofi** (launcher)
- **Hyprland** (Wayland compositor)
- **Waybar** and **EWW** widgets
- **swww**-based wallpapers with helpers (`wall`, `wall_path`)

## Highlights

- **Waybar**: Workspace switcher, hardware monitors (CPU, RAM, temp), media controls, weather, system tray, and a menu toggle for EWW.
- **EWW “Services” window**: CPU/RAM/Disk usage, music panel (artwork, title, artist, progress), service buttons (dhcpcd, XAMPP on/off), and wallpaper selection grid.
- **Wallpapers**: 8 presets (`001`–`008`) switched via hotkeys (`SUPER + CTRL + 1..8`) or EWW buttons, with animated transitions via `swww`.
- **Fish scripts**: Media control, wallpaper management, and weather fetching.
- **Default apps**: Kitty (terminal), Wofi (launcher), Firefox, Discord, Steam, Neovim.

## Folder Layout

- `~/.config/hypr/` – Hyprland config (`hyprland.conf`)
- `~/.config/waybar/` – Waybar config (`config.jsonc`, `style.css`, icons, scripts)
- `~/.config/eww/` – EWW config (`eww.yuck`, `eww.scss`, scripts, assets)
- `~/.local/bin/` – Helper scripts (Fish and Bash) for media, wallpapers, and services

## Dependencies

Core (Arch official repos):
- `fish`, `hyprland`, `xdg-desktop-portal-hyprland`, `waybar`
- `wofi` (launcher), `kitty` (terminal)
- `swww` (wallpaper daemon)
- `pipewire`, `pipewire-pulse`, `pavucontrol` (audio)
- `playerctl` (MPRIS), `jq` (JSON parsing), `curl` (HTTP), `busctl` (player capabilities)
- `wl-clipboard`, `grim`, `slurp`, `swappy` (screenshots)
- `dhcpcd` (optional for network service button), `upower` (battery)
- `noto-fonts`, `noto-fonts-emoji`, `ttf-nerd-fonts-symbols`, `ttf-nerd-fonts-symbols-mono` (fonts/icons)

One-liner install (Arch):
```bash
sudo pacman -S --needed fish hyprland xdg-desktop-portal-hyprland waybar wofi swww \
    kitty neovim fastfetch pipewire pipewire-pulse pavucontrol playerctl jq curl \
    wl-clipboard grim slurp swappy dhcpcd upower \
    noto-fonts noto-fonts-emoji ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono
```

EWW (AUR):
```bash
yay -S eww
```
*Note*: On some systems, the package may be `eww-wayland`. Use the appropriate package for your Wayland setup.

Optional:
- `lxqt-policykit` or `polkit-gnome` (for `pkexec`)
- `firefox`, `discord`, `steam` (optional apps for Waybar buttons)

## Install

1. **Place configs**:
   Copy the repository contents to:
   - `~/.config/hypr`
   - `~/.config/waybar`
   - `~/.config/eww`
   - `~/.local/bin`

2. **Make scripts executable**:
   ```bash
   chmod +x ~/.local/bin/* ~/.config/waybar/scripts/* ~/.config/eww/scripts/*
   ```

3. **Start Hyprland**:
   Waybar and EWW daemon autostart via `hyprland.conf` (`exec-once = waybar` and `exec-once = eww -c $HOME/.config/eww daemon`).

4. **Initialize swww**:
   Included in `hyprland.conf` (`exec-once = swww init`). The `wall` script also ensures `swww-daemon` runs if needed.

## Wallpapers: `wall` and `wall_path`

Wallpapers are stored in `~/Pictures/wallpapers/quick` (override via `WALL_DIR` environment variable). Expected names: `001`–`008` with extensions `jpg`, `jpeg`, `png`, `webp`, `avif`, or `bmp` (case-insensitive).

- **`wall`**: Sets wallpaper by index (`1`–`8` or `001`–`008`) with `swww`. Defaults to `--transition-type grow` and a random corner position (`top-left`, `top-right`, `bottom-left`, `bottom-right`) unless custom transitions are provided.
  ```bash
  # Basic usage
  wall 1           # Sets 001.* from WALL_DIR
  wall 003         # Sets 003.* from WALL_DIR

  # Custom transitions
  wall 004 --transition-type wipe --transition-pos center
  ```

- **`wall_path`**: Resolves absolute file path for a wallpaper index for EWW previews.
  ```bash
  wall_path 005    # Outputs: /home/orcaex/Pictures/wallpapers/quick/005.png
  ```

- **Hotkeys** (`hyprland.conf`): `SUPER + CTRL + 1..8` → `~/.local/bin/wall 001..008`
- **EWW integration** (`eww.yuck`): Background grid buttons call `wall 001..008` with live previews via `wall_path`.

### Transition Examples (swww)
```bash
# Fade
wall 003 --transition-type simple --transition-fps 60 --transition-step 2
# Grow from center
wall 004 --transition-type center --transition-fps 60 --transition-step 90
# Edges to center
wall 005 --transition-type outer --transition-fps 60 --transition-step 90
# Angled wipe
wall 006 --transition-type wipe --transition-angle 30 --transition-fps 60 --transition-step 90
# Top-to-bottom slide
wall 007 --transition-type top --transition-fps 60 --transition-step 90
# Random transition
wall 002 --transition-type random --transition-fps 60 --transition-step 90
```
See `man swww-img` for full options.

- https://man.archlinux.org/man/swww-img.1.en

## Configuration You'll Likely Change

1. **Wallpapers**:
   - Place 8 images named `001`–`008` in `~/Pictures/wallpapers/quick` (or set `WALL_DIR`).
   - Hotkeys: `SUPER + CTRL + 1..8` in `hyprland.conf`.
   - EWW “Backgrounds” grid uses `wall` and `wall_path` for dynamic previews.

2. **Weather** (`waybar/scripts/weather.fish`):
   - Uses `wttr.in` for Tashkent (`CITY="Tashkent_Uzbekistan"`). Edit `CITY` for your location.
   - Example: `curl -s "wttr.in/$CITY?format=%c+%t&lang=ru"` for localized output.
   - Configured in `waybar/config.jsonc` (`custom/weather`).

3. **Terminal & Launcher**:
   - Terminal: `kitty` (edit `hyprland.conf` and `waybar/config.jsonc` for alternatives).
   - Launcher: `wofi --show drun`.

4. **Media & Audio**:
   - **EWW music panel**: Uses `playerctl`, `jq`, `curl`, `busctl` for metadata, artwork, and controls (`pmusic_poll.fish`, `mediactl.fish`, `select_player.fish`).
   - **Waybar media**: Uses `playerctl` for artist/title and controls.
   - Audio: `pipewire`, `pipewire-pulse`, `pavucontrol` for volume control.

5. **EWW Services** (`eww.yuck`):
   - System monitors: CPU, RAM, disk usage.
   - Service buttons: `dhcpcd` (network restart), XAMPP start/stop (optional).
   - Wallpaper grid: 8 buttons for `wall 001..008`.

6. **Fonts & Icons**:
   - Requires `ttf-nerd-fonts-symbols` and `noto-fonts` for icons in Waybar and EWW.

## Waybar Notes

- **Image path**: Use absolute path in `waybar/config.jsonc`:
  ```jsonc
  "image": {
    "path": "/home/orcaex/.config/waybar/img/arch.png",
    ...
  }
  ```
- **Window title**: `hyprland/window` shows active window title (max 40 characters).

## EWW Notes

- **Music panel**: Displays artwork (`image.jpg` or `cover.png`), title, artist, and progress slider.
- **Service buttons**: Use `pkexec` for `dhcpcd` and XAMPP commands.
- **Background previews**: Use `wall_path` for dynamic wallpaper thumbnails.

## Tips & Troubleshooting

- **Missing icons?** Ensure `ttf-nerd-fonts-symbols` and `noto-fonts` are installed.
- **No audio?** Verify `pipewire` and `pipewire-pulse` are running; check `pavucontrol`.
- **Weather empty?** Check internet and `CITY` in `weather.fish`.
- **Media not showing?** Use MPRIS-compatible players (e.g., Firefox, Spotify, VLC); run `playerctl status`.
- **Wofi not launching?** Ensure `wofi` is installed and Wayland session is active.
- **Wallpaper errors?** Ensure `001`–`008` exist in `WALL_DIR` with supported extensions.
- **Hyprland window empty?** App may not set title, or Waybar’s Hyprland module may need updating.
- **EWW logs**: Check with `eww -c ~/.config/eww logs` for errors.
- **Dependencies check**: Run `which playerctl jq curl swww hyprctl busctl grim slurp wl-copy swappy wpctl brightnessctl`.

## License

MIT — see [LICENSE](./LICENSE).