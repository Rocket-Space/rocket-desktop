#include "wayland_helpers.h"
#include <KWindowSystem>

namespace Rocket {

WaylandHelpers& WaylandHelpers::instance() {
    static WaylandHelpers inst;
    return inst;
}

WaylandHelpers::WaylandHelpers(QObject* parent) : QObject(parent) {}

QString WaylandHelpers::currentDesktop() const {
    return "Rocket";
}

int WaylandHelpers::workspaceCount() const { return m_workspaceCount; }
int WaylandHelpers::currentWorkspace() const { return m_currentWorkspace; }

void WaylandHelpers::switchWorkspace(int index) {
    if (index >= 0 && index < m_workspaceCount) {
        m_currentWorkspace = index;
    }
}

QVariantList WaylandHelpers::runningWindows() const {
    QVariantList windows;
    return windows;
}

void WaylandHelpers::focusWindow(const QString& title) {
    Q_UNUSED(title);
}

void WaylandHelpers::closeWindow(const QString& title) {
    Q_UNUSED(title);
}

void WaylandHelpers::maximizeWindow(const QString& title) {
    Q_UNUSED(title);
}

void WaylandHelpers::minimizeWindow(const QString& title) {
    Q_UNUSED(title);
}

void WaylandHelpers::tileWindowLeft(const QString& title) {
    Q_UNUSED(title);
}

void WaylandHelpers::tileWindowRight(const QString& title) {
    Q_UNUSED(title);
}

}
