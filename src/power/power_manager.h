#pragma once

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QDBusPendingCallWatcher>

class PowerManagerAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Power")

public:
    explicit PowerManagerAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Shutdown();
    Q_SCRIPTABLE void Reboot();
    Q_SCRIPTABLE void Suspend();
    Q_SCRIPTABLE void Hibernate();
    Q_SCRIPTABLE void Lock();
    Q_SCRIPTABLE void ShowPowerMenu();
};

class PowerManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool canShutdown READ canShutdown NOTIFY canShutdownChanged)
    Q_PROPERTY(bool canReboot READ canReboot NOTIFY canRebootChanged)
    Q_PROPERTY(bool canSuspend READ canSuspend NOTIFY canSuspendChanged)
    Q_PROPERTY(bool canHibernate READ canHibernate NOTIFY canHibernateChanged)

public:
    static PowerManager* instance();

    bool canShutdown() const;
    bool canReboot() const;
    bool canSuspend() const;
    bool canHibernate() const;

    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void reboot();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void lock();
    Q_INVOKABLE void showPowerMenu();

signals:
    void canShutdownChanged();
    void canRebootChanged();
    void canSuspendChanged();
    void canHibernateChanged();
    void powerMenuRequested();

private:
    explicit PowerManager(QObject* parent = nullptr);
    ~PowerManager() override = default;
    PowerManager(const PowerManager&) = delete;
    PowerManager& operator=(const PowerManager&) = delete;

    void callLogin1Method(const QString& method);
    void updateCapabilities();

    bool m_canShutdown = true;
    bool m_canReboot = true;
    bool m_canSuspend = true;
    bool m_canHibernate = true;
    PowerManagerAdaptor* m_adaptor;
    static PowerManager* s_instance;
};
