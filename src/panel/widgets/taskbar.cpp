#include "taskbar.h"
#include <KWindowSystem>
#include <KWindowInfo>

namespace Rocket {

Taskbar::Taskbar(QObject* parent) : QObject(parent) {
    connect(KWindowSystem::self(), &KWindowSystem::showingDesktopChanged, this, &Taskbar::refresh);
    refresh();
}

QVariantList Taskbar::windows() const { return m_windows; }

void Taskbar::refresh() {
    m_windows.clear();
    emit windowsChanged();
}

void Taskbar::focusWindow(qint64 id) {
    Q_UNUSED(id);
}

void Taskbar::closeWindow(qint64 id) {
    Q_UNUSED(id);
}

void Taskbar::minimizeWindow(qint64 id) {
    Q_UNUSED(id);
}

}
