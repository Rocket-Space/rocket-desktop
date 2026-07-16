#include "launcher_window.h"
#include "app_database.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QJsonArray>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

LauncherWindowAdaptor::LauncherWindowAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void LauncherWindowAdaptor::Toggle() {
    auto* window = qobject_cast<LauncherWindow*>(parent());
    if (window) window->toggle();
}

void LauncherWindowAdaptor::Search(const QString& query) {
    Q_UNUSED(query)
}

void LauncherWindowAdaptor::LaunchApp(const QString& desktopFile) {
    AppDatabase::instance()->launchByDesktopFile(desktopFile);
    auto* window = qobject_cast<LauncherWindow*>(parent());
    if (window) {
        window->hide();
        emit window->appLaunched(desktopFile);
    }
}

LauncherWindow::LauncherWindow(QWindow* parent)
    : QQuickWindow(parent)
    , m_adaptor(new LauncherWindowAdaptor(this))
    , m_database(AppDatabase::instance()) {
    setWidth(600);
    setHeight(400);
    setTitle("Rocket Launcher");
    setFlags(Qt::FramelessWindowHint | Qt::Popup | Qt::WindowStaysOnTopHint);
    setColor(Qt::transparent);

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        int screenW = screen->availableGeometry().width();
        int screenH = screen->availableGeometry().height();
        setPosition((screenW - width()) / 2, (screenH - height()) / 2);
    }

    m_engine = new QQmlEngine(this);
    m_engine->addImportPath("qrc:/qml/common");
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/Launcher.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) {
            root->setParentItem(contentItem());
        }
    } else {
        qWarning() << "Launcher QML errors:" << m_component->errorString();
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.rocket.Launcher")) {
        qWarning() << "Failed to register DBus service:" << bus.lastError();
    }
    bus.registerObject("/org/rocket/Launcher", this);
}

LauncherWindow::~LauncherWindow() {
    delete m_component;
    delete m_engine;
}

bool LauncherWindow::launcherVisible() const {
    return m_visible;
}

void LauncherWindow::setLauncherVisible(bool visible) {
    if (m_visible == visible) return;
    m_visible = visible;
    emit launcherVisibleChanged();
}

int LauncherWindow::launcherWidth() const {
    return 600;
}

int LauncherWindow::launcherHeight() const {
    return 400;
}

void LauncherWindow::show() {
    setLauncherVisible(true);
    QQuickWindow::show();
    requestActivate();
}

void LauncherWindow::hide() {
    setLauncherVisible(false);
    QQuickWindow::hide();
}

void LauncherWindow::toggle() {
    if (m_visible) {
        hide();
    } else {
        show();
    }
}

QJsonArray LauncherWindow::searchApps(const QString& query) {
    return m_database->search(query);
}
