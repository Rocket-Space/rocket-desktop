#pragma once

#include <QObject>
#include <QDBusConnection>
#include <QString>

namespace Rocket {

class DBusService : public QObject {
    Q_OBJECT
public:
    explicit DBusService(QObject* parent = nullptr);
    ~DBusService();

    bool registerService(const QString& serviceName);
    bool registerObject(const QString& path, QObject* obj);
    bool connectSignal(const QString& service, const QString& path,
                       const QString& iface, const QString& signal,
                       QObject* receiver, const char* slot);

    void emitSignal(const QString& path, const QString& iface,
                    const QString& signal, const QVariantList& args = {});

    QDBusConnection connection() const;

private:
    QDBusConnection m_conn;
};

}
