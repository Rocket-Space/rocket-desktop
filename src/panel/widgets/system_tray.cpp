#include "system_tray.h"
#include <QJsonObject>

namespace Rocket {

SystemTray::SystemTray(QObject* parent) : QObject(parent) {}

QVariantList SystemTray::items() const { return m_items; }
int SystemTray::itemCount() const { return m_items.size(); }

void SystemTray::refresh() {
    m_items.clear();
    emit itemsChanged();
}

void SystemTray::activateItem(const QString& serviceName) {
    Q_UNUSED(serviceName);
}

void SystemTray::secondaryActivateItem(const QString& serviceName) {
    Q_UNUSED(serviceName);
}

}
