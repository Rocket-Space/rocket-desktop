#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QList>
#include <QDBusAbstractAdaptor>
#include <QDBusMessage>

struct Notification {
    uint id;
    QString appName;
    QString appIcon;
    QString summary;
    QString body;
    QStringList actions;
    qint64 timestamp;
    uint replacesId;
};

class NotificationDaemon;

class NotificationDaemonAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")

public:
    explicit NotificationDaemonAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE uint Notify(const QString& app_name,
                             uint replaces_id,
                             const QString& app_icon,
                             const QString& summary,
                             const QString& body,
                             const QStringList& actions,
                             const QVariantMap& hints,
                             int expire_timeout);
    Q_SCRIPTABLE void CloseNotification(uint id);
    Q_SCRIPTABLE QStringList GetCapabilities();
    Q_SCRIPTABLE QStringList GetServerInformation();
};

class NotificationDaemon : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    friend class NotificationDaemonAdaptor;

public:
    static NotificationDaemon* instance();

    int count() const;
    QList<Notification> notifications() const;
    Q_INVOKABLE QJsonArray getNotificationsJson() const;

    uint nextId();
    void addNotification(const Notification& notification);

signals:
    void countChanged();
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString& action_key);
    void notificationAdded(const QJsonObject& notification);

private:
    explicit NotificationDaemon(QObject* parent = nullptr);
    ~NotificationDaemon() override = default;
    NotificationDaemon(const NotificationDaemon&) = delete;
    NotificationDaemon& operator=(const NotificationDaemon&) = delete;

    QList<Notification> m_notifications;
    uint m_nextId = 1;
    NotificationDaemonAdaptor* m_adaptor;
    static NotificationDaemon* s_instance;
};
