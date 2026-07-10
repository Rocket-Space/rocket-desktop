#include "popup.h"
#include <QScreen>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

NotificationPopup* NotificationPopup::s_instance = nullptr;

NotificationPopup* NotificationPopup::instance() {
    if (!s_instance) {
        s_instance = new NotificationPopup();
    }
    return s_instance;
}

NotificationPopup::NotificationPopup(QObject* parent)
    : QObject(parent) {}

int NotificationPopup::visibleCount() const {
    return m_popups.size();
}

void NotificationPopup::showNotification(const QJsonObject& notification) {
    const qint64 id = notification["id"].toVariant().toLongLong();

    if (m_popups.contains(id)) return;

    if (m_popups.size() >= MAX_VISIBLE) {
        qint64 oldestId = m_popups.keys().first();
        hideNotification(oldestId);
    }

    auto* window = new QQuickWindow();
    window->setFlags(Qt::FramelessWindowHint | Qt::Tool | Qt::WindowStaysOnTopHint);
    window->setColor(Qt::transparent);
    window->setTitle("Notification");

    auto* engine = new QQmlEngine(window);
    auto* component = new QQmlComponent(engine, QUrl("qrc:/qml/NotificationPopup.qml"));
    if (!component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(component->create());
        if (root) root->setParentItem(window->contentItem());
    }

    m_popups[id] = window;

    positionWindows();
    window->show();
    window->requestActivate();

    auto* timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(AUTO_HIDE_MS);
    connect(timer, &QTimer::timeout, this, [this, id]() {
        hideNotification(id);
    });
    m_timers[id] = timer;
    timer->start();

    emit visibleCountChanged();
}

void NotificationPopup::hideNotification(qint64 id) {
    if (!m_popups.contains(id)) return;

    if (m_timers.contains(id)) {
        m_timers[id]->stop();
        m_timers[id]->deleteLater();
        m_timers.remove(id);
    }

    QQuickWindow* window = m_popups.take(id);
    if (window) {
        window->close();
        window->deleteLater();
    }

    positionWindows();
    emit visibleCountChanged();
    emit notificationDismissed(id);
}

void NotificationPopup::positionWindows() {
    QScreen* screen = QGuiApplication::primaryScreen();
    if (!screen) return;

    const QRect screenGeometry = screen->availableGeometry();
    int x = screenGeometry.right() - POPUP_MARGIN - POPUP_WIDTH;
    int y = screenGeometry.top() + POPUP_MARGIN;

    const QList<qint64> ids = m_popups.keys();
    for (qint64 id : ids) {
        QQuickWindow* window = m_popups.value(id);
        if (window) {
            window->setGeometry(x, y, POPUP_WIDTH, POPUP_HEIGHT);
            y += POPUP_HEIGHT + POPUP_SPACING;
        }
    }
}
