#include "shell.h"

namespace Rocket {

Shell::Shell(QObject* parent) : QObject(parent) {}
Shell::~Shell() {}

bool Shell::isOverviewVisible() const { return m_overviewVisible; }
bool Shell::isLauncherVisible() const { return m_launcherVisible; }
bool Shell::isSettingsVisible() const { return m_settingsVisible; }

void Shell::toggleOverview() {
    m_overviewVisible = !m_overviewVisible;
    emit overviewVisibleChanged();
}

void Shell::toggleLauncher() {
    m_launcherVisible = !m_launcherVisible;
    emit launcherVisibleChanged();
}

void Shell::toggleClipboard() {}

void Shell::showSettings() {
    m_settingsVisible = true;
    emit settingsVisibleChanged();
}

void Shell::hideSettings() {
    m_settingsVisible = false;
    emit settingsVisibleChanged();
}

}
