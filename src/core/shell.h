#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QQmlApplicationEngine>
#include <QTimer>
#include <QMap>

namespace Rocket {

class Shell : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool overviewVisible READ isOverviewVisible NOTIFY overviewVisibleChanged)
    Q_PROPERTY(bool launcherVisible READ isLauncherVisible NOTIFY launcherVisibleChanged)
    Q_PROPERTY(bool settingsVisible READ isSettingsVisible NOTIFY settingsVisibleChanged)

public:
    explicit Shell(QObject* parent = nullptr);
    ~Shell();

    bool isOverviewVisible() const;
    bool isLauncherVisible() const;
    bool isSettingsVisible() const;

    Q_INVOKABLE void toggleOverview();
    Q_INVOKABLE void toggleLauncher();
    Q_INVOKABLE void toggleClipboard();
    Q_INVOKABLE void showSettings();
    Q_INVOKABLE void hideSettings();

signals:
    void overviewVisibleChanged();
    void launcherVisibleChanged();
    void settingsVisibleChanged();
    void launchApplication(const QString& desktopFile);
    void screenshotRequested();
    void screenshotRegionRequested();

private:
    bool m_overviewVisible = false;
    bool m_launcherVisible = false;
    bool m_settingsVisible = false;
};

}
