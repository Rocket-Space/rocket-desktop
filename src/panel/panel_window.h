#pragma once

#include <QObject>
#include <QQuickWindow>
#include <QTimer>

namespace Rocket {

class PanelWindow : public QObject {
    Q_OBJECT
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY widthChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY heightChanged)
    Q_PROPERTY(int x READ x WRITE setX NOTIFY xChanged)
    Q_PROPERTY(int y READ y WRITE setY NOTIFY yChanged)
    Q_PROPERTY(QString position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(bool visible READ isVisible WRITE setVisible NOTIFY visibleChanged)
    Q_PROPERTY(float opacity READ opacity WRITE setOpacity NOTIFY opacityChanged)

public:
    explicit PanelWindow(QObject* parent = nullptr);
    ~PanelWindow();

    int width() const;
    int height() const;
    int x() const;
    int y() const;
    QString position() const;
    bool isVisible() const;
    float opacity() const;

    void setWidth(int w);
    void setHeight(int h);
    void setX(int x);
    void setY(int y);
    void setPosition(const QString& pos);
    void setVisible(bool v);
    void setOpacity(float o);

    Q_INVOKABLE void toggle();
    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();

signals:
    void widthChanged();
    void heightChanged();
    void xChanged();
    void yChanged();
    void positionChanged();
    void visibleChanged();
    void opacityChanged();

private:
    int m_width = 1920;
    int m_height = 40;
    int m_x = 0;
    int m_y = 0;
    QString m_position = "bottom";
    bool m_visible = true;
    float m_opacity = 0.85f;
};

}
