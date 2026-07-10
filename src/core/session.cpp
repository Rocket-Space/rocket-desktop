#include "session.h"
#include "dbus_service.h"
#include "config_manager.h"
#include "dbus_paths.h"
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
#include <QCoreApplication>
#include <QDir>
#include <QDebug>

Session::Session(QObject* parent)
    : QObject(parent)
    , m_dbus(new Rocket::DBusService(this))
{
}

Session::~Session() { stop(); }

bool Session::isRunning() const { return m_running; }
int Session::componentCount() const { return m_components.size(); }

void Session::setupEnvironment() {
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("XDG_CURRENT_DESKTOP", "Rocket");
    qputenv("XDG_SESSION_TYPE", "wayland");
    qputenv("ROCKET_VERSION", "1.0.0");
}

void Session::registerDBus() {
    m_dbus->registerService(Rocket::DBUS_SERVICE);
}

bool Session::startKWin() {
    m_kwinProcess = new QProcess(this);
    connect(m_kwinProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &Session::onComponentFinished);

    QString kwinBin = "/usr/bin/kwin_wayland";

    if (!QFile::exists(kwinBin)) {
        qCritical() << "Rocket: KWin not found at" << kwinBin;
        return false;
    }

    QStringList args;
    args << "--no-lockscreen"
         << "--no-global-shortcuts"
         << "--locale1"
         << "--xwayland";

    qDebug() << "Rocket: Starting KWin from" << kwinBin << args;

    m_kwinProcess->start(kwinBin, args);
    if (!m_kwinProcess->waitForStarted(5000)) {
        qCritical() << "Rocket: Failed to start KWin";
        return false;
    }

    m_components["kwin"] = m_kwinProcess;
    emit componentStarted("kwin");
    return true;
}

void Session::startComponents() {
    qDebug() << "Rocket: Starting components...";

    m_panelWindow = new Rocket::PanelWindow(this);
    m_panelWindow->show();

    NotificationDaemon::instance();

    m_wallpaperWindow = new WallpaperRenderer();
    m_wallpaperWindow->show();

    ClipboardManager::instance();

    m_launcherWindow = new LauncherWindow();
    m_launcherWindow->hide();

    m_overviewWindow = new OverviewWindow();
    m_overviewWindow->hide();

    m_settingsWindow = new SettingsWindow();
    m_settingsWindow->hide();

    m_clipboardWindow = new ClipboardHistoryWindow();
    m_clipboardWindow->hide();

    ScreenshotTool::instance();

    m_running = true;
    emit runningChanged();
    emit componentCountChanged();

    qDebug() << "Rocket: All components started";
}

bool Session::start() {
    if (m_running) return true;

    setupEnvironment();
    registerDBus();
    Rocket::ConfigManager::instance().load();

    if (!startKWin()) {
        qCritical() << "Rocket: Cannot start without KWin";
        return false;
    }

    QTimer::singleShot(2000, this, &Session::startComponents);

    return true;
}

void Session::stop() {
    m_running = false;

    delete m_panelWindow; m_panelWindow = nullptr;
    delete m_wallpaperWindow; m_wallpaperWindow = nullptr;
    delete m_launcherWindow; m_launcherWindow = nullptr;
    delete m_overviewWindow; m_overviewWindow = nullptr;
    delete m_settingsWindow; m_settingsWindow = nullptr;
    delete m_clipboardWindow; m_clipboardWindow = nullptr;

    for (auto it = m_components.begin(); it != m_components.end(); ++it) {
        if (it.value() && it.value()->state() != QProcess::NotRunning) {
            it.value()->terminate();
            it.value()->waitForFinished(3000);
            if (it.value()->state() != QProcess::NotRunning)
                it.value()->kill();
        }
    }

    qDeleteAll(m_components);
    m_components.clear();

    emit runningChanged();
    emit componentCountChanged();
}

void Session::restartComponent(const QString& name) {
    Q_UNUSED(name);
}

void Session::onComponentFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    Q_UNUSED(exitStatus);
    QProcess* proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    QString name;
    for (auto it = m_components.begin(); it != m_components.end(); ++it) {
        if (it.value() == proc) {
            name = it.key();
            break;
        }
    }

    if (!name.isEmpty()) {
        qWarning() << "Rocket: Component" << name << "exited with code" << exitCode;
        m_components.remove(name);
        emit componentStopped(name);
        emit componentCountChanged();

        if (name == "kwin") {
            qDebug() << "Rocket: KWin exited, shutting down";
            stop();
        }
    }
}
