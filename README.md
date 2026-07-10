# Rocket

A modern Wayland desktop environment built on KWin, designed to be lightweight, modular, and visually striking with a cyberpunk neon aesthetic.

## Features

- **KWin Compositor** - Battle-tested Wayland compositor as the foundation
- **Floating Panel** - Cyberpunk-themed taskbar with workspace indicators, clock, system tray
- **Application Launcher** - Fast fuzzy-search launcher (Super key)
- **Notifications** - Desktop notification daemon following freedesktop spec
- **Wallpaper Manager** - Dynamic wallpaper with multiple scaling modes
- **Overview** - Expose all windows (Super+Tab)
- **Settings Panel** - GUI configuration for themes, keybinds, power
- **Power Manager** - Shutdown, reboot, suspend, hibernate
- **Clipboard History** - Searchable clipboard with pin support (Super+V)
- **Screenshot Tool** - Full screen, region, and window capture

## Installation

### Arch Linux / CachyOS

```bash
git clone https://github.com/Rocket-Space/rocket-desktop.git
cd rocket-desktop
./scripts/install.sh
```

The installer will:
1. Detect your Arch-based system
2. Install all required dependencies via pacman
3. Build the project with CMake
4. Install binaries to `/usr/bin/`
5. Set up systemd user services
6. Install the session file for your display manager

### Manual Installation

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
```

## Usage

### From Display Manager

Log out and select **Rocket** from your display manager (SDDM, GDM, etc.)

### From TTY

```bash
rocket-session
```

## Configuration

All configuration is stored in `~/.config/rocket/`:

| File | Description |
|------|-------------|
| `rocket.conf` | General settings, keybinds, panel config |
| `appearance.conf` | Theme, colors, fonts, effects |

## Default Keybinds

| Shortcut | Action |
|----------|--------|
| `Super` | Open Launcher |
| `Super+Tab` | Overview |
| `Super+V` | Clipboard History |
| `Super+Print` | Screenshot (fullscreen) |
| `Super+Shift+Print` | Screenshot (region) |
| `Super+L` | Lock Screen |
| `Super+Shift+E` | Power Menu |
| `Super+1-9` | Switch Workspace |
| `Super+Shift+1-9` | Move Window to Workspace |
| `Super+Q` | Close Window |
| `Super+F` | Maximize Window |

## Architecture

```
┌─────────────────────────────────────┐
│         KWin (compositor)           │
├─────────────────────────────────────┤
│          Rocket Session             │
├──────┬──────┬──────┬──────┬─────────┤
│Panel │Launch│Notif │Wallp │Clipboard│
│  Tray│  er  │      │paper │         │
├──────┴──────┴──────┴──────┴─────────┤
│       DBus IPC Communication        │
├─────────────────────────────────────┤
│systemd │PipeWire│NetMgr│BlueZ│Polkit│
└─────────────────────────────────────┘
```

## Tech Stack

- C++20
- Qt 6 / QML
- KWindowSystem (KF6)
- Wayland
- DBus
- systemd
- PipeWire
- NetworkManager
- BlueZ

## License

MIT License

## Credits

- KWin team for the compositor
- KDE Frameworks for KWindowSystem
- Hyprland for design inspiration
