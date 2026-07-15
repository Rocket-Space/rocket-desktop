#include "status_area.h"
#include <QFile>
#include <QProcess>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QTextStream>

namespace Rocket {

StatusArea::StatusArea(QObject* parent) : QObject(parent) {
    updateBattery();
    updateNetwork();
    updateVolume();
    updateBluetooth();
    updateCpu();

    connect(&m_updateTimer, &QTimer::timeout, this, [this]() {
        updateBattery();
        updateNetwork();
        updateVolume();
        updateBluetooth();
        updateCpu();
    });
    m_updateTimer.start(3000);
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

bool StatusArea::isBluetoothEnabled() const { return m_bluetoothEnabled; }
int StatusArea::cpuUsage() const { return m_cpuUsage; }

void StatusArea::toggleMute() {
    m_muted = !m_muted;
    executeCommand("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
    emit volumeChanged();
}

void StatusArea::setVolume(int vol) {
    m_volume = qBound(0, vol, 100);
    executeCommand(QString("wpctl set-volume @DEFAULT_AUDIO_SINK@ %1").arg(m_volume / 100.0));
    emit volumeChanged();
}

void StatusArea::toggleWifi() {
    if (m_networkConnected) {
        executeCommand("nmcli radio wifi off");
    } else {
        executeCommand("nmcli radio wifi on");
    }
    m_networkConnected = !m_networkConnected;
    emit networkChanged();
}

void StatusArea::toggleBluetooth() {
    if (m_bluetoothEnabled) {
        executeCommand("bluetoothctl power off");
    } else {
        executeCommand("bluetoothctl power on");
    }
    m_bluetoothEnabled = !m_bluetoothEnabled;
    emit bluetoothChanged();
}

QString StatusArea::openTerminalWithCommand(const QString& command) {
    QString terminal = "kitty";
    if (QFile::exists("/usr/bin/alacritty")) terminal = "alacritty";
    else if (QFile::exists("/usr/bin/foot")) terminal = "foot";
    else if (QFile::exists("/usr/bin/ghostty")) terminal = "ghostty";

    QStringList args;
    if (terminal == "kitty") {
        args << command;
    } else if (terminal == "alacritty") {
        args << "-e" << "bash" << "-c" << command;
    } else {
        args << "-e" << "bash" << "-c" << command;
    }

    QProcess::startDetached(terminal, args);
    return terminal;
}

void StatusArea::updateBattery() {
    float newLevel = m_batteryLevel;
    bool newCharging = m_batteryCharging;

    QFile file("/sys/class/power_supply/BAT0/capacity");
    if (file.open(QIODevice::ReadOnly)) {
        newLevel = file.readAll().trimmed().toFloat();
        file.close();
    }

    QFile statusFile("/sys/class/power_supply/BAT0/status");
    if (statusFile.open(QIODevice::ReadOnly)) {
        newCharging = (statusFile.readAll().trimmed() == "Charging");
        statusFile.close();
    }

    if (newLevel != m_batteryLevel || newCharging != m_batteryCharging) {
        m_batteryLevel = newLevel;
        m_batteryCharging = newCharging;
        emit batteryChanged();
    }
}

void StatusArea::updateNetwork() {
    QString output = executeCommand("nmcli -t -f NAME,TYPE connection show --active | head -1");
    QString newName = output.trimmed().split(":").first();
    bool newConnected = !newName.isEmpty();

    if (newConnected != m_networkConnected || newName != m_networkName) {
        m_networkConnected = newConnected;
        m_networkName = newName;
        emit networkChanged();
    }
}

void StatusArea::updateVolume() {
    QString output = executeCommand("wpctl get-volume @DEFAULT_AUDIO_SINK@");
    int newVolume = m_volume;
    bool newMuted = m_muted;

    if (output.contains("Volume:")) {
        QRegularExpression re("Volume:\\s+(\\d+\\.?\\d*)");
        QRegularExpressionMatch match = re.match(output);
        if (match.hasMatch()) {
            newVolume = qRound(match.captured(1).toFloat() * 100);
        }
    }
    newMuted = output.contains("[MUTED]");

    if (newVolume != m_volume || newMuted != m_muted) {
        m_volume = newVolume;
        m_muted = newMuted;
        emit volumeChanged();
    }
}

void StatusArea::updateBluetooth() {
    QString output = executeCommand("bluetoothctl show | grep 'Powered:' | awk '{print $2}'");
    bool newEnabled = output.trimmed() == "yes";

    if (newEnabled != m_bluetoothEnabled) {
        m_bluetoothEnabled = newEnabled;
        emit bluetoothChanged();
    }
}

void StatusArea::updateCpu() {
    static long prevTotal = 0;
    static long prevIdle = 0;

    QFile file("/proc/stat");
    if (file.open(QIODevice::ReadOnly)) {
        QString line = file.readLine();
        file.close();

        QStringList parts = line.split(QRegularExpression("\\s+"));
        if (parts.size() >= 5) {
            long user = parts[1].toLong();
            long nice = parts[2].toLong();
            long system = parts[3].toLong();
            long idle = parts[4].toLong();
            long total = user + nice + system + idle;

            long totalDiff = total - prevTotal;
            long idleDiff = idle - prevIdle;

            if (totalDiff > 0) {
                int newUsage = qRound((1.0 - (double)idleDiff / totalDiff) * 100);
                if (newUsage != m_cpuUsage) {
                    m_cpuUsage = newUsage;
                    emit cpuChanged();
                }
            }

            prevTotal = total;
            prevIdle = idle;
        }
    }
}

QString StatusArea::executeCommand(const QString& cmd) {
    QProcess process;
    process.start("bash", QStringList() << "-c" << cmd);
    process.waitForFinished(3000);
    return QString(process.readAllStandardOutput());
}

}
