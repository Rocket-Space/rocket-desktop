#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QJsonObject>
#include <QMap>
#include <QTimer>

class NotificationPopup : public QObject {
    Q_OBJECT
    Q_PROPERTY(int visibleCount READ visibleCount NOTIFY visibleCountChanged)

public:
    static NotificationPopup* instance();

    int visibleCount() const;

    Q_INVOKABLE void showNotification(const QJsonObject& notification);
    Q_INVOKABLE void hideNotification(qint64 id);

signals:
    void visibleCountChanged();
    void notificationDismissed(qint64 id);

private:
    explicit NotificationPopup(QObject* parent = nullptr);
    ~NotificationPopup() override = default;
    NotificationPopup(const NotificationPopup&) = delete;
    NotificationPopup& operator=(const NotificationPopup) = delete;

    void positionWindows();

    QMap<qint64, QQuickWindow*> m_popups;
    QMap<qint64, QTimer*> m_timers;
    static constexpr int MAX_VISIBLE = 5;
    static constexpr int POPUP_WIDTH = 380;
    static constexpr int POPUP_HEIGHT = 100;
    static constexpr int POPUP_SPACING = 8;
    static constexpr int POPUP_MARGIN = 16;
    static constexpr int AUTO_HIDE_MS = 5000;
    static NotificationPopup* s_instance;
};
