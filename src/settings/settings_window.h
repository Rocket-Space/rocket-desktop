#pragma once

#include <QQuickWindow>
#include <QJsonObject>
#include <QDBusAbstractAdaptor>

class QQmlEngine;
class QQmlComponent;

class SettingsWindowAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Settings")

public:
    explicit SettingsWindowAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE void Toggle();
};

class SettingsWindow : public QQuickWindow {
    Q_OBJECT
    Q_PROPERTY(bool settingsVisible READ settingsVisible NOTIFY settingsVisibleChanged)
    Q_PROPERTY(QString currentSection READ currentSection WRITE setCurrentSection NOTIFY currentSectionChanged)

public:
    explicit SettingsWindow(QWindow* parent = nullptr);
    ~SettingsWindow() override;

    bool settingsVisible() const;
    QString currentSection() const;
    void setCurrentSection(const QString& section);

    Q_INVOKABLE void show();
    Q_INVOKABLE void hide();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE QVariant getSetting(const QString& group, const QString& key);
    Q_INVOKABLE void setSetting(const QString& group, const QString& key, const QVariant& value);

signals:
    void settingsVisibleChanged();
    void currentSectionChanged();
    void settingChanged(const QString& group, const QString& key, const QVariant& value);

private:
    void loadSettings();
    void saveSettings();

    bool m_visible = false;
    QString m_currentSection = "general";
    QJsonObject m_settings;
    SettingsWindowAdaptor* m_adaptor;
    QQmlEngine* m_engine = nullptr;
    QQmlComponent* m_component = nullptr;
};
