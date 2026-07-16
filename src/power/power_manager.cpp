#include "power_manager.h"
#include <QDBusConnection>
#include <QDBusError>
#include <QDBusInterface>
#include <QDBusPendingCall>

PowerManager* PowerManager::s_instance = nullptr;

PowerManager* PowerManager::instance() {
    if (!s_instance) {
        s_instance = new PowerManager();
    }
    return s_instance;
}

PowerManager::PowerManager(QObject* parent)
    : QObject(parent)
    , m_adaptor(new PowerManagerAdaptor(this)) {
    updateCapabilities();

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerService("org.rocket.Power")) {
        qWarning() << "Failed to register DBus service:" << bus.lastError();
    }
    bus.registerObject("/org/rocket/Power", this);
}

bool PowerManager::canShutdown() const {
    return m_canShutdown;
}

bool PowerManager::canReboot() const {
    return m_canReboot;
}

bool PowerManager::canSuspend() const {
    return m_canSuspend;
}

bool PowerManager::canHibernate() const {
    return m_canHibernate;
}

void PowerManager::shutdown() {
    callLogin1Method("PowerOff");
}

void PowerManager::reboot() {
    callLogin1Method("Reboot");
}

void PowerManager::suspend() {
    callLogin1Method("Suspend");
}

void PowerManager::hibernate() {
    callLogin1Method("Hibernate");
}

void PowerManager::lock() {
    QDBusInterface screenSaver(
        "org.freedesktop.ScreenSaver",
        "/org/freedesktop/ScreenSaver",
        "org.freedesktop.ScreenSaver",
        QDBusConnection::sessionBus());

    if (!screenSaver.isValid()) {
        qWarning() << "ScreenSaver DBus interface not available";
        return;
    }

    screenSaver.asyncCall("Lock");
}

void PowerManager::showPowerMenu() {
    emit powerMenuRequested();
}

void PowerManager::callLogin1Method(const QString& method) {
    QDBusInterface login1(
        "org.freedesktop.login1",
        "/org/freedesktop/login1",
        "org.freedesktop.login1.Manager",
        QDBusConnection::systemBus());

    if (!login1.isValid()) return;

    QDBusPendingCall call = login1.asyncCall(method, true);
    auto* watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [](QDBusPendingCallWatcher* w) {
        w->deleteLater();
    });
}

void PowerManager::updateCapabilities() {
    QDBusInterface login1(
        "org.freedesktop.login1",
        "/org/freedesktop/login1",
        "org.freedesktop.login1.Manager",
        QDBusConnection::systemBus());

    if (!login1.isValid()) {
        m_canShutdown = false;
        m_canReboot = false;
        m_canSuspend = false;
        m_canHibernate = false;
        return;
    }

    m_canShutdown = login1.property("CanPowerOff").toString() != "na";
    m_canReboot = login1.property("CanReboot").toString() != "na";
    m_canSuspend = login1.property("CanSuspend").toString() != "na";
    m_canHibernate = login1.property("CanHibernate").toString() != "na";

    emit canShutdownChanged();
    emit canRebootChanged();
    emit canSuspendChanged();
    emit canHibernateChanged();
}

PowerManagerAdaptor::PowerManagerAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void PowerManagerAdaptor::Shutdown() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->shutdown();
}

void PowerManagerAdaptor::Reboot() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->reboot();
}

void PowerManagerAdaptor::Suspend() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->suspend();
}

void PowerManagerAdaptor::Hibernate() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->hibernate();
}

void PowerManagerAdaptor::Lock() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->lock();
}

void PowerManagerAdaptor::ShowPowerMenu() {
    auto* manager = qobject_cast<PowerManager*>(parent());
    if (manager) manager->showPowerMenu();
}
