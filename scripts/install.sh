#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║       Rocket Desktop Install      ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# STEP 0: Install Dependencies
# ============================================================================
echo -e "${CYAN}[*] Checking and installing dependencies...${NC}"

install_deps() {
    local DEPS=(
        # Build tools
        "cmake"
        "extra-cmake-modules"
        "pkg-config"
        "gcc"
        "git"
        
        # Qt6
        "qt6-base"
        "qt6-declarative"
        "qt6-wayland"
        "qt6-svg"
        
        # KDE Frameworks
        "kwindowsystem"
        "kwin"
        "kglobalacceld"
        "krunner"
        
        # System libraries
        "wayland"
        "wayland-protocols"
        "dbus"
        "networkmanager"
        "bluez"
        "pipewire"
        "wireplumber"
        
        # Display manager
        "sddm"
        
        # Qt tools (for qdbus6)
        "qt6-tools"
        
        # Python
        "python-gobject"
        "python"
        
        # Utilities
        "wget"
        "curl"
        "base-devel"
        "yay"
        
        # TUI apps for rocket menu
        "fzf"
        "ripgrep"
        "bat"
        "nano"
        "vim"
        "neovim"
        
        # System info
        "lm_sensors"
        "htop"
        "fastfetch"
        
        # Network
        "network-manager-applet"
        "nm-connection-editor"
        
        # Audio
        "pipewire-audio"
        "pipewire-pulse"
        "pavucontrol"
        "playerctl"
        
        # Bluetooth
        "blueman"
        
        # File manager
        "dolphin"
        "thunar"
        
        # Terminal
        "kitty"
        "alacritty"
        
        # Browser
        "firefox"
        
        # Screenshot
        "grim"
        "slurp"
        "swappy"
        
        # Clipboard
        "wl-clipboard"
        "cliphist"
        
        # Power
        "power-profiles-daemon"
        
        # Appearance
        "kvantum"
        "qt5ct"
        "qt6ct"
        "lxappearance"
        "nwg-look"
        
        # Fonts
        "ttf-font-awesome"
        "ttf-fira-code"
        "ttf-jetbrains-mono"
        "noto-fonts"
        "noto-fonts-emoji"
        
        # Notifications
        "dunst"
        "libnotify"
        
        # Lock screen
        "swaylock"
        "swayidle"
        
        # Wallpaper
        "swaybg"
        
        # App launcher (rofi for rocket-shortcuts, wofi as backup)
        "rofi-wayland"
        "wofi"
        
        # Bar
        "waybar"
    )
    
    local MISSING=()
    
    for dep in "${DEPS[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            MISSING+=("$dep")
        fi
    done
    
    if [ ${#MISSING[@]} -eq 0 ]; then
        echo -e "${GREEN}[OK] All dependencies installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Missing dependencies: ${MISSING[*]}${NC}"
    
    # Try to install
    if sudo pacman -S --needed --noconfirm "${MISSING[@]}"; then
        echo -e "${GREEN}[OK] Dependencies installed${NC}"
        return 0
    else
        local EXIT_CODE=$?
        # Check if it's a network error (exit code 30 = pacman error)
        if [ $EXIT_CODE -eq 30 ] || [ $EXIT_CODE -eq 1 ]; then
            echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
            echo -e "${YELLOW}This could be a network error or package not found.${NC}"
            echo ""
            echo -e "Options:"
            echo -e "  ${CYAN}1${NC} - Retry (check your internet connection)"
            echo -e "  ${CYAN}2${NC} - Skip dependencies (may cause issues later)"
            echo -e "  ${CYAN}3${NC} - Exit"
            echo ""
            read -p "Choose option [1/2/3]: " CHOICE
            
            case $CHOICE in
                1)
                    # Use loop instead of recursion to avoid stack overflow
                    while true; do
                        if sudo pacman -S --needed --noconfirm "${MISSING[@]}"; then
                            echo -e "${GREEN}[OK] Dependencies installed${NC}"
                            break
                        else
                            echo -e "${RED}[ERROR] Retry failed. Check network.${NC}"
                            read -p "Retry again? [y/N]: " RETRY
                            [[ "$RETRY" =~ ^[Yy]$ ]] || { echo -e "${RED}[ERROR] Installation cancelled${NC}"; exit 1; }
                        fi
                    done
                    ;;
                2)
                    echo -e "${YELLOW}[WARN] Skipping dependencies - some features may not work${NC}"
                    return 0
                    ;;
                *)
                    echo -e "${RED}[ERROR] Installation cancelled${NC}"
                    exit 1
                    ;;
            esac
        else
            echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
            exit 1
        fi
    fi
}

install_deps

# ============================================================================
# STEP 1: Install KWin Tiling Script
# ============================================================================
echo -e "${CYAN}[*] Installing KWin tiling script...${NC}"
KWIN_SCRIPTS_DIR="$HOME/.local/share/kwin/scripts"
mkdir -p "$KWIN_SCRIPTS_DIR"
cp -r "$PROJECT_DIR/kwin-scripts/rocket-tiling" "$KWIN_SCRIPTS_DIR/"
echo -e "${GREEN}[OK] Tiling script installed${NC}"

# ============================================================================
# STEP 2: Install KWin Effects
# ============================================================================
echo -e "${CYAN}[*] Installing KWin animation effects...${NC}"
KWIN_EFFECTS_DIR="$HOME/.local/share/kwin/effects"
mkdir -p "$KWIN_EFFECTS_DIR"
cp -r "$PROJECT_DIR/kwin-effects/rocket-animations" "$KWIN_EFFECTS_DIR/"
echo -e "${GREEN}[OK] Animation effects installed${NC}"

# ============================================================================
# STEP 3: Build Qt6 binary
# ============================================================================
echo -e "${CYAN}[*] Building Qt6 components...${NC}"
mkdir -p "$BUILD_DIR"
cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -3
cmake --build "$BUILD_DIR" -j"$(nproc)" 2>&1 | tail -3
echo -e "${GREEN}[OK] Build complete${NC}"

# ============================================================================
# STEP 4: Install binary
# ============================================================================
echo -e "${CYAN}[*] Installing binary...${NC}"
sudo cp "$BUILD_DIR/src/rocket-session-bin" /usr/bin/rocket-session-bin
sudo chmod +x /usr/bin/rocket-session-bin
echo -e "${GREEN}[OK] Binary installed${NC}"

# ============================================================================
# STEP 5: Install session script
# ============================================================================
echo -e "${CYAN}[*] Installing session script...${NC}"
sudo cp "$PROJECT_DIR/scripts/rocket-session" /usr/bin/rocket-session
sudo chmod +x /usr/bin/rocket-session
echo -e "${GREEN}[OK] Session script installed${NC}"

# ============================================================================
# STEP 6: Install TUI scripts
# ============================================================================
echo -e "${CYAN}[*] Installing TUI scripts...${NC}"
sudo cp "$PROJECT_DIR/scripts/rocket-tui-"* /usr/bin/ 2>/dev/null || true
sudo chmod +x /usr/bin/rocket-tui-* 2>/dev/null || true
echo -e "${GREEN}[OK] TUI scripts installed${NC}"

# ============================================================================
# STEP 7: Install rocketctl
# ============================================================================
echo -e "${CYAN}[*] Installing rocketctl...${NC}"
sudo cp "$PROJECT_DIR/scripts/rocketctl" /usr/bin/rocketctl
sudo chmod +x /usr/bin/rocketctl
echo -e "${GREEN}[OK] rocketctl installed${NC}"

# ============================================================================
# STEP 8: Install rocket menu scripts
# ============================================================================
echo -e "${CYAN}[*] Installing rocket menu scripts...${NC}"
for script in rocket-settings rocket-install rocket-remove rocket-update rocket-style rocket-setup rocket-trigger rocket-learn rocket-system rocket-launcher rocket-shortcuts; do
    if [ -f "$PROJECT_DIR/scripts/$script" ]; then
        chmod +x "$PROJECT_DIR/scripts/$script"
        sudo cp "$PROJECT_DIR/scripts/$script" "/usr/bin/$script"
        sudo chmod +x "/usr/bin/$script"
    fi
done
echo -e "${GREEN}[OK] Rocket menu scripts installed${NC}"

# ============================================================================
# STEP 9: Install systemd user services
# ============================================================================
echo -e "${CYAN}[*] Installing systemd user services...${NC}"
mkdir -p "$HOME/.config/systemd/user"
for service in "$PROJECT_DIR/config/systemd/user/"*; do
    if [ -f "$service" ]; then
        cp "$service" "$HOME/.config/systemd/user/"
    fi
done
systemctl --user daemon-reload
for service in "$PROJECT_DIR/config/systemd/user/"*.service "$PROJECT_DIR/config/systemd/user/"*.target; do
    if [ -f "$service" ]; then
        svc_name=$(basename "$service")
        systemctl --user enable "$svc_name" 2>/dev/null || true
    fi
done
echo -e "${GREEN}[OK] Systemd user services installed${NC}"

# ============================================================================
# STEP 10: Install autostart files
# ============================================================================
echo -e "${CYAN}[*] Installing autostart files...${NC}"
mkdir -p "$HOME/.config/autostart"
for desktop in "$PROJECT_DIR/autostart/"*.desktop; do
    if [ -f "$desktop" ]; then
        cp "$desktop" "$HOME/.config/autostart/"
    fi
done
echo -e "${GREEN}[OK] Autostart files installed${NC}"

# ============================================================================
# STEP 11: Install session desktop entry
# ============================================================================
echo -e "${CYAN}[*] Installing session entry...${NC}"
sudo mkdir -p /usr/share/wayland-sessions
sudo cp "$PROJECT_DIR/session/rocket-desktop.desktop" /usr/share/wayland-sessions/
echo -e "${GREEN}[OK] Session entry installed${NC}"

# ============================================================================
# STEP 12: Install default config
# ============================================================================
echo -e "${CYAN}[*] Installing default configuration...${NC}"
mkdir -p "$HOME/.config/rocket"
if [ ! -f "$HOME/.config/rocket/rocket.conf" ]; then
    cp "$PROJECT_DIR/config/default/rocket.conf" "$HOME/.config/rocket/"
fi
if [ ! -f "$HOME/.config/rocket/appearance.conf" ]; then
    cp "$PROJECT_DIR/config/default/appearance.conf" "$HOME/.config/rocket/"
fi
echo -e "${GREEN}[OK] Configuration installed${NC}"

# ============================================================================
# STEP 13: Install wallpaper
# ============================================================================
echo -e "${CYAN}[*] Installing wallpaper...${NC}"
sudo mkdir -p /usr/share/rocket-desktop/wallpapers
sudo cp "$PROJECT_DIR/wallpapers/"* /usr/share/rocket-desktop/wallpapers/ 2>/dev/null || true
# Also copy from hackerman theme if available
if [ -f "$HOME/.local/share/omarchy/themes/hackerman/backgrounds/1-synth-scape.jpg" ]; then
    sudo cp "$HOME/.local/share/omarchy/themes/hackerman/backgrounds/1-synth-scape.jpg" /usr/share/rocket-desktop/wallpapers/
fi
mkdir -p "$HOME/.config/rocket-desktop"
cat > "$HOME/.config/rocket-desktop/wallpaper.json" << 'WALLPAPER'
{
    "imagePath": "/usr/share/rocket-desktop/wallpapers/1-synth-scape.jpg",
    "scalingMode": "fill"
}
WALLPAPER
echo -e "${GREEN}[OK] Wallpaper installed${NC}"

# ============================================================================
# STEP 14: Enable KWin tiling script
# ============================================================================
echo -e "${CYAN}[*] Enabling KWin tiling script...${NC}"
mkdir -p "$HOME/.config"
KWINRC="$HOME/.config/kwinrc"
if [ ! -f "$KWINRC" ]; then
    cat > "$KWINRC" << 'KWINCFG'
[Desktops]
Number=1
Rows=1

[Script-rocket-tiling]
layout=master
gap=8
masterRatio=0.55
masterCount=1
activeBorderColor=#00d4ff
inactiveBorderColor=#333355
noBorder=false
KWINCFG
else
    if ! grep -q "\[Script-rocket-tiling\]" "$KWINRC"; then
        cat >> "$KWINRC" << 'KWINCFG'

[Script-rocket-tiling]
layout=master
gap=8
masterRatio=0.55
masterCount=1
activeBorderColor=#00d4ff
inactiveBorderColor=#333355
noBorder=false
KWINCFG
    fi
    # Enable the tiling script plugin (format: <pluginId>Enabled=true)
    if ! grep -q "rocket-tilingEnabled" "$KWINRC"; then
        if grep -q "\[Plugins\]" "$KWINRC"; then
            sed -i '/\[Plugins\]/a rocket-tilingEnabled=true' "$KWINRC" 2>/dev/null || true
        else
            printf "\n[Plugins]\nrocket-tilingEnabled=true\n" >> "$KWINRC"
        fi
    fi
fi
echo -e "${GREEN}[OK] KWin config updated${NC}"

# ============================================================================
# STEP 15: Configure SDDM Auto-Login
# ============================================================================
echo -e "${CYAN}[*] Configuring SDDM auto-login...${NC}"
SDDM_CONF="/etc/sddm.conf.d/autologin.conf"
CURRENT_USER=$(whoami)

if command -v sddm &> /dev/null; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee "$SDDM_CONF" > /dev/null << SDDMCFG
[Autologin]
User=$CURRENT_USER
Session=rocket-desktop.desktop
SDDMCFG
    echo -e "${GREEN}[OK] SDDM auto-login configured for user: $CURRENT_USER${NC}"
else
    echo -e "${YELLOW}[WARN] SDDM not found - skipping auto-login config${NC}"
    echo -e "${YELLOW}       You can manually select 'Rocket' from your display manager${NC}"
fi

# ============================================================================
# STEP 16: Enable SDDM service
# ============================================================================
echo -e "${CYAN}[*] Enabling SDDM service...${NC}"
if command -v sddm &> /dev/null; then
    sudo systemctl enable sddm
    echo -e "${GREEN}[OK] SDDM enabled${NC}"
else
    echo -e "${YELLOW}[WARN] SDDM not found - cannot enable${NC}"
fi

# ============================================================================
# STEP 17: Add user to input group (for rocket-shortcuts)
# ============================================================================
echo -e "${CYAN}[*] Adding user to input group...${NC}"
sudo usermod -aG input "$CURRENT_USER"
echo -e "${GREEN}[OK] User added to input group${NC}"

# ============================================================================
# STEP 18: Create keybinds reference file
# ============================================================================
echo -e "${CYAN}[*] Creating keybinds reference...${NC}"
mkdir -p "$HOME/.config/rocket"
cat > "$HOME/.config/rocket/keybinds.txt" << 'KEYBINDS'
Rocket Desktop Keybinds
=======================

Window Management:
  Super+W          Close window
  Super+Shift+V    Toggle float
  Super+F          Fullscreen
  Super+H/L        Shrink/Grow master
  Super+J/K        Focus next/prev

Tiling:
  Super+Space      Cycle layout
  Super+Tab        Next workspace
  Super+Shift+Tab  Prev workspace
  Super+1-5        Switch workspace 1-5
  Super+Shift+1-5  Move window to workspace 1-5
  Super+I          Add master
  Super+D          Remove master

Navigation:
  Super+Arrow      Focus direction
  Super+Shift+Arrow Swap windows
  Super+Ctrl+Arrow Move windows

Apps:
  Super+Return     Terminal
  Super+Shift+Return Browser
  Super+Shift+F    File manager
  Super+Shift+N    Editor
  Super+Escape     Launcher (Rocket menu)
  Super+Print      Screenshot
  Super+Comma      Show keybinds

System:
  Super+Shift+E    Power menu
  Super+L          Lock screen
KEYBINDS
echo -e "${GREEN}[OK] Keybinds reference created${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Rocket Desktop installed successfully!   ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
if command -v sddm &> /dev/null; then
    echo -e "  ${GREEN}Auto-login is configured!${NC}"
    echo -e "  After reboot, Rocket will start automatically."
    echo ""
fi
echo -e "  To start manually:"
echo -e "    ${CYAN}1. Log out and select 'Rocket' in your display manager${NC}"
echo -e "    ${CYAN}2. Or run: rocket-session${NC}"
echo ""
echo -e "  Controls:"
echo -e "    ${YELLOW}Super+Escape${NC}   Open Rocket Menu"
echo -e "    ${YELLOW}Super+Return${NC}   Terminal"
echo -e "    ${YELLOW}Super+Space${NC}    Cycle layout"
echo -e "    ${YELLOW}Super+Arrow${NC}    Focus window"
echo -e "    ${YELLOW}Super+Q${NC}        Close window"
echo ""
echo -e "  Config:"
echo -e "    ${YELLOW}~/.config/rocket/${NC}           Rocket config"
echo -e "    ${YELLOW}~/.config/rocket/keybinds.txt${NC}  Keybinds reference"
echo ""
