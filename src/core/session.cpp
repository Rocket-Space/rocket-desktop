#include "session.h"
#include "dbus_service.h"
#include "config_manager.h"
#include "dbus_paths.h"
#include <QCoreApplication>
#include <QProcessEnvironment>
#include <QDir>
#include <QDebug>

namespace Rocket {

Session::Session(QObject* parent)
    : QObject(parent)
    , m_dbus(new DBusService(this))
{
}

Session::~Session() { stop(); }

bool Session::isRunning() const { return m_running; }
int Session::componentCount() const { return m_components.size(); }

void Session::setupEnvironment() {
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("XDG_CURRENT_DESKTOP", "Rocket");
    qputenv("XDG_SESSION_TYPE", "wayland");
    qputenv("ROCKET_VERSION", "1.0.0");
}

void Session::registerDBus() {
    m_dbus->registerService(Rocket::DBUS_SERVICE);
}

bool Session::startKWin() {
    m_kwinProcess = new QProcess(this);
    connect(m_kwinProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &Session::onComponentFinished);

    QString kwinBin = "/usr/bin/kwin_wayland";

    if (!QFile::exists(kwinBin)) {
        qCritical() << "KWin not found at" << kwinBin;
        return false;
    }

    QStringList args;
    args << "--no-lockscreen"
         << "--no-global-shortcuts"
         << "--locale1"
         << "--xwayland"
         << "--inputmethod"
         << "MESA_LOADER_DRIVER_OVERRIDE=zink NVIDIA EGLImplementation=eglangle"
         << "--socket", "rocket-kwin";

    m_kwinProcess->start(kwinBin, args);
    if (!m_kwinProcess->waitForStarted(5000)) {
        qCritical() << "Failed to start KWin";
        return false;
    }

    m_components["kwin"] = m_kwinProcess;
    emit componentStarted("kwin");
    return true;
}

void Session::startComponent(const QString& name, const QString& binary, const QStringList& args) {
    if (m_components.contains(name)) return;

    QProcess* proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &Session::onComponentFinished);

    proc->start(binary, args);
    if (proc->waitForStarted(3000)) {
        m_components[name] = proc;
        emit componentStarted(name);
        emit componentCountChanged();
    } else {
        qWarning() << "Failed to start component:" << name << "at" << binary;
        delete proc;
    }
}

bool Session::start() {
    if (m_running) return true;

    setupEnvironment();
    registerDBus();

    ConfigManager::instance().load();

    if (!startKWin()) return false;

    QTimer::singleShot(1000, this, [this]() {
        QString bin = QCoreApplication::applicationDirPath();

        startComponent("panel", bin + "/rocket-panel");
        startComponent("notifications", bin + "/rocket-notifications");
        startComponent("wallpaper", bin + "/rocket-wallpaper");
        startComponent("clipboard", bin + "/rocket-clipboard");
        startComponent("screenshot", bin + "/rocket-screenshot");

        m_running = true;
        emit runningChanged();

        QTimer::singleShot(2000, this, &Session::allComponentsReady);
    });

    return true;
}

void Session::stop() {
    for (auto it = m_components.begin(); it != m_components.end(); ++it) {
        if (it.value() && it.value()->state() != QProcess::NotRunning) {
            it.value()->terminate();
            it.value()->waitForFinished(3000);
            if (it.value()->state() != QProcess::NotRunning)
                it.value()->kill();
        }
    }

    qDeleteAll(m_components);
    m_components.clear();
    m_running = false;
    emit runningChanged();
    emit componentCountChanged();
}

void Session::restartComponent(const QString& name) {
    if (m_components.contains(name)) {
        QProcess* old = m_components.take(name);
        old->terminate();
        old->waitForFinished(2000);
        delete old;
    }
}

void Session::onComponentFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    QProcess* proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    QString name;
    for (auto it = m_components.begin(); it != m_components.end(); ++it) {
        if (it.value() == proc) {
            name = it.key();
            break;
        }
    }

    if (!name.isEmpty()) {
        qWarning() << "Component" << name << "exited with code" << exitCode;
        m_components.remove(name);
        emit componentStopped(name);
        emit componentCountChanged();

        if (name == "kwin") {
            stop();
        } else if (name == "panel") {
            QTimer::singleShot(1000, this, [this]() {
                startComponent("panel", QCoreApplication::applicationDirPath() + "/rocket-panel");
            });
        }
    }
}

}
