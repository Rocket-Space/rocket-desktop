#include "daemon.h"
#include <QDBusConnection>
#include <QDBusError>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QJsonDocument>

NotificationDaemon* NotificationDaemon::s_instance = nullptr;

NotificationDaemon* NotificationDaemon::instance() {
    if (!s_instance) {
        s_instance = new NotificationDaemon();
    }
    return s_instance;
}

NotificationDaemon::NotificationDaemon(QObject* parent)
    : QObject(parent)
    , m_adaptor(new NotificationDaemonAdaptor(this)) {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.freedesktop.Notifications")) {
        qWarning() << "Failed to register DBus notification service:" << bus.lastError();
    }
    bus.registerObject("/org/freedesktop/Notifications", this);
}

int NotificationDaemon::count() const {
    return m_notifications.size();
}

QList<Notification> NotificationDaemon::notifications() const {
    return m_notifications;
}

QJsonArray NotificationDaemon::getNotificationsJson() const {
    QJsonArray arr;
    for (const Notification& n : m_notifications) {
        QJsonObject obj;
        obj["id"] = static_cast<qint64>(n.id);
        obj["appName"] = n.appName;
        obj["appIcon"] = n.appIcon;
        obj["summary"] = n.summary;
        obj["body"] = n.body;
        obj["timestamp"] = n.timestamp;
        obj["actions"] = QJsonArray::fromStringList(n.actions);
        arr.append(obj);
    }
    return arr;
}

uint NotificationDaemon::nextId() {
    return m_nextId++;
}

void NotificationDaemon::addNotification(const Notification& notification) {
    m_notifications.append(notification);
    emit countChanged();

    QJsonObject obj;
    obj["id"] = static_cast<qint64>(notification.id);
    obj["appName"] = notification.appName;
    obj["appIcon"] = notification.appIcon;
    obj["summary"] = notification.summary;
    obj["body"] = notification.body;
    obj["timestamp"] = notification.timestamp;
    obj["actions"] = QJsonArray::fromStringList(notification.actions);
    emit notificationAdded(obj);
}

NotificationDaemonAdaptor::NotificationDaemonAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

uint NotificationDaemonAdaptor::Notify(const QString& app_name,
                                       uint replaces_id,
                                       const QString& app_icon,
                                       const QString& summary,
                                       const QString& body,
                                       const QStringList& actions,
                                       const QVariantMap& hints,
                                       int expire_timeout) {
    Q_UNUSED(hints)
    Q_UNUSED(expire_timeout)

    auto* daemon = qobject_cast<NotificationDaemon*>(parent());
    if (!daemon) return 0;

    if (replaces_id > 0) {
        for (int i = 0; i < daemon->m_notifications.size(); ++i) {
            if (daemon->m_notifications[i].id == replaces_id) {
                Notification& n = daemon->m_notifications[i];
                n.appName = app_name;
                n.appIcon = app_icon;
                n.summary = summary;
                n.body = body;
                n.actions = actions;
                n.timestamp = QDateTime::currentMSecsSinceEpoch();

                QJsonObject obj;
                obj["id"] = static_cast<qint64>(n.id);
                obj["appName"] = n.appName;
                obj["appIcon"] = n.appIcon;
                obj["summary"] = n.summary;
                obj["body"] = n.body;
                obj["timestamp"] = n.timestamp;
                emit daemon->notificationAdded(obj);
                return n.id;
            }
        }
    }

    Notification notification;
    notification.id = daemon->nextId();
    notification.appName = app_name;
    notification.appIcon = app_icon;
    notification.summary = summary;
    notification.body = body;
    notification.actions = actions;
    notification.timestamp = QDateTime::currentMSecsSinceEpoch();
    notification.replacesId = replaces_id;

    daemon->addNotification(notification);
    return notification.id;
}

void NotificationDaemonAdaptor::CloseNotification(uint id) {
    auto* daemon = qobject_cast<NotificationDaemon*>(parent());
    if (!daemon) return;

    for (int i = 0; i < daemon->m_notifications.size(); ++i) {
        if (daemon->m_notifications[i].id == id) {
            daemon->m_notifications.removeAt(i);
            emit daemon->NotificationClosed(id, 3);
            emit daemon->countChanged();
            return;
        }
    }
}

QStringList NotificationDaemonAdaptor::GetCapabilities() {
    return {
        "body",
        "body-markup",
        "actions",
        "persistence",
        "icon-static"
    };
}

QStringList NotificationDaemonAdaptor::GetServerInformation() {
    return {
        "Rocket Notification Server",
        "Rocket",
        "1.0.0",
        "1.2"
    };
}
