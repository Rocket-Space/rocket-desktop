#include "panel_window.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QQuickItem>
#include <QQmlContext>
#include <LayerShellQt/Window>
#include <QSizeF>
#include "panel/widgets/clock.h"
#include "panel/widgets/status_area.h"
#include "panel/widgets/taskbar.h"
#include "panel/widgets/system_tray.h"
#include "panel/widgets/workspace_indicator.h"

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

    // Create panel widget backends
    auto* clock = new Clock(this);
    auto* statusArea = new StatusArea(this);
    auto* taskbar = new Taskbar(this);
    auto* systemTray = new SystemTray(this);
    auto* workspaceIndicator = new WorkspaceIndicator(this);

    m_engine = new QQmlEngine(this);
    m_engine->addImportPath("qrc:/qml/common");
    // Expose C++ widgets to QML
    m_engine->rootContext()->setContextProperty("clock", clock);
    m_engine->rootContext()->setContextProperty("statusArea", statusArea);
    m_engine->rootContext()->setContextProperty("taskbar", taskbar);
    m_engine->rootContext()->setContextProperty("systemTray", systemTray);
    m_engine->rootContext()->setContextProperty("workspaceIndicator", workspaceIndicator);

    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/panel/Panel.qml"));
    if (!m_component->isError()) {
        QObject* obj = m_component->create();
        if (obj) {
            QQuickItem* root = qobject_cast<QQuickItem*>(obj);
            if (root) {
                root->setParentItem(contentItem());
                root->setSize(QSizeF(contentItem()->width(), contentItem()->height()));
                connect(contentItem(), &QQuickItem::widthChanged, this, [this, root]() {
                    root->setWidth(contentItem()->width());
                });
                connect(contentItem(), &QQuickItem::heightChanged, this, [this, root]() {
                    root->setHeight(contentItem()->height());
                });
            }
        }
    } else {
        qWarning() << "Panel QML errors:" << m_component->errorString();
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.rocket.Panel")) {
        qWarning() << "Failed to register DBus service:" << bus.lastError();
    }
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
