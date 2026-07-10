#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include "core/session.h"
#include "core/shell.h"
#include "core/config_manager.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("rocket");
    app.setOrganizationName("rocket");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Universal");
    QIcon::setThemeName("hicolor");

    Rocket::ConfigManager::instance().load();

    QQmlApplicationEngine engine;

    Rocket::Session session;
    Rocket::Shell shell;

    engine.rootContext()->setContextProperty("rocketSession", &session);
    engine.rootContext()->setContextProperty("rocketShell", &shell);

    session.start();

    return app.exec();
}
