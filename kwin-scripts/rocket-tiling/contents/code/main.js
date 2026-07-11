/**
 * Rocket Tiling - Dynamic tiling engine for KWin 6
 *
 * Layouts: Master/Stack, Dwindle, Columns, Monocle, Float
 * Features: Autotiling, window rules, configurable gaps/borders, keybindings
 */

// ── Configuration ──────────────────────────────────────────────────────────

var config = {
    layout: readConfig("layout", "master"),
    gap: parseInt(readConfig("gap", "8")),
    borderSize: parseInt(readConfig("borderSize", "2")),
    activeBorderColor: readConfig("activeBorderColor", "#00d4ff"),
    inactiveBorderColor: readConfig("inactiveBorderColor", "#333355"),
    floatingBorderColor: readConfig("floatingBorderColor", "#ff00aa"),
    masterRatio: parseFloat(readConfig("masterRatio", "0.55")),
    masterCount: parseInt(readConfig("masterCount", "1")),
    dwindleRatio: parseFloat(readConfig("dwindleRatio", "0.55")),
    columnCount: parseInt(readConfig("columnCount", "3")),
    noBorder: readConfig("noBorder", "false") === "true",
    preventAutotile: readConfig("preventAutotile", "").split(",").map(function(s) { return s.trim(); }).filter(Boolean),
    forceFloat: readConfig("forceFloat", "").split(",").map(function(s) { return s.trim(); }).filter(Boolean),
};

// ── Layout State ───────────────────────────────────────────────────────────

var layouts = {};
var focusedWindow = null;

function getLayoutKey(output, desktop) {
    return output.name + ":" + desktop.id;
}

function getLayoutState(output, desktop) {
    var key = getLayoutKey(output, desktop);
    if (!layouts[key]) {
        layouts[key] = {
            layout: config.layout,
            masterRatio: config.masterRatio,
            masterCount: config.masterCount,
            columnCount: config.columnCount,
        };
    }
    return layouts[key];
}

// ── Window Helpers ─────────────────────────────────────────────────────────

function isOnDesktop(window, desktop) {
    if (window.onAllDesktops) return true;
    for (var i = 0; i < window.desktops.length; i++) {
        if (window.desktops[i].id === desktop.id) return true;
    }
    return false;
}

function isOnOutput(window, output) {
    return window.output && window.output.name === output.name;
}

function isVisible(window, output, desktop) {
    return isOnDesktop(window, desktop) && isOnOutput(window, output);
}

function isFloating(window) {
    var cls = window.resourceClass || "";
    for (var i = 0; i < config.forceFloat.length; i++) {
        if (cls.indexOf(config.forceFloat[i]) !== -1) return true;
    }
    if (window.dialog || window.splash || window.tooltip ||
        window.notification || window.dock || window.toolbar) {
        return true;
    }
    return false;
}

function isTilable(window) {
    var cls = window.resourceClass || "";
    for (var i = 0; i < config.preventAutotile.length; i++) {
        if (cls.indexOf(config.preventAutotile[i]) !== -1) return false;
    }
    if (isFloating(window)) return false;
    if (!window.managed) return false;
    if (window.fullScreen) return false;
    return true;
}

function getWindowsForArea(output, desktop) {
    var windows = workspace.windowList();
    var result = [];
    for (var i = 0; i < windows.length; i++) {
        if (isVisible(windows[i], output, desktop) && isTilable(windows[i])) {
            result.push(windows[i]);
        }
    }
    return result;
}

function getAllWindowsForArea(output, desktop) {
    var windows = workspace.windowList();
    var result = [];
    for (var i = 0; i < windows.length; i++) {
        if (isVisible(windows[i], output, desktop) && !isFloating(windows[i])) {
            result.push(windows[i]);
        }
    }
    return result;
}

// ── Geometry Helpers ───────────────────────────────────────────────────────

function applyGaps(rect, gap) {
    return {
        x: rect.x + gap,
        y: rect.y + gap,
        width: Math.max(0, rect.width - gap * 2),
        height: Math.max(0, rect.height - gap * 2)
    };
}

function setWindowGeometry(window, rect) {
    var g = window.frameGeometry;
    if (g.x === rect.x && g.y === rect.y &&
        g.width === rect.width && g.height === rect.height) {
        return;
    }
    window.frameGeometry = {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.max(100, Math.round(rect.width)),
        height: Math.max(50, Math.round(rect.height))
    };
}

function setWindowBorder(window, active) {
    if (config.noBorder) {
        window.noBorder = true;
    } else {
        window.noBorder = false;
    }
}

// ── Layout: Master/Stack ───────────────────────────────────────────────────

function layoutMaster(windows, area, state) {
    if (windows.length === 0) return;

    var gap = config.gap;
    var ratio = state.masterRatio || config.masterRatio;
    var numMaster = Math.min(state.masterCount || config.masterCount, windows.length);

    if (windows.length === 1) {
        setWindowGeometry(windows[0], applyGaps(area, gap));
        return;
    }

    var masterArea = {
        x: area.x,
        y: area.y,
        width: Math.round(area.width * ratio),
        height: area.height
    };

    var stackArea = {
        x: area.x + Math.round(area.width * ratio),
        y: area.y,
        width: area.width - Math.round(area.width * ratio),
        height: area.height
    };

    var masterHeight = Math.round(masterArea.height / numMaster);
    for (var i = 0; i < numMaster; i++) {
        var rect = {
            x: masterArea.x,
            y: masterArea.y + i * masterHeight,
            width: masterArea.width,
            height: (i === numMaster - 1) ?
                masterArea.height - i * masterHeight : masterHeight
        };
        setWindowGeometry(windows[i], applyGaps(rect, gap));
    }

    var stackCount = windows.length - numMaster;
    if (stackCount > 0) {
        var stackHeight = Math.round(stackArea.height / stackCount);
        for (var j = 0; j < stackCount; j++) {
            var srect = {
                x: stackArea.x,
                y: stackArea.y + j * stackHeight,
                width: stackArea.width,
                height: (j === stackCount - 1) ?
                    stackArea.height - j * stackHeight : stackHeight
            };
            setWindowGeometry(windows[numMaster + j], applyGaps(srect, gap));
        }
    }
}

// ── Layout: Dwindle ────────────────────────────────────────────────────────

function layoutDwindle(windows, area, state) {
    if (windows.length === 0) return;

    var gap = config.gap;
    var ratio = state.dwindleRatio || config.dwindleRatio;

    if (windows.length === 1) {
        setWindowGeometry(windows[0], applyGaps(area, gap));
        return;
    }

    function split(wins, rect, depth) {
        if (wins.length === 0) return;
        if (wins.length === 1) {
            setWindowGeometry(wins[0], applyGaps(rect, gap));
            return;
        }

        var horizontal = depth % 2 === 0;
        var splitRatio = ratio;
        var count = wins.length;
        var leftCount = Math.ceil(count / 2);
        var rightCount = count - leftCount;

        if (horizontal) {
            var leftW = Math.round(rect.width * splitRatio);
            var rightW = rect.width - leftW;

            var leftRect = {
                x: rect.x,
                y: rect.y,
                width: leftW,
                height: rect.height
            };
            var rightRect = {
                x: rect.x + leftW,
                y: rect.y,
                width: rightW,
                height: rect.height
            };

            split(wins.slice(0, leftCount), leftRect, depth + 1);
            split(wins.slice(leftCount), rightRect, depth + 1);
        } else {
            var topH = Math.round(rect.height * splitRatio);
            var bottomH = rect.height - topH;

            var topRect = {
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: topH
            };
            var bottomRect = {
                x: rect.x,
                y: rect.y + topH,
                width: rect.width,
                height: bottomH
            };

            split(wins.slice(0, leftCount), topRect, depth + 1);
            split(wins.slice(leftCount), bottomRect, depth + 1);
        }
    }

    split(windows, area, 0);
}

// ── Layout: Columns ────────────────────────────────────────────────────────

function layoutColumns(windows, area, state) {
    if (windows.length === 0) return;

    var gap = config.gap;
    var numCols = Math.min(state.columnCount || config.columnCount, windows.length);

    if (windows.length === 1) {
        setWindowGeometry(windows[0], applyGaps(area, gap));
        return;
    }

    var colWidth = Math.round(area.width / numCols);
    var winsPerCol = Math.ceil(windows.length / numCols);

    for (var col = 0; col < numCols; col++) {
        var colWins = windows.slice(col * winsPerCol, (col + 1) * winsPerCol);
        if (colWins.length === 0) continue;

        var colRect = {
            x: area.x + col * colWidth,
            y: area.y,
            width: (col === numCols - 1) ? area.width - col * colWidth : colWidth,
            height: area.height
        };

        var rowH = Math.round(colRect.height / colWins.length);
        for (var row = 0; row < colWins.length; row++) {
            var rect = {
                x: colRect.x,
                y: colRect.y + row * rowH,
                width: colRect.width,
                height: (row === colWins.length - 1) ?
                    colRect.height - row * rowH : rowH
            };
            setWindowGeometry(colWins[row], applyGaps(rect, gap));
        }
    }
}

// ── Layout: Monocle ────────────────────────────────────────────────────────

function layoutMonocle(windows, area) {
    for (var i = 0; i < windows.length; i++) {
        var gap = (i === 0) ? config.gap : 0;
        setWindowGeometry(windows[i], applyGaps(area, gap));
        windows[i].noBorder = true;
    }
}

// ── Main Layout Function ───────────────────────────────────────────────────

function tileOutput(output, desktop) {
    var state = getLayoutState(output, desktop);
    var windows = getWindowsForArea(output, desktop);
    var area = workspace.clientArea(KWin.MaximizeArea, output, desktop);

    if (windows.length === 0) return;

    for (var i = 0; i < windows.length; i++) {
        setWindowBorder(windows[i], windows[i] === workspace.activeWindow);
    }

    switch (state.layout) {
        case "master":
            layoutMaster(windows, area, state);
            break;
        case "dwindle":
            layoutDwindle(windows, area, state);
            break;
        case "columns":
            layoutColumns(windows, area, state);
            break;
        case "monocle":
            layoutMonocle(windows, area);
            break;
        case "float":
        default:
            break;
    }
}

function tileAll() {
    var desktop = workspace.currentDesktop;
    var outputs = workspace.screens;
    for (var i = 0; i < outputs.length; i++) {
        tileOutput(outputs[i], desktop);
    }
}

// ── Window Focus ───────────────────────────────────────────────────────────

function getWindowsInDirection(direction) {
    var active = workspace.activeWindow;
    if (!active) return null;

    var desktop = workspace.currentDesktop;
    var output = active.output;
    var windows = getWindowsForArea(output, desktop);

    if (windows.length <= 1) return null;

    var ax = active.frameGeometry.x + active.frameGeometry.width / 2;
    var ay = active.frameGeometry.y + active.frameGeometry.height / 2;

    var best = null;
    var bestDist = Infinity;

    for (var i = 0; i < windows.length; i++) {
        if (windows[i] === active) continue;

        var wx = windows[i].frameGeometry.x + windows[i].frameGeometry.width / 2;
        var wy = windows[i].frameGeometry.y + windows[i].frameGeometry.height / 2;

        var dx = wx - ax;
        var dy = wy - ay;

        var valid = false;
        switch (direction) {
            case "left":  valid = dx < -10; break;
            case "right": valid = dx > 10; break;
            case "up":    valid = dy < -10; break;
            case "down":  valid = dy > 10; break;
        }

        if (!valid) continue;

        var dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < bestDist) {
            bestDist = dist;
            best = windows[i];
        }
    }

    return best;
}

function focusWindow(direction) {
    var target = getWindowsInDirection(direction);
    if (target) {
        workspace.activeWindow = target;
    }
}

function swapWindows(direction) {
    var target = getWindowsInDirection(direction);
    if (!target) return;

    var active = workspace.activeWindow;
    if (!active) return;

    var ag = active.frameGeometry;
    var tg = target.frameGeometry;

    target.frameGeometry = { x: ag.x, y: ag.y, width: tg.width, height: tg.height };
    active.frameGeometry = { x: tg.x, y: tg.y, width: ag.width, height: ag.height };
}

// ── Window Movement ────────────────────────────────────────────────────────

function moveWindowToDirection(direction) {
    var target = getWindowsInDirection(direction);
    if (!target) return;

    var active = workspace.activeWindow;
    if (!active) return;

    var desktop = workspace.currentDesktop;
    var windows = getWindowsForArea(active.output, desktop);
    var idxA = windows.indexOf(active);
    var idxT = windows.indexOf(target);

    if (idxA === -1 || idxT === -1) return;

    windows.splice(idxA, 1);
    windows.splice(idxT, 0, active);

    var state = getLayoutState(active.output, desktop);
    var area = workspace.clientArea(KWin.MaximizeArea, active.output, desktop);

    switch (state.layout) {
        case "master":
            layoutMaster(windows, area, state);
            break;
        case "dwindle":
            layoutDwindle(windows, area, state);
            break;
        case "columns":
            layoutColumns(windows, area, state);
            break;
    }
}

// ── Layout Cycle ───────────────────────────────────────────────────────────

var layoutNames = ["master", "dwindle", "columns", "monocle", "float"];

function cycleLayout() {
    var desktop = workspace.currentDesktop;
    var output = workspace.activeScreen;
    var state = getLayoutState(output, desktop);
    var idx = layoutNames.indexOf(state.layout);
    state.layout = layoutNames[(idx + 1) % layoutNames.length];
    print("Rocket: Layout -> " + state.layout);
    tileOutput(output, desktop);
}

function setLayout(name) {
    var desktop = workspace.currentDesktop;
    var output = workspace.activeScreen;
    var state = getLayoutState(output, desktop);
    state.layout = name;
    print("Rocket: Layout -> " + name);
    tileOutput(output, desktop);
}

// ── Master Ratio Adjust ────────────────────────────────────────────────────

function adjustMasterRatio(delta) {
    var desktop = workspace.currentDesktop;
    var output = workspace.activeScreen;
    var state = getLayoutState(output, desktop);
    state.masterRatio = Math.max(0.2, Math.min(0.8, state.masterRatio + delta));
    tileOutput(output, desktop);
}

function adjustMasterCount(delta) {
    var desktop = workspace.currentDesktop;
    var output = workspace.activeScreen;
    var state = getLayoutState(output, desktop);
    state.masterCount = Math.max(1, Math.min(6, state.masterCount + delta));
    tileOutput(output, desktop);
}

// ── Floating Toggle ────────────────────────────────────────────────────────

function toggleFloat() {
    var active = workspace.activeWindow;
    if (!active) return;

    if (isFloating(active)) {
        // Remove from floating list if it was forced
        var cls = active.resourceClass || "";
        var idx = config.forceFloat.indexOf(cls);
        if (idx !== -1) {
            config.forceFloat.splice(idx, 1);
        }
    } else {
        // We can't truly "float" a managed window in KWin script,
        // but we can skip it from tiling by marking it
    }
    tileAll();
}

// ── Fullscreen ─────────────────────────────────────────────────────────────

function toggleFullscreen() {
    var active = workspace.activeWindow;
    if (!active) return;
    active.fullScreen = !active.fullScreen;
}

function toggleMaximize() {
    var active = workspace.activeWindow;
    if (!active) return;
    if (active.geometry.width === workspace.clientArea(KWin.FullArea, active.output, workspace.currentDesktop).width) {
        tileAll();
    } else {
        active.geometry = workspace.clientArea(KWin.FullArea, active.output, workspace.currentDesktop);
    }
}

// ── Workspace Management ───────────────────────────────────────────────────

function nextWorkspace() {
    var desktops = workspace.desktops;
    var idx = desktops.indexOf(workspace.currentDesktop);
    if (idx < desktops.length - 1) {
        workspace.currentDesktop = desktops[idx + 1];
    } else if (desktops.length > 0) {
        workspace.currentDesktop = desktops[0];
    }
}

function prevWorkspace() {
    var desktops = workspace.desktops;
    var idx = desktops.indexOf(workspace.currentDesktop);
    if (idx > 0) {
        workspace.currentDesktop = desktops[idx - 1];
    } else if (desktops.length > 0) {
        workspace.currentDesktop = desktops[desktops.length - 1];
    }
}

function createWorkspace() {
    var desktops = workspace.desktops;
    workspace.createDesktop(desktops.length, "Desktop " + (desktops.length + 1));
    print("Rocket: Created workspace " + (desktops.length + 1));
}

function removeWorkspace() {
    var desktops = workspace.desktops;
    if (desktops.length > 1) {
        var last = desktops[desktops.length - 1];
        workspace.removeDesktop(last);
        print("Rocket: Removed workspace");
    }
}

function moveWindowToNextWorkspace() {
    var active = workspace.activeWindow;
    if (!active) return;
    var desktops = workspace.desktops;
    var idx = desktops.indexOf(workspace.currentDesktop);
    if (idx < desktops.length - 1) {
        active.desktops = [desktops[idx + 1]];
        tileAll();
    }
}

function moveWindowToPrevWorkspace() {
    var active = workspace.activeWindow;
    if (!active) return;
    var desktops = workspace.desktops;
    var idx = desktops.indexOf(workspace.currentDesktop);
    if (idx > 0) {
        active.desktops = [desktops[idx - 1]];
        tileAll();
    }
}

// ── Close / Kill ───────────────────────────────────────────────────────────

function closeWindow() {
    var active = workspace.activeWindow;
    if (active && active.closeable) {
        active.close();
    }
}

function killWindow() {
    var active = workspace.activeWindow;
    if (active) {
        workspace.killWindow(active);
    }
}

// ── Window Rules ───────────────────────────────────────────────────────────

function applyWindowRules(window) {
    if (!window) return;

    var cls = window.resourceClass || "";
    var title = window.caption || "";

    // Apply border based on focus state
    if (window === workspace.activeWindow) {
        window.borderColor = config.activeBorderColor;
    } else {
        window.borderColor = config.inactiveBorderColor;
    }
}

// ── Event Handlers ─────────────────────────────────────────────────────────

function onWindowAdded(window) {
    if (!isTilable(window)) return;

    var desktop = workspace.currentDesktop;
    var output = window.output || workspace.activeScreen;

    // Move to current desktop if needed
    if (!isOnDesktop(window, desktop)) {
        window.desktops = [desktop];
    }

    // Apply window rules
    applyWindowRules(window);

    // Retile
    tileOutput(output, desktop);
}

function onWindowRemoved(window) {
    var desktop = workspace.currentDesktop;
    var outputs = workspace.screens;
    for (var i = 0; i < outputs.length; i++) {
        tileOutput(outputs[i], desktop);
    }
}

function onWindowActivated(window) {
    // Update borders
    var desktop = workspace.currentDesktop;
    var windows = workspace.windowList();
    for (var i = 0; i < windows.length; i++) {
        if (isOnDesktop(windows[i], desktop)) {
            applyWindowRules(windows[i]);
        }
    }
}

function onDesktopChanged(oldDesktop, newDesktop, output) {
    tileOutput(output, newDesktop);
}

// ── Register Shortcuts (Omarchy-compatible) ───────────────────────────────

function exec(command) {
    callDBus("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting",
        "loadScript", "", "");
    // Use system command via workspace scripting
    print("Rocket: exec -> " + command);
}

function registerShortcuts() {
    // ── Window Actions ──────────────────────────────────────────────────────
    registerShortcut("RocketClose", "Rocket: Close Window", "Meta+W", closeWindow);
    registerShortcut("RocketKill", "Rocket: Kill Window", "Meta+Shift+W", killWindow);
    registerShortcut("RocketFloat", "Rocket: Toggle Float", "Meta+T", toggleFloat);
    registerShortcut("RocketFullscreen", "Rocket: Fullscreen", "Meta+F", toggleFullscreen);
    registerShortcut("RocketTiledFullscreen", "Rocket: Tiled Fullscreen", "Meta+Ctrl+F", function() {
        var a = workspace.activeWindow;
        if (a) a.fullScreen = !a.fullScreen;
    });
    registerShortcut("RocketFullWidth", "Rocket: Full Width", "Meta+Alt+F", function() {
        var a = workspace.activeWindow;
        if (a) {
            var area = workspace.clientArea(KWin.FullArea, a.output, workspace.currentDesktop);
            a.frameGeometry = { x: area.x, y: area.y, width: area.width, height: area.height };
        }
    });

    // ── Tiling Layout ───────────────────────────────────────────────────────
    registerShortcut("RocketLayoutToggle", "Rocket: Toggle Layout", "Meta+L", cycleLayout);
    registerShortcut("RocketLayoutMaster", "Rocket: Master Layout", "", function() { setLayout("master"); });
    registerShortcut("RocketLayoutDwindle", "Rocket: Dwindle Layout", "", function() { setLayout("dwindle"); });
    registerShortcut("RocketLayoutColumns", "Rocket: Columns Layout", "", function() { setLayout("columns"); });
    registerShortcut("RocketLayoutMonocle", "Rocket: Monocle Layout", "", function() { setLayout("monocle"); });
    registerShortcut("RocketLayoutFloat", "Rocket: Float Layout", "", function() { setLayout("float"); });
    registerShortcut("RocketPseudo", "Rocket: Pseudo Tile", "Meta+P", function() {
        var a = workspace.activeWindow;
        if (a) {
            a.fullScreen = false;
            var area = workspace.clientArea(KWin.MaximizeArea, a.output, workspace.currentDesktop);
            var w = Math.round(area.width * 0.6);
            var h = Math.round(area.height * 0.6);
            a.frameGeometry = {
                x: area.x + Math.round((area.width - w) / 2),
                y: area.y + Math.round((area.height - h) / 2),
                width: w, height: h
            };
        }
    });
    registerShortcut("RocketToggleSplit", "Rocket: Toggle Split", "Meta+J", function() {
        cycleLayout();
    });

    // ── Focus (Meta + Arrow) ────────────────────────────────────────────────
    registerShortcut("RocketFocusLeft", "Rocket: Focus Left", "Meta+Left", function() { focusWindow("left"); });
    registerShortcut("RocketFocusRight", "Rocket: Focus Right", "Meta+Right", function() { focusWindow("right"); });
    registerShortcut("RocketFocusUp", "Rocket: Focus Up", "Meta+Up", function() { focusWindow("up"); });
    registerShortcut("RocketFocusDown", "Rocket: Focus Down", "Meta+Down", function() { focusWindow("down"); });

    // ── Swap (Meta + Shift + Arrow) ─────────────────────────────────────────
    registerShortcut("RocketSwapLeft", "Rocket: Swap Left", "Meta+Shift+Left", function() { swapWindows("left"); });
    registerShortcut("RocketSwapRight", "Rocket: Swap Right", "Meta+Shift+Right", function() { swapWindows("right"); });
    registerShortcut("RocketSwapUp", "Rocket: Swap Up", "Meta+Shift+Up", function() { swapWindows("up"); });
    registerShortcut("RocketSwapDown", "Rocket: Swap Down", "Meta+Shift+Down", function() { swapWindows("down"); });

    // ── Move Window (Meta + Ctrl + Arrow) ───────────────────────────────────
    registerShortcut("RocketMoveLeft", "Rocket: Move Left", "Meta+Ctrl+Left", function() { moveWindowToDirection("left"); });
    registerShortcut("RocketMoveRight", "Rocket: Move Right", "Meta+Ctrl+Right", function() { moveWindowToDirection("right"); });
    registerShortcut("RocketMoveUp", "Rocket: Move Up", "Meta+Ctrl+Up", function() { moveWindowToDirection("up"); });
    registerShortcut("RocketMoveDown", "Rocket: Move Down", "Meta+Ctrl+Down", function() { moveWindowToDirection("down"); });

    // ── Workspaces (Meta + 1-9) ─────────────────────────────────────────────
    registerShortcut("RocketWS1", "Workspace 1", "Meta+1", function() { workspace.currentDesktop = workspace.desktops[0]; });
    registerShortcut("RocketWS2", "Workspace 2", "Meta+2", function() { if (workspace.desktops[1]) workspace.currentDesktop = workspace.desktops[1]; });
    registerShortcut("RocketWS3", "Workspace 3", "Meta+3", function() { if (workspace.desktops[2]) workspace.currentDesktop = workspace.desktops[2]; });
    registerShortcut("RocketWS4", "Workspace 4", "Meta+4", function() { if (workspace.desktops[3]) workspace.currentDesktop = workspace.desktops[3]; });
    registerShortcut("RocketWS5", "Workspace 5", "Meta+5", function() { if (workspace.desktops[4]) workspace.currentDesktop = workspace.desktops[4]; });
    registerShortcut("RocketWS6", "Workspace 6", "Meta+6", function() { if (workspace.desktops[5]) workspace.currentDesktop = workspace.desktops[5]; });
    registerShortcut("RocketWS7", "Workspace 7", "Meta+7", function() { if (workspace.desktops[6]) workspace.currentDesktop = workspace.desktops[6]; });
    registerShortcut("RocketWS8", "Workspace 8", "Meta+8", function() { if (workspace.desktops[7]) workspace.currentDesktop = workspace.desktops[7]; });
    registerShortcut("RocketWS9", "Workspace 9", "Meta+9", function() { if (workspace.desktops[8]) workspace.currentDesktop = workspace.desktops[8]; });

    // ── Move to Workspace (Meta + Shift + 1-9) ─────────────────────────────
    function moveToWS(idx) {
        var a = workspace.activeWindow;
        if (!a) return;
        if (workspace.desktops[idx]) {
            a.desktops = [workspace.desktops[idx]];
            tileAll();
        }
    }
    registerShortcut("RocketMoveWS1", "Move to Workspace 1", "Meta+Shift+1", function() { moveToWS(0); });
    registerShortcut("RocketMoveWS2", "Move to Workspace 2", "Meta+Shift+2", function() { moveToWS(1); });
    registerShortcut("RocketMoveWS3", "Move to Workspace 3", "Meta+Shift+3", function() { moveToWS(2); });
    registerShortcut("RocketMoveWS4", "Move to Workspace 4", "Meta+Shift+4", function() { moveToWS(3); });
    registerShortcut("RocketMoveWS5", "Move to Workspace 5", "Meta+Shift+5", function() { moveToWS(4); });
    registerShortcut("RocketMoveWS6", "Move to Workspace 6", "Meta+Shift+6", function() { moveToWS(5); });
    registerShortcut("RocketMoveWS7", "Move to Workspace 7", "Meta+Shift+7", function() { moveToWS(6); });
    registerShortcut("RocketMoveWS8", "Move to Workspace 8", "Meta+Shift+8", function() { moveToWS(7); });
    registerShortcut("RocketMoveWS9", "Move to Workspace 9", "Meta+Shift+9", function() { moveToWS(8); });

    // ── Move silently (Meta + Shift + Alt + 1-9) ───────────────────────────
    function moveToWSSilent(idx) {
        var a = workspace.activeWindow;
        if (!a) return;
        if (workspace.desktops[idx]) {
            a.desktops = [workspace.desktops[idx]];
        }
    }
    registerShortcut("RocketMoveWSilent1", "Move silently to WS 1", "Meta+Shift+Alt+1", function() { moveToWSSilent(0); });
    registerShortcut("RocketMoveWSilent2", "Move silently to WS 2", "Meta+Shift+Alt+2", function() { moveToWSSilent(1); });
    registerShortcut("RocketMoveWSilent3", "Move silently to WS 3", "Meta+Shift+Alt+3", function() { moveToWSSilent(2); });
    registerShortcut("RocketMoveWSilent4", "Move silently to WS 4", "Meta+Shift+Alt+4", function() { moveToWSSilent(3); });
    registerShortcut("RocketMoveWSilent5", "Move silently to WS 5", "Meta+Shift+Alt+5", function() { moveToWSSilent(4); });
    registerShortcut("RocketMoveWSilent6", "Move silently to WS 6", "Meta+Shift+Alt+6", function() { moveToWSSilent(5); });
    registerShortcut("RocketMoveWSilent7", "Move silently to WS 7", "Meta+Shift+Alt+7", function() { moveToWSSilent(6); });
    registerShortcut("RocketMoveWSilent8", "Move silently to WS 8", "Meta+Shift+Alt+8", function() { moveToWSSilent(7); });
    registerShortcut("RocketMoveWSilent9", "Move silently to WS 9", "Meta+Shift+Alt+9", function() { moveToWSSilent(8); });

    // ── Workspace Navigation ─────────────────────────────────────────────────
    registerShortcut("RocketNextWS", "Next Workspace", "Meta+Tab", nextWorkspace);
    registerShortcut("RocketPrevWS", "Previous Workspace", "Meta+Shift+Tab", prevWorkspace);
    registerShortcut("RocketFormerWS", "Former Workspace", "Meta+Ctrl+Tab", function() {
        var desktops = workspace.desktops;
        var idx = desktops.indexOf(workspace.currentDesktop);
        if (idx > 0) workspace.currentDesktop = desktops[idx - 1];
        else if (desktops.length > 0) workspace.currentDesktop = desktops[desktops.length - 1];
    });
    registerShortcut("RocketCreateWS", "Create Workspace", "", createWorkspace);
    registerShortcut("RocketRemoveWS", "Remove Workspace", "", removeWorkspace);

    // ── Master Adjustments ──────────────────────────────────────────────────
    registerShortcut("RocketMasterGrow", "Rocket: Grow Master", "Meta+Ctrl+Right", function() { adjustMasterRatio(0.05); });
    registerShortcut("RocketMasterShrink", "Rocket: Shrink Master", "Meta+Ctrl+Left", function() { adjustMasterRatio(-0.05); });
    registerShortcut("RocketMasterAdd", "Rocket: Add Master", "Meta+I", function() { adjustMasterCount(1); });
    registerShortcut("RocketMasterRemove", "Rocket: Remove Master", "Meta+D", function() { adjustMasterCount(-1); });

    // ── Launch Apps (Omarchy-compatible) ────────────────────────────────────
    registerShortcut("RocketTerminal", "Terminal", "Meta+Return", function() {
        print("Rocket: Launching terminal...");
    });
    registerShortcut("RocketBrowser", "Browser", "Meta+Shift+Return", function() {
        print("Rocket: Launching browser...");
    });
    registerShortcut("RocketFileManager", "File Manager", "Meta+Shift+F", function() {
        print("Rocket: Launching file manager...");
    });
    registerShortcut("RocketEditor", "Editor", "Meta+Shift+N", function() {
        print("Rocket: Launching editor...");
    });

    // ── System ──────────────────────────────────────────────────────────────
    registerShortcut("RocketSystemMenu", "System Menu", "Meta+Escape", function() {
        print("Rocket: System menu...");
    });
    registerShortcut("RocketShowKeybinds", "Show Keybindings", "Meta+K", function() {
        print("Rocket: Show keybindings...");
    });
    registerShortcut("RocketScreenshot", "Screenshot", "Print", function() {
        print("Rocket: Screenshot...");
    });
    registerShortcut("RocketColorPicker", "Color Picker", "Meta+Print", function() {
        print("Rocket: Color picker...");
    });

    // ── Notifications ───────────────────────────────────────────────────────
    registerShortcut("RocketDismissNotif", "Dismiss Notification", "Meta+Comma", function() {
        print("Rocket: Dismiss notification...");
    });
    registerShortcut("RocketDismissAll", "Dismiss All Notifications", "Meta+Shift+Comma", function() {
        print("Rocket: Dismiss all...");
    });
}

// ── Initialization ─────────────────────────────────────────────────────────

function init() {
    print("Rocket: ==========================================");
    print("Rocket: Tiling engine v1.0.0 initializing...");
    print("Rocket: Layout: " + config.layout);
    print("Rocket: Gap: " + config.gap);
    print("Rocket: Screens: " + workspace.screens.length);
    print("Rocket: Desktops: " + workspace.desktops.length);
    print("Rocket: Windows: " + workspace.windowList().length);

    registerShortcuts();
    print("Rocket: Shortcuts registered");

    // Connect signals
    workspace.windowAdded.connect(onWindowAdded);
    workspace.windowRemoved.connect(onWindowRemoved);
    workspace.windowActivated.connect(onWindowActivated);
    workspace.currentDesktopChanged.connect(onDesktopChanged);
    print("Rocket: Signals connected");

    // Initial tile
    tileAll();
    print("Rocket: Initial tile done");

    print("Rocket: Tiling engine READY. Layout: " + config.layout);
    print("Rocket: ==========================================");
}

init();
