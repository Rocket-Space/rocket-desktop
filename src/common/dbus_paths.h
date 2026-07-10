#pragma once

namespace Rocket {

constexpr const char* DBUS_SERVICE = "org.rocket.Desktop";
constexpr const char* DBUS_SESSION_PATH = "/org/rocket/core";
constexpr const char* DBUS_PANEL_PATH = "/org/rocket/panel";
constexpr const char* DBUS_LAUNCHER_PATH = "/org/rocket/launcher";
constexpr const char* DBUS_NOTIFICATIONS_PATH = "/org/rocket/notifications";
constexpr const char* DBUS_WALLPAPER_PATH = "/org/rocket/wallpaper";
constexpr const char* DBUS_SETTINGS_PATH = "/org/rocket/settings";
constexpr const char* DBUS_POWER_PATH = "/org/rocket/power";
constexpr const char* DBUS_CLIPBOARD_PATH = "/org/rocket/clipboard";
constexpr const char* DBUS_SCREENSHOT_PATH = "/org/rocket/screenshot";

constexpr const char* DBUS_PANEL_IFACE = "org.rocket.Panel";
constexpr const char* DBUS_LAUNCHER_IFACE = "org.rocket.Launcher";
constexpr const char* DBUS_NOTIFICATIONS_IFACE = "org.rocket.Notifications";
constexpr const char* DBUS_WALLPAPER_IFACE = "org.rocket.Wallpaper";
constexpr const char* DBUS_SETTINGS_IFACE = "org.rocket.Settings";
constexpr const char* DBUS_POWER_IFACE = "org.rocket.Power";
constexpr const char* DBUS_CLIPBOARD_IFACE = "org.rocket.Clipboard";
constexpr const char* DBUS_SCREENSHOT_IFACE = "org.rocket.Screenshot";

constexpr const char* FREEDesktop_NOTIFICATIONS_IFACE = "org.freedesktop.Notifications";
constexpr const char* FREEDesktop_NOTIFICATIONS_PATH = "/org/freedesktop/Notifications";

constexpr const char* DBUS_KWIN_SCRIPT_IFACE = "org.kde.KWin.Script";
constexpr const char* DBUS_KWIN_PATH = "/org/kde/KWin";

constexpr const char* CONFIG_DIR = ".config/rocket";
constexpr const char* CONFIG_MAIN = "rocket.conf";
constexpr const char* CONFIG_KEYBINDS = "keybinds.conf";
constexpr const char* CONFIG_APPEARANCE = "appearance.conf";

}
