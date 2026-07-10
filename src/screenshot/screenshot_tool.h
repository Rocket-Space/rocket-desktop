#pragma once

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QPixmap>

class ScreenshotToolAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Screenshot")

public:
    explicit ScreenshotToolAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE QString FullScreen();
    Q_SCRIPTABLE QString Region(int x, int y, int w, int h);
    Q_SCRIPTABLE QString ActiveWindow();
};

class ScreenshotTool : public QObject {
    Q_OBJECT

public:
    static ScreenshotTool* instance();

    Q_INVOKABLE QString captureFullScreen();
    Q_INVOKABLE QString captureRegion(int x, int y, int w, int h);
    Q_INVOKABLE QString captureActiveWindow();

signals:
    void screenshotTaken(const QString& filePath);

private:
    explicit ScreenshotTool(QObject* parent = nullptr);
    ~ScreenshotTool() override = default;
    ScreenshotTool(const ScreenshotTool&) = delete;
    ScreenshotTool& operator=(const ScreenshotTool&) = delete;

    QString savePixmap(const QPixmap& pixmap);
    QString generateFilePath() const;
    QPixmap grabFullScreen();
    QPixmap grabRegion(int x, int y, int w, int h);

    ScreenshotToolAdaptor* m_adaptor;
    static ScreenshotTool* s_instance;
};
