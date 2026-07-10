#pragma once

#include <QQuickWindow>
#include <QDBusAbstractAdaptor>
#include <QClipboard>

class ClipboardManager;

class ClipboardHistoryWindowAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Clipboard.History")

public:
    explicit ClipboardHistoryWindowAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Toggle();
};

class QQmlEngine;
class QQmlComponent;

class ClipboardHistoryWindow : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(bool historyVisible READ historyVisible NOTIFY historyVisibleChanged)

public:
    explicit ClipboardHistoryWindow(QWindow* parent = nullptr);
    ~ClipboardHistoryWindow() override;

    bool historyVisible() const;

    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void copyItem(int index);

signals:
    void historyVisibleChanged();
    void itemCopied(const QString& text);

private:
    bool m_visible = false;
    ClipboardManager* m_manager;
    ClipboardHistoryWindowAdaptor* m_adaptor;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};
