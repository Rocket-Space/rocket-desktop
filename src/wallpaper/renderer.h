#pragma once

#include <QQuickWindow>
#include <QDBusAbstractAdaptor>
#include <QStringList>

class QQmlEngine;
class QQmlComponent;

class WallpaperRendererAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Wallpaper")

public:
    explicit WallpaperRendererAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void SetImage(const QString& path);
    Q_SCRIPTABLE void SetScalingMode(const QString& mode);
    Q_SCRIPTABLE QStringList GetAvailableWallpapers();
};

class WallpaperRenderer : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(QString imagePath READ imagePath NOTIFY wallpaperChanged)
    Q_PROPERTY(QString scalingMode READ scalingMode NOTIFY scalingModeChanged)

public:
    explicit WallpaperRenderer(QWindow* parent = nullptr);
    ~WallpaperRenderer() override;

    QString imagePath() const;
    QString scalingMode() const;

    Q_INVOKABLE void setImage(const QString& path);
    Q_INVOKABLE void setScalingMode(const QString& mode);
    Q_INVOKABLE QStringList getAvailableWallpapers();

signals:
    void wallpaperChanged(const QString& path);
    void scalingModeChanged(const QString& mode);

private:
    void loadConfig();
    void saveConfig();

    QString m_imagePath;
    QString m_scalingMode = "fill";
    WallpaperRendererAdaptor* m_adaptor;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};
