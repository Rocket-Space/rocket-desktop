#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
INSTALL_PREFIX="/usr"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "  ██████╗ ██╗  ██╗ ██████╗ ███████╗██████╗ ██╗  ██╗ ██████╗ ██████╗ "
    echo "  ██╔══██╗██║  ██║██╔═══██╗██╔════╝██╔══██╗██║  ██║██╔═══██╗██╔══██╗"
    echo "  ██████╔╝███████║██║   ██║███████╗██████╔╝███████║██║   ██║██████╔╝"
    echo "  ██╔══██╗██╔══██║██║   ██║╚════██║██╔═══╝ ██╔══██║██║   ██║██╔══██╗"
    echo "  ██║  ██║██║  ██║╚██████╔╝███████║██║     ██║  ██║╚██████╔╝██║  ██║"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}Rocket v1.0.0${NC}"
    echo -e "  ${YELLOW}Wayland desktop environment based on KWin${NC}"
    echo ""
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}[ERROR] This installer requires Arch Linux or CachyOS (pacman)${NC}"
        exit 1
    fi
    echo -e "${GREEN}[OK] Detected Arch-based system${NC}"
}

install_deps() {
    echo -e "${CYAN}[*] Installing dependencies...${NC}"

    local DEPS=(
        cmake
        extra-cmake-modules
        gcc
        qt6-base
        qt6-wayland
        qt6-declarative
        qt6-shadertools
        qt6-svg
        kwin
        kf6-kwindowsystem
        kf6-kcoreaddons
        pipewire
        wireplumber
        networkmanager
        bluez
        polkit
        systemd
        noto-fonts
        hicolor-icon-theme
        xdg-utils
    )

    sudo pacman -S --needed --noconfirm "${DEPS[@]}"
    echo -e "${GREEN}[OK] Dependencies installed${NC}"
}

build_project() {
    echo -e "${CYAN}[*] Building Rocket...${NC}"

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    cmake "$PROJECT_DIR" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_BUILD_TYPE=Release

    make -j"$(nproc)"

    echo -e "${GREEN}[OK] Build complete${NC}"
}

install_project() {
    echo -e "${CYAN}[*] Installing Rocket...${NC}"

    cd "$BUILD_DIR"
    sudo make install

    echo -e "${GREEN}[OK] Binaries installed to $INSTALL_PREFIX/bin/${NC}"
}

install_session() {
    echo -e "${CYAN}[*] Installing session files...${NC}"

    sudo mkdir -p /usr/share/wayland-sessions
    sudo cp "$PROJECT_DIR/session/rocket-desktop.desktop" /usr/share/wayland-sessions/

    echo -e "${GREEN}[OK] Session entry installed${NC}"
}

install_config() {
    echo -e "${CYAN}[*] Installing default configuration...${NC}"

    local CONFIG_DIR="$HOME/.config/rocket"
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_DIR/rocket.conf" ]; then
        cp "$PROJECT_DIR/config/default/rocket.conf" "$CONFIG_DIR/"
    fi
    if [ ! -f "$CONFIG_DIR/appearance.conf" ]; then
        cp "$PROJECT_DIR/config/default/appearance.conf" "$CONFIG_DIR/"
    fi

    echo -e "${GREEN}[OK] Configuration installed to $CONFIG_DIR/${NC}"
}

install_systemd() {
    echo -e "${CYAN}[*] Installing systemd services...${NC}"

    mkdir -p "$HOME/.config/systemd/user"

    for service in "$PROJECT_DIR/config/systemd/user/"*.service; do
        [ -f "$service" ] && cp "$service" "$HOME/.config/systemd/user/"
    done
    for target in "$PROJECT_DIR/config/systemd/user/"*.target; do
        [ -f "$target" ] && cp "$target" "$HOME/.config/systemd/user/"
    done

    systemctl --user daemon-reload

    echo -e "${GREEN}[OK] Systemd services installed${NC}"
}

install_launcher() {
    echo -e "${CYAN}[*] Installing launch script...${NC}"

    sudo cp "$SCRIPT_DIR/launch.sh" /usr/bin/rocket-session
    sudo chmod +x /usr/bin/rocket-session

    echo -e "${GREEN}[OK] Launch script installed at /usr/bin/rocket-session${NC}"
}

cleanup() {
    echo -e "${CYAN}[*] Cleaning build directory...${NC}"
    rm -rf "$BUILD_DIR"
    echo -e "${GREEN}[OK] Cleanup complete${NC}"
}

print_banner
check_arch
install_deps
build_project
install_project
install_session
install_config
install_systemd
install_launcher

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Rocket installed successfully!  ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  To start Rocket:"
echo -e "    ${CYAN}1. Log out and select 'Rocket' in your display manager${NC}"
echo -e "    ${CYAN}2. Or run: rocket-session${NC}"
echo ""
echo -e "  Configuration: ${YELLOW}~/.config/rocket/${NC}"
echo -e "  Documentation: ${YELLOW}https://github.com/Rocket-Space/rocket-desktop${NC}"
echo ""
