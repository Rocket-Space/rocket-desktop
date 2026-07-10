#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QMap>
#include "dbus_service.h"
#include "config_manager.h"

namespace Rocket { class PanelWindow; }
class WallpaperRenderer;
class LauncherWindow;
class OverviewWindow;
class SettingsWindow;
class ClipboardHistoryWindow;

class Session : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(int componentCount READ componentCount NOTIFY componentCountChanged)

public:
    explicit Session(QObject* parent = nullptr);
    ~Session();

    bool isRunning() const;
    int componentCount() const;

    Q_INVOKABLE bool start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void restartComponent(const QString& name);

signals:
    void runningChanged();
    void componentCountChanged();
    void componentStarted(const QString& name);
    void componentStopped(const QString& name);
    void allComponentsReady();

private slots:
    void onComponentFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void startComponents();

private:
    bool m_running = false;
    QProcess* m_kwinProcess = nullptr;
    QMap<QString, QProcess*> m_components;
    Rocket::DBusService* m_dbus = nullptr;

    Rocket::PanelWindow* m_panelWindow = nullptr;
    WallpaperRenderer* m_wallpaperWindow = nullptr;
    LauncherWindow* m_launcherWindow = nullptr;
    OverviewWindow* m_overviewWindow = nullptr;
    SettingsWindow* m_settingsWindow = nullptr;
    ClipboardHistoryWindow* m_clipboardWindow = nullptr;

    bool startKWin();
    void setupEnvironment();
    void registerDBus();
};
