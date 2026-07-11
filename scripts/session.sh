#!/bin/bash
set -e

export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_CURRENT_DESKTOP=Rocket
export XDG_SESSION_TYPE=wayland
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export ROCKET_VERSION=1.0.0

ROCKET_BIN="/usr/bin/rocket-session-bin"
ROCKET_LOG="$HOME/.rocket-session.log"
ROCKET_PID_FILE="/tmp/rocket-session.pid"

cleanup() {
    echo "[$(date)] Rocket: Shutting down..." >> "$ROCKET_LOG"
    if [ -f "$ROCKET_PID_FILE" ]; then
        kill $(cat "$ROCKET_PID_FILE") 2>/dev/null
        rm -f "$ROCKET_PID_FILE"
    fi
    kill $(jobs -p) 2>/dev/null
    wait 2>/dev/null
}
trap cleanup EXIT INT TERM

# Return to SDDM when session ends
return_to_sddm() {
    echo "[$(date)] Rocket: Returning to display manager..." >> "$ROCKET_LOG"
    # Try to restart SDDM greeter
    if command -v sddm-greeter &>/dev/null; then
        sddm-greeter --socket /tmp/sddm-* --theme /usr/share/sddm/themes/ 2>/dev/null &
    elif systemctl is-active sddm &>/dev/null; then
        sudo systemctl restart sddm 2>/dev/null || true
    fi
}

echo "[$(date)] Rocket: Starting session..." > "$ROCKET_LOG"

if [ ! -x "$ROCKET_BIN" ]; then
    echo "Rocket: Binary not found at $ROCKET_BIN" >> "$ROCKET_LOG"
    exit 1
fi

# ── Start KWin ──────────────────────────────────────────────────────────────
echo "[$(date)] Rocket: Starting KWin compositor..." >> "$ROCKET_LOG"
kwin_wayland --no-lockscreen --no-global-shortcuts --locale1 --xwayland &
KWIN_PID=$!
echo "$KWIN_PID" > "$ROCKET_PID_FILE"

# ── Wait for Wayland display ───────────────────────────────────────────────
echo "[$(date)] Rocket: Waiting for Wayland display..." >> "$ROCKET_LOG"
for i in $(seq 1 30); do
    if [ -e "$XDG_RUNTIME_DIR/wayland-0" ]; then
        export WAYLAND_DISPLAY="wayland-0"
        break
    fi
    sleep 0.2
done

if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "[$(date)] Rocket: ERROR - Wayland display not ready" >> "$ROCKET_LOG"
    exit 1
fi

echo "[$(date)] Rocket: Wayland display ready: $WAYLAND_DISPLAY" >> "$ROCKET_LOG"

# ── Load KWin tiling script ────────────────────────────────────────────────
echo "[$(date)] Rocket: Loading KWin tiling script..." >> "$ROCKET_LOG"
# Script auto-loads from kwinrc [Plugins] rocket-tilingEnabled=true
# Just need to wait for KWin to be ready and reconfigure
RETRIES=0
while [ $RETRIES -lt 20 ]; do
    if qdbus6 org.kde.KWin /KWin org.kde.KWin.isActive 2>/dev/null | grep -qi "true\|yes"; then
        break
    fi
    sleep 0.5
    RETRIES=$((RETRIES + 1))
done
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
sleep 2
# Verify script loaded
SCRIPTS=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded "rocket-tiling" 2>/dev/null || echo "unknown")
echo "[$(date)] Rocket: Tiling script loaded: $SCRIPTS" >> "$ROCKET_LOG"

# ── Enable KWin built-in effects ───────────────────────────────────────────
echo "[$(date)] Rocket: Enabling effects..." >> "$ROCKET_LOG"
sleep 0.5
qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.loadEffect "fade" 2>/dev/null || true
qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.loadEffect "glide" 2>/dev/null || true
qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.loadEffect "slide" 2>/dev/null || true
qdbus6 org.kde.KWin /Effects org.kde.KWin.Effects.loadEffect "blur" 2>/dev/null || true

# ── Launch shell components ────────────────────────────────────────────────
echo "[$(date)] Rocket: Starting components..." >> "$ROCKET_LOG"

# Start rocket-launcher DBus service for app launching shortcuts
rocket-launcher &
sleep 1

# Start krunner for app launching shortcuts (if available)
krunner --daemon 2>/dev/null &
$ROCKET_BIN --panel >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --wallpaper >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --notifications >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --power >> "$ROCKET_LOG" 2>&1 &

echo "[$(date)] Rocket: All components launched" >> "$ROCKET_LOG"
echo "[$(date)] Rocket: Use 'rocketctl status' to check status" >> "$ROCKET_LOG"

wait $KWIN_PID
echo "[$(date)] Rocket: KWin exited" >> "$ROCKET_LOG"
return_to_sddm
