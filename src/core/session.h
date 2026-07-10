#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QList>
#include <QMap>

namespace Rocket {

class DBusService;

class Session : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(int componentCount READ componentCount NOTIFY componentCountChanged)

public:
    explicit Session(QObject* parent = nullptr);
    ~Session();

    bool isRunning() const;
    int componentCount() const;

    Q_INVOKABLE bool start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void restartComponent(const QString& name);

signals:
    void runningChanged();
    void componentCountChanged();
    void componentStarted(const QString& name);
    void componentStopped(const QString& name);
    void allComponentsReady();

private slots:
    void onComponentFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    bool m_running = false;
    QProcess* m_kwinProcess = nullptr;
    QMap<QString, QProcess*> m_components;
    DBusService* m_dbus = nullptr;
    QTimer* m_startupTimer = nullptr;

    bool startKWin();
    void startComponent(const QString& name, const QString& binary, const QStringList& args = {});
    void setupEnvironment();
    void registerDBus();
};

}
