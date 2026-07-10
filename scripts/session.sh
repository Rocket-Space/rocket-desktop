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

echo "[$(date)] Rocket: Starting session..." > "$ROCKET_LOG"

if [ ! -x "$ROCKET_BIN" ]; then
    echo "Rocket: Binary not found at $ROCKET_BIN" >> "$ROCKET_LOG"
    exit 1
fi

echo "[$(date)] Rocket: Starting KWin compositor..." >> "$ROCKET_LOG"
kwin_wayland --no-lockscreen --no-global-shortcuts --locale1 --xwayland &
KWIN_PID=$!
echo "$KWIN_PID" > "$ROCKET_PID_FILE"

echo "[$(date)] Rocket: Waiting for Wayland display..." >> "$ROCKET_LOG"
for i in $(seq 1 30); do
    if [ -n "$WAYLAND_DISPLAY" ] && [ -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
        break
    fi
    sleep 0.2
done

if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "[$(date)] Rocket: ERROR - Wayland display not ready after 6 seconds" >> "$ROCKET_LOG"
    exit 1
fi

echo "[$(date)] Rocket: Wayland display ready: $WAYLAND_DISPLAY" >> "$ROCKET_LOG"

echo "[$(date)] Rocket: Starting components..." >> "$ROCKET_LOG"

$ROCKET_BIN --panel >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --wallpaper >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --notifications >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --clipboard >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --screenshot >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --settings >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --launcher >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --overview >> "$ROCKET_LOG" 2>&1 &
$ROCKET_BIN --power >> "$ROCKET_LOG" 2>&1 &

echo "[$(date)] Rocket: All components launched" >> "$ROCKET_LOG"

wait $KWIN_PID
echo "[$(date)] Rocket: KWin exited" >> "$ROCKET_LOG"
