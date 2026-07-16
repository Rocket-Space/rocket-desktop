#include "overview_window.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

OverviewWindowAdaptor::OverviewWindowAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void OverviewWindowAdaptor::Toggle() {
    auto* window = qobject_cast<OverviewWindow*>(parent());
    if (window) window->toggle();
}

OverviewWindow::OverviewWindow(QWindow* parent)
    : QQuickWindow(parent)
    , m_adaptor(new OverviewWindowAdaptor(this)) {
    setFlags(Qt::FramelessWindowHint | Qt::Tool | Qt::WindowStaysOnTopHint);
    setColor(Qt::transparent);
    setTitle("Rocket Overview");

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        setGeometry(screen->availableGeometry());
    }

    m_engine = new QQmlEngine(this);
    m_engine->addImportPath("qrc:/qml/common");
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/Overview.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) {
            root->setParentItem(contentItem());
        }
    } else {
        qWarning() << "Overview QML errors:" << m_component->errorString();
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.rocket.Overview")) {
        qWarning() << "Failed to register DBus service:" << bus.lastError();
    }
    bus.registerObject("/org/rocket/Overview", this);
}

OverviewWindow::~OverviewWindow() {
    delete m_component;
    delete m_engine;
}

bool OverviewWindow::overviewVisible() const {
    return m_visible;
}

QVariantList OverviewWindow::windows() const {
    return m_windows;
}

void OverviewWindow::show() {
    refreshWindows();
    m_visible = true;
    QQuickWindow::show();
    QQuickWindow::raise();
    QQuickWindow::requestActivate();
    emit overviewVisibleChanged();
}

void OverviewWindow::hide() {
    m_visible = false;
    QQuickWindow::hide();
    emit overviewVisibleChanged();
}

void OverviewWindow::toggle() {
    if (m_visible) {
        hide();
    } else {
        show();
    }
}

void OverviewWindow::refreshWindows() {
    m_windows.clear();
    emit windowsChanged();
}

void OverviewWindow::selectWindow(qint64 id) {
    Q_UNUSED(id);
    hide();
    emit windowSelected(id);
}
