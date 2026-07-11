#include "renderer.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDir>
#include <QStandardPaths>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QDBusConnection>

WallpaperRendererAdaptor::WallpaperRendererAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void WallpaperRendererAdaptor::SetImage(const QString& path) {
    auto* renderer = qobject_cast<WallpaperRenderer*>(parent());
    if (renderer) renderer->setImage(path);
}

void WallpaperRendererAdaptor::SetScalingMode(const QString& mode) {
    auto* renderer = qobject_cast<WallpaperRenderer*>(parent());
    if (renderer) renderer->setScalingMode(mode);
}

QStringList WallpaperRendererAdaptor::GetAvailableWallpapers() {
    auto* renderer = qobject_cast<WallpaperRenderer*>(parent());
    if (renderer) return renderer->getAvailableWallpapers();
    return {};
}

WallpaperRenderer::WallpaperRenderer(QWindow* parent)
    : QQuickWindow(parent)
    , m_adaptor(new WallpaperRendererAdaptor(this)) {
    setFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnBottomHint);
    setColor(QColor("#0d0d1a"));

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        setGeometry(screen->availableGeometry());
    }

    m_engine = new QQmlEngine(this);
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/wallpaper/WallpaperRenderer.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) {
            root->setParentItem(contentItem());
            m_qmlRoot = root;
        }
    }

    loadConfig();

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("org.rocket.Wallpaper");
    bus.registerObject("/org/rocket/Wallpaper", this);

    if (!m_imagePath.isEmpty()) {
        if (m_qmlRoot) {
            m_qmlRoot->setProperty("imagePath", "file://" + m_imagePath);
            m_qmlRoot->setProperty("scalingMode", m_scalingMode);
        }
        emit wallpaperChanged(m_imagePath);
        emit scalingModeChanged(m_scalingMode);
    }
}

WallpaperRenderer::~WallpaperRenderer() {
    delete m_component;
    delete m_engine;
}

QString WallpaperRenderer::imagePath() const {
    return m_imagePath;
}

QString WallpaperRenderer::scalingMode() const {
    return m_scalingMode;
}

void WallpaperRenderer::setImage(const QString& path) {
    if (m_imagePath == path) return;

    if (path.isEmpty()) {
        m_imagePath.clear();
    } else {
        QFile file(path);
        if (!file.exists()) return;
        m_imagePath = path;
    }

    saveConfig();
    if (m_qmlRoot) {
        m_qmlRoot->setProperty("imagePath", "file://" + m_imagePath);
    }
    emit wallpaperChanged(m_imagePath);
}

void WallpaperRenderer::setScalingMode(const QString& mode) {
    static const QStringList validModes = {"fill", "fit", "stretch", "center", "tile"};
    if (!validModes.contains(mode)) return;
    if (m_scalingMode == mode) return;

    m_scalingMode = mode;
    saveConfig();
    if (m_qmlRoot) {
        m_qmlRoot->setProperty("scalingMode", m_scalingMode);
    }
    emit scalingModeChanged(m_scalingMode);
}

QStringList WallpaperRenderer::getAvailableWallpapers() {
    QStringList wallpapers;

    QStringList searchPaths = {
        QDir::homePath() + "/Pictures",
        "/usr/share/rocket-desktop/wallpapers"
    };

    const QStringList imageFilters = {"*.png", "*.jpg", "*.jpeg", "*.bmp", "*.webp"};

    for (const QString& path : searchPaths) {
        QDir dir(path);
        if (!dir.exists()) continue;

        const QStringList files = dir.entryList(imageFilters, QDir::Files);
        for (const QString& file : files) {
            wallpapers.append(dir.absoluteFilePath(file));
        }

        const QStringList subdirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString& subdir : subdirs) {
            QDir subDir(dir.absoluteFilePath(subdir));
            const QStringList subFiles = subDir.entryList(imageFilters, QDir::Files);
            for (const QString& file : subFiles) {
                wallpapers.append(subDir.absoluteFilePath(file));
            }
        }
    }

    return wallpapers;
}

void WallpaperRenderer::loadConfig() {
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                         + "/rocket-desktop/wallpaper.json";

    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly)) return;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    const QJsonObject obj = doc.object();
    m_imagePath = obj["imagePath"].toString();
    m_scalingMode = obj["scalingMode"].toString("fill");
}

void WallpaperRenderer::saveConfig() {
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                         + "/rocket-desktop/wallpaper.json";

    QDir().mkpath(QFileInfo(configPath).absolutePath());

    QJsonObject obj;
    obj["imagePath"] = m_imagePath;
    obj["scalingMode"] = m_scalingMode;

    QFile file(configPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(obj).toJson());
        file.close();
    }
}
