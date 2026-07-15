#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

namespace Rocket {

class StatusArea : public QObject {
    Q_OBJECT
    Q_PROPERTY(float batteryLevel READ batteryLevel NOTIFY batteryChanged)
    Q_PROPERTY(bool batteryCharging READ isBatteryCharging NOTIFY batteryChanged)
    Q_PROPERTY(QString batteryIcon READ batteryIcon NOTIFY batteryChanged)
    Q_PROPERTY(bool networkConnected READ isNetworkConnected NOTIFY networkChanged)
    Q_PROPERTY(QString networkIcon READ networkIcon NOTIFY networkChanged)
    Q_PROPERTY(QString networkName READ networkName NOTIFY networkChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ isMuted NOTIFY volumeChanged)
    Q_PROPERTY(QString volumeIcon READ volumeIcon NOTIFY volumeChanged)
    Q_PROPERTY(bool bluetoothEnabled READ isBluetoothEnabled NOTIFY bluetoothChanged)
    Q_PROPERTY(int cpuUsage READ cpuUsage NOTIFY cpuChanged)

public:
    explicit StatusArea(QObject* parent = nullptr);

    float batteryLevel() const;
    bool isBatteryCharging() const;
    QString batteryIcon() const;
    bool isNetworkConnected() const;
    QString networkIcon() const;
    QString networkName() const;
    int volume() const;
    bool isMuted() const;
    QString volumeIcon() const;
    bool isBluetoothEnabled() const;
    int cpuUsage() const;

    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void setVolume(int vol);
    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE QString openTerminalWithCommand(const QString& command);

signals:
    void batteryChanged();
    void networkChanged();
    void volumeChanged();
    void bluetoothChanged();
    void cpuChanged();
    void openTerminal(QString command);

private:
    float m_batteryLevel = 100.0f;
    bool m_batteryCharging = false;
    bool m_networkConnected = true;
    QString m_networkName = "Connected";
    int m_volume = 75;
    bool m_muted = false;
    bool m_bluetoothEnabled = false;
    int m_cpuUsage = 0;
    QTimer m_updateTimer;

    void updateBattery();
    void updateNetwork();
    void updateVolume();
    void updateBluetooth();
    void updateCpu();
    QString executeCommand(const QString& cmd);
};

}
