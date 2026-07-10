#pragma once

#include <QQuickWindow>
#include <QDBusAbstractAdaptor>
#include <QQmlEngine>
#include <QQmlComponent>

namespace Rocket {

class PanelWindowAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Panel")

public:
    explicit PanelWindowAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Toggle();
    Q_SCRIPTABLE void Show();
    Q_SCRIPTABLE void Hide();
};

class PanelWindow : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(bool panelVisible READ panelVisible NOTIFY panelVisibleChanged)
    Q_PROPERTY(int panelHeight READ panelHeight CONSTANT)

public:
    explicit PanelWindow(QWindow* parent = nullptr);
    ~PanelWindow() override;

    bool panelVisible() const;
    int panelHeight() const;

    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();
    Q_INVOKABLE void toggle();

signals:
    void panelVisibleChanged();

private:
    bool m_visible = true;
    PanelWindowAdaptor* m_adaptor;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};

}
