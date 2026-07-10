#pragma once

#include <QQuickWindow>
#include <QDBusAbstractAdaptor>
#include <QVariantList>

class QQmlEngine;
class QQmlComponent;

class OverviewWindowAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Overview")

public:
    explicit OverviewWindowAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Toggle();
};

class OverviewWindow : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(bool overviewVisible READ overviewVisible NOTIFY overviewVisibleChanged)
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)

public:
    explicit OverviewWindow(QWindow* parent = nullptr);
    ~OverviewWindow() override;

    bool overviewVisible() const;
    QVariantList windows() const;

    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void refreshWindows();
    Q_INVOKABLE void selectWindow(qint64 id);

signals:
    void overviewVisibleChanged();
    void windowsChanged();
    void windowSelected(qint64 id);

private:
    bool m_visible = false;
    QVariantList m_windows;
    OverviewWindowAdaptor* m_adaptor;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};
