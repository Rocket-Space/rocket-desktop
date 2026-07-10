#include "screenshot_tool.h"
#include <QGuiApplication>
#include <QScreen>
#include <QPixmap>
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QDBusConnection>

ScreenshotTool* ScreenshotTool::s_instance = nullptr;

ScreenshotTool* ScreenshotTool::instance() {
    if (!s_instance) {
        s_instance = new ScreenshotTool();
    }
    return s_instance;
}

ScreenshotTool::ScreenshotTool(QObject* parent)
    : QObject(parent)
    , m_adaptor(new ScreenshotToolAdaptor(this)) {
    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("org.rocket.Screenshot");
    bus.registerObject("/org/rocket/Screenshot", this);
}

QString ScreenshotTool::generateFilePath() const {
    QString picturesDir = QDir::homePath() + "/Pictures";
    QDir().mkpath(picturesDir);
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    return picturesDir + "/screenshot_" + timestamp + ".png";
}

QString ScreenshotTool::savePixmap(const QPixmap& pixmap) {
    if (pixmap.isNull()) return {};
    QString filePath = generateFilePath();
    if (pixmap.save(filePath, "PNG")) {
        emit screenshotTaken(filePath);
        return filePath;
    }
    return {};
}

QPixmap ScreenshotTool::grabFullScreen() {
    QScreen* screen = QGuiApplication::primaryScreen();
    if (!screen) return {};
    return screen->grabWindow(0,
                              screen->geometry().x(),
                              screen->geometry().y(),
                              screen->geometry().width(),
                              screen->geometry().height());
}

QPixmap ScreenshotTool::grabRegion(int x, int y, int w, int h) {
    QScreen* screen = QGuiApplication::primaryScreen();
    if (!screen) return {};
    return screen->grabWindow(0, x, y, w, h);
}

QString ScreenshotTool::captureFullScreen() {
    return savePixmap(grabFullScreen());
}

QString ScreenshotTool::captureRegion(int x, int y, int w, int h) {
    return savePixmap(grabRegion(x, y, w, h));
}

QString ScreenshotTool::captureActiveWindow() {
    return captureFullScreen();
}

ScreenshotToolAdaptor::ScreenshotToolAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

QString ScreenshotToolAdaptor::FullScreen() {
    auto* tool = qobject_cast<ScreenshotTool*>(parent());
    if (tool) return tool->captureFullScreen();
    return {};
}

QString ScreenshotToolAdaptor::Region(int x, int y, int w, int h) {
    auto* tool = qobject_cast<ScreenshotTool*>(parent());
    if (tool) return tool->captureRegion(x, y, w, h);
    return {};
}

QString ScreenshotToolAdaptor::ActiveWindow() {
    auto* tool = qobject_cast<ScreenshotTool*>(parent());
    if (tool) return tool->captureActiveWindow();
    return {};
}
