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

# 1. Install KWin Tiling Script
echo -e "${CYAN}[*] Installing KWin tiling script...${NC}"
KWIN_SCRIPTS_DIR="$HOME/.local/share/kwin/scripts"
mkdir -p "$KWIN_SCRIPTS_DIR"
cp -r "$PROJECT_DIR/kwin-scripts/rocket-tiling" "$KWIN_SCRIPTS_DIR/"
echo -e "${GREEN}[OK] Tiling script installed${NC}"

# 2. Install KWin Effects
echo -e "${CYAN}[*] Installing KWin animation effects...${NC}"
KWIN_EFFECTS_DIR="$HOME/.local/share/kwin/effects"
mkdir -p "$KWIN_EFFECTS_DIR"
cp -r "$PROJECT_DIR/kwin-effects/rocket-animations" "$KWIN_EFFECTS_DIR/"
echo -e "${GREEN}[OK] Animation effects installed${NC}"

# 3. Build Qt6 binary
echo -e "${CYAN}[*] Building Qt6 components...${NC}"
mkdir -p "$BUILD_DIR"
cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -3
cmake --build "$BUILD_DIR" -j"$(nproc)" 2>&1 | tail -3
echo -e "${GREEN}[OK] Build complete${NC}"

# 4. Install binary
echo -e "${CYAN}[*] Installing binary...${NC}"
sudo cp "$BUILD_DIR/src/rocket-session-bin" /usr/bin/rocket-session-bin
sudo chmod +x /usr/bin/rocket-session-bin
echo -e "${GREEN}[OK] Binary installed${NC}"

# 5. Install session script
echo -e "${CYAN}[*] Installing session script...${NC}"
sudo cp "$PROJECT_DIR/scripts/session.sh" /usr/bin/rocket-session
sudo chmod +x /usr/bin/rocket-session
echo -e "${GREEN}[OK] Session script installed${NC}"

# 6. Install rocketctl
echo -e "${CYAN}[*] Installing rocketctl...${NC}"
sudo cp "$PROJECT_DIR/scripts/rocketctl" /usr/bin/rocketctl
sudo chmod +x /usr/bin/rocketctl
echo -e "${GREEN}[OK] rocketctl installed${NC}"

# 7. Install session desktop entry
echo -e "${CYAN}[*] Installing session entry...${NC}"
sudo mkdir -p /usr/share/wayland-sessions
sudo cp "$PROJECT_DIR/session/rocket-desktop.desktop" /usr/share/wayland-sessions/
echo -e "${GREEN}[OK] Session entry installed${NC}"

# 8. Install default config
echo -e "${CYAN}[*] Installing default configuration...${NC}"
mkdir -p "$HOME/.config/rocket"
if [ ! -f "$HOME/.config/rocket/rocket.conf" ]; then
    cp "$PROJECT_DIR/config/default/rocket.conf" "$HOME/.config/rocket/"
fi
if [ ! -f "$HOME/.config/rocket/appearance.conf" ]; then
    cp "$PROJECT_DIR/config/default/appearance.conf" "$HOME/.config/rocket/"
fi
echo -e "${GREEN}[OK] Configuration installed${NC}"

# 9. Install wallpaper
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

# 10. Enable KWin tiling script
echo -e "${CYAN}[*] Enabling KWin tiling script...${NC}"
mkdir -p "$HOME/.config"
KWINRC="$HOME/.config/kwinrc"
if [ ! -f "$KWINRC" ]; then
    cat > "$KWINRC" << 'KWINCFG'
[Desktops]
Number=1
Rows=1

[Tiling]
padding=8

[RocketTiling]
layout=master
gap=8
masterRatio=0.55
masterCount=1
activeBorderColor=#00d4ff
inactiveBorderColor=#333355
noBorder=false
KWINCFG
else
    if ! grep -q "\[RocketTiling\]" "$KWINRC"; then
        cat >> "$KWINRC" << 'KWINCFG'

[RocketTiling]
layout=master
gap=8
masterRatio=0.55
masterCount=1
activeBorderColor=#00d4ff
inactiveBorderColor=#333355
noBorder=false
KWINCFG
    fi
fi
echo -e "${GREEN}[OK] KWin config updated${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Rocket Desktop installed successfully!   ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo -e "  To start:"
echo -e "    ${CYAN}1. Log out and select 'Rocket' in SDDM${NC}"
echo -e "    ${CYAN}2. Or run: rocket-session${NC}"
echo ""
echo -e "  Controls:"
echo -e "    ${YELLOW}Meta+T${NC}       Cycle layout"
echo -e "    ${YELLOW}Meta+H/L${NC}     Shrink/grow master"
echo -e "    ${YELLOW}Meta+Arrow${NC}   Focus window"
echo -e "    ${YELLOW}Meta+Shift+Arrow${NC}  Swap window"
echo -e "    ${YELLOW}Meta+Space${NC}   Toggle float"
echo -e "    ${YELLOW}Meta+Q${NC}       Close window"
echo ""
echo -e "  Config:"
echo -e "    ${YELLOW}rocketctl status${NC}          Show status"
echo -e "    ${YELLOW}rocketctl layout set master${NC}  Change layout"
echo -e "    ${YELLOW}rocketctl config set gap 12${NC}  Change gap"
echo ""
