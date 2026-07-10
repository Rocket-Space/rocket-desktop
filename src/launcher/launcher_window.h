#pragma once

#include <QQuickWindow>
#include <QJsonObject>
#include <QDBusAbstractAdaptor>

class QQmlEngine;
class QQmlComponent;
class AppDatabase;

class LauncherWindowAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Launcher")

public:
    explicit LauncherWindowAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Toggle();
    Q_SCRIPTABLE void Search(const QString& query);
    Q_SCRIPTABLE void LaunchApp(const QString& desktopFile);
};

class LauncherWindow : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(bool launcherVisible READ launcherVisible WRITE setLauncherVisible NOTIFY launcherVisibleChanged)
    Q_PROPERTY(int launcherWidth READ launcherWidth CONSTANT)
    Q_PROPERTY(int launcherHeight READ launcherHeight CONSTANT)

public:
    explicit LauncherWindow(QWindow* parent = nullptr);
    ~LauncherWindow() override;

    bool launcherVisible() const;
    void setLauncherVisible(bool visible);
    int launcherWidth() const;
    int launcherHeight() const;

    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE QJsonArray searchApps(const QString& query);

signals:
    void launcherVisibleChanged();
    void appLaunched(const QString& desktopFile);

private:
    bool m_visible = false;
    LauncherWindowAdaptor* m_adaptor;
    AppDatabase* m_database;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};
