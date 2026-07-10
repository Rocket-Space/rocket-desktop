#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDebug>
#include "core/session.h"
#include "core/config_manager.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("rocket");
    app.setOrganizationName("rocket");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Universal");
    QIcon::setThemeName("hicolor");

    qDebug() << "Rocket: Starting...";
    qDebug() << "Rocket: Qt version" << qVersion();
    qDebug() << "Rocket: Platform" << qApp->platformName();

    Rocket::ConfigManager::instance().load();

    Session session;

    QObject::connect(&session, &Session::componentStarted, [](const QString& name) {
        qDebug() << "Rocket: Component started:" << name;
    });

    QObject::connect(&session, &Session::componentStopped, [](const QString& name) {
        qDebug() << "Rocket: Component stopped:" << name;
    });

    if (!session.start()) {
        qCritical() << "Rocket: Failed to start session";
        return 1;
    }

    qDebug() << "Rocket: Session started, entering event loop";

    return app.exec();
}
