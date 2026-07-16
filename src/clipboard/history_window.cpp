#include "history_window.h"
#include "manager.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QDBusError>
#include <QClipboard>
#include <QJsonObject>
#include <QJsonArray>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

ClipboardHistoryWindowAdaptor::ClipboardHistoryWindowAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void ClipboardHistoryWindowAdaptor::Toggle() {
    auto* window = qobject_cast<ClipboardHistoryWindow*>(parent());
    if (window) window->toggle();
}

ClipboardHistoryWindow::ClipboardHistoryWindow(QWindow* parent)
    : QQuickWindow(parent)
    , m_manager(ClipboardManager::instance())
    , m_adaptor(new ClipboardHistoryWindowAdaptor(this)) {
    setWidth(350);
    setHeight(500);
    setFlags(Qt::FramelessWindowHint | Qt::Popup | Qt::WindowStaysOnTopHint);
    setColor(Qt::transparent);
    setTitle("Clipboard History");

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        int screenW = screen->availableGeometry().width();
        int screenH = screen->availableGeometry().height();
        setPosition((screenW - width()) / 2, (screenH - height()) / 2);
    }

    m_engine = new QQmlEngine(this);
    m_engine->addImportPath("qrc:/qml/common");
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/ClipboardHistory.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) root->setParentItem(contentItem());
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.rocket.Clipboard.History")) {
        qWarning() << "Failed to register DBus service:" << bus.lastError();
    }
    bus.registerObject("/org/rocket/Clipboard/History", this);
}

ClipboardHistoryWindow::~ClipboardHistoryWindow() {
    delete m_component;
    delete m_engine;
}

bool ClipboardHistoryWindow::historyVisible() const {
    return m_visible;
}

void ClipboardHistoryWindow::show() {
    m_visible = true;
    QQuickWindow::show();
    QQuickWindow::raise();
    QQuickWindow::requestActivate();
    emit historyVisibleChanged();
}

void ClipboardHistoryWindow::hide() {
    m_visible = false;
    QQuickWindow::hide();
    emit historyVisibleChanged();
}

void ClipboardHistoryWindow::toggle() {
    if (m_visible) hide();
    else show();
}

void ClipboardHistoryWindow::copyItem(int index) {
    QString text = m_manager->getItem(index);
    if (!text.isEmpty()) {
        m_manager->copyToClipboard(text);
        hide();
    }
}
