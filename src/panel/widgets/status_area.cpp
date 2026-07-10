#include "status_area.h"
#include <QFile>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>

namespace Rocket {

StatusArea::StatusArea(QObject* parent) : QObject(parent) {
    updateBattery();
    updateNetwork();
    updateVolume();
}

float StatusArea::batteryLevel() const { return m_batteryLevel; }
bool StatusArea::isBatteryCharging() const { return m_batteryCharging; }
QString StatusArea::batteryIcon() const {
    if (m_batteryCharging) return "battery-full-charged";
    if (m_batteryLevel > 75) return "battery-full";
    if (m_batteryLevel > 50) return "battery-good";
    if (m_batteryLevel > 25) return "battery-low";
    return "battery-caution";
}

bool StatusArea::isNetworkConnected() const { return m_networkConnected; }
QString StatusArea::networkIcon() const { return m_networkConnected ? "network-wireless" : "network-offline"; }
QString StatusArea::networkName() const { return m_networkName; }

int StatusArea::volume() const { return m_volume; }
bool StatusArea::isMuted() const { return m_muted; }
QString StatusArea::volumeIcon() const {
    if (m_muted || m_volume == 0) return "audio-volume-muted";
    if (m_volume < 33) return "audio-volume-low";
    if (m_volume < 66) return "audio-volume-medium";
    return "audio-volume-high";
}

void StatusArea::toggleMute() {
    m_muted = !m_muted;
    emit volumeChanged();
}

void StatusArea::setVolume(int vol) {
    m_volume = qBound(0, vol, 100);
    emit volumeChanged();
}

void StatusArea::toggleWifi() {
    m_networkConnected = !m_networkConnected;
    emit networkChanged();
}

void StatusArea::updateBattery() {
    QFile file("/sys/class/power_supply/BAT0/capacity");
    if (file.open(QIODevice::ReadOnly)) {
        m_batteryLevel = file.readAll().trimmed().toFloat();
        file.close();
    }

    QFile statusFile("/sys/class/power_supply/BAT0/status");
    if (statusFile.open(QIODevice::ReadOnly)) {
        m_batteryCharging = (statusFile.readAll().trimmed() == "Charging");
        statusFile.close();
    }

    emit batteryChanged();
}

void StatusArea::updateNetwork() {
    emit networkChanged();
}

void StatusArea::updateVolume() {
    emit volumeChanged();
}

}
