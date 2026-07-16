#include "panel_window.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QQuickItem>
#include <LayerShellQt/Window>

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
    setColor(Qt::transparent);
    setTitle("Rocket Panel");

    // Anchor the panel to the top layer at the bottom edge, reserving its height.
    // Must be configured before the window is first shown.
    if (auto* layer = LayerShellQt::Window::get(this)) {
        layer->setLayer(LayerShellQt::Window::LayerTop);
        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorBottom |
            LayerShellQt::Window::AnchorLeft |
            LayerShellQt::Window::AnchorRight));
        layer->setExclusiveZone(panelHeight());
        layer->setMargins(QMargins(8, 0, 8, 8));
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
        layer->setScope(QStringLiteral("panel"));
    }
    resize(width(), panelHeight());

    m_engine = new QQmlEngine(this);
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/panel/Panel.qml"));
    if (!m_component->isError()) {
        QObject* obj = m_component->create();
        if (obj) {
            QQuickItem* root = qobject_cast<QQuickItem*>(obj);
            if (root) {
                root->setParentItem(contentItem());
            }
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
