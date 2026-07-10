#!/bin/bash

if ! command -v kwin_wayland &> /dev/null; then
    echo "Error: kwin_wayland not found. Install kwin package."
    exit 1
fi

if ! command -v rocket-session &> /dev/null && [ ! -f "$(dirname "$0")/build/src/rocket-session" ]; then
    echo "Error: rocket-session not found. Run install.sh first."
    exit 1
fi

export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_CURRENT_DESKTOP=Rocket
export XDG_SESSION_TYPE=wayland
export ROCKET_VERSION=1.0.0
export QT_QPA_PLATFORMTHEME=qt6ct

export ROCKET_LOG="$HOME/.rocket-session.log"

if [ -f "$(dirname "$0")/build/src/rocket-session" ]; then
    exec "$(dirname "$0")/build/src/rocket-session" "$@" > "$ROCKET_LOG" 2>&1
else
    exec rocket-session "$@" > "$ROCKET_LOG" 2>&1
fi
