#include "panel_window.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QQuickItem>

namespace Rocket {

PanelWindowAdaptor::PanelWindowAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void PanelWindowAdaptor::Toggle() {
    auto* w = qobject_cast<PanelWindow*>(parent());
    if (w) w->toggle();
}

void PanelWindowAdaptor::Show() {
    auto* w = qobject_cast<PanelWindow*>(parent());
    if (w) w->show();
}

void PanelWindowAdaptor::Hide() {
    auto* w = qobject_cast<PanelWindow*>(parent());
    if (w) w->hide();
}

PanelWindow::PanelWindow(QWindow* parent)
    : QQuickWindow(parent)
    , m_adaptor(new PanelWindowAdaptor(this)) {
    setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint | Qt::Tool);
    setColor(Qt::transparent);
    setTitle("Rocket Panel");

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        int sw = screen->availableGeometry().width();
        int sh = screen->availableGeometry().height();
        setGeometry(8, sh - 52, sw - 16, 44);
    }

    m_engine = new QQmlEngine(this);
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/panel/Panel.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) {
            root->setParentItem(contentItem());
        }
    } else {
        qWarning() << "Panel QML errors:" << m_component->errorString();
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("org.rocket.Panel");
    bus.registerObject("/org/rocket/Panel", this);
}

PanelWindow::~PanelWindow() {
    delete m_component;
    delete m_engine;
}

bool PanelWindow::panelVisible() const { return m_visible; }
int PanelWindow::panelHeight() const { return 44; }

void PanelWindow::show() {
    m_visible = true;
    QQuickWindow::show();
    QQuickWindow::raise();
    emit panelVisibleChanged();
}

void PanelWindow::hide() {
    m_visible = false;
    QQuickWindow::hide();
    emit panelVisibleChanged();
}

void PanelWindow::toggle() {
    if (m_visible) hide();
    else show();
}

}
