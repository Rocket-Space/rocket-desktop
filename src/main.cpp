#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDebug>
#include <QCommandLineParser>
#include "core/config_manager.h"
#include "panel/panel_window.h"
#include "notifications/daemon.h"
#include "notifications/popup.h"
#include "wallpaper/renderer.h"
#include "clipboard/manager.h"
#include "clipboard/history_window.h"
#include "screenshot/screenshot_tool.h"
#include "launcher/launcher_window.h"
#include "overview/overview_window.h"
#include "settings/settings_window.h"
#include "power/power_manager.h"
static int runPanel(QGuiApplication& app) {
    Rocket::ConfigManager::instance().load();
    Rocket::PanelWindow panel;
    panel.show();
    qDebug() << "Rocket: Panel started";
    return app.exec();
}

static int runLauncher(QGuiApplication& app) {
    LauncherWindow window;
    window.show();
    qDebug() << "Rocket: Launcher started";
    return app.exec();
}

static int runOverview(QGuiApplication& app) {
    OverviewWindow window;
    window.show();
    qDebug() << "Rocket: Overview started";
    return app.exec();
}

static int runWallpaper(QGuiApplication& app) {
    Rocket::ConfigManager::instance().load();
    WallpaperRenderer renderer;
    renderer.show();
    qDebug() << "Rocket: Wallpaper started";
    return app.exec();
}

static int runNotifications(QGuiApplication& app) {
    NotificationDaemon::instance();
    qDebug() << "Rocket: Notification daemon started";
    return app.exec();
}

static int runClipboard(QGuiApplication& app) {
    ClipboardManager::instance();
    qDebug() << "Rocket: Clipboard manager started";
    return app.exec();
}

static int runSettings(QGuiApplication& app) {
    Rocket::ConfigManager::instance().load();
    SettingsWindow window;
    window.hide();
    qDebug() << "Rocket: Settings started";
    return app.exec();
}

static int runScreenshot(QGuiApplication& app) {
    ScreenshotTool::instance();
    qDebug() << "Rocket: Screenshot tool started";
    return app.exec();
}

static int runPower(QGuiApplication& app) {
    PowerManager::instance();
    qDebug() << "Rocket: Power manager started";
    return app.exec();
}

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("rocket");
    app.setOrganizationName("rocket");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Universal");
    QIcon::setThemeName("hicolor");

    QCommandLineParser parser;
    parser.setApplicationDescription("Rocket Desktop Environment");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption panelOpt("panel", "Start panel");
    QCommandLineOption launcherOpt("launcher", "Start launcher");
    QCommandLineOption overviewOpt("overview", "Start overview");
    QCommandLineOption wallpaperOpt("wallpaper", "Start wallpaper renderer");
    QCommandLineOption notifOpt("notifications", "Start notification daemon");
    QCommandLineOption clipOpt("clipboard", "Start clipboard manager");
    QCommandLineOption settingsOpt("settings", "Start settings window");
    QCommandLineOption screenshotOpt("screenshot", "Start screenshot tool");
    QCommandLineOption powerOpt("power", "Start power manager");

    parser.addOption(panelOpt);
    parser.addOption(launcherOpt);
    parser.addOption(overviewOpt);
    parser.addOption(wallpaperOpt);
    parser.addOption(notifOpt);
    parser.addOption(clipOpt);
    parser.addOption(settingsOpt);
    parser.addOption(screenshotOpt);
    parser.addOption(powerOpt);
    parser.process(app);

    qDebug() << "Rocket: Starting component... Qt" << qVersion() << "on" << app.platformName();

    if (parser.isSet(panelOpt)) return runPanel(app);
    if (parser.isSet(launcherOpt)) return runLauncher(app);
    if (parser.isSet(overviewOpt)) return runOverview(app);
    if (parser.isSet(wallpaperOpt)) return runWallpaper(app);
    if (parser.isSet(notifOpt)) return runNotifications(app);
    if (parser.isSet(clipOpt)) return runClipboard(app);
    if (parser.isSet(settingsOpt)) return runSettings(app);
    if (parser.isSet(screenshotOpt)) return runScreenshot(app);
    if (parser.isSet(powerOpt)) return runPower(app);

    qWarning() << "Rocket: No component specified. Use --panel, --launcher, etc.";
    return 0;
}
