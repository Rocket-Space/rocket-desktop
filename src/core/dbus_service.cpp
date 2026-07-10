#include "dbus_service.h"
#include <QDBusMessage>
#include <QDBusInterface>

namespace Rocket {

DBusService::DBusService(QObject* parent)
    : QObject(parent)
    , m_conn(QDBusConnection::sessionBus())
{
}

DBusService::~DBusService() {
}

bool DBusService::registerService(const QString& serviceName) {
    return m_conn.registerService(serviceName);
}

bool DBusService::registerObject(const QString& path, QObject* obj) {
    return m_conn.registerObject(path, obj, QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals);
}

bool DBusService::connectSignal(const QString& service, const QString& path,
                                 const QString& iface, const QString& signal,
                                 QObject* receiver, const char* slot) {
    return m_conn.connect(service, path, iface, signal, receiver, slot);
}

void DBusService::emitSignal(const QString& path, const QString& iface,
                              const QString& signal, const QVariantList& args) {
    QDBusMessage msg = QDBusMessage::createSignal(path, iface, signal);
    msg.setArguments(args);
    m_conn.send(msg);
}

QDBusConnection DBusService::connection() const {
    return m_conn;
}

}
