#pragma once

#include <QObject>
#include <QVariantList>

namespace Rocket {

class SystemTray : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)
    Q_PROPERTY(int itemCount READ itemCount NOTIFY itemsChanged)

public:
    explicit SystemTray(QObject* parent = nullptr);

    QVariantList items() const;
    int itemCount() const;
    void refresh();

    Q_INVOKABLE void activateItem(const QString& serviceName);
    Q_INVOKABLE void secondaryActivateItem(const QString& serviceName);

signals:
    void itemsChanged();

private:
    QVariantList m_items;
};

}
