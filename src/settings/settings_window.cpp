#include "settings_window.h"
#include <QScreen>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

SettingsWindowAdaptor::SettingsWindowAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void SettingsWindowAdaptor::Toggle() {
    auto* window = qobject_cast<SettingsWindow*>(parent());
    if (window) window->toggle();
}

SettingsWindow::SettingsWindow(QWindow* parent)
    : QQuickWindow(parent)
    , m_adaptor(new SettingsWindowAdaptor(this)) {
    setWidth(800);
    setHeight(600);
    setFlags(Qt::FramelessWindowHint | Qt::Dialog);
    setColor(Qt::transparent);
    setTitle("Rocket Settings");

    QScreen* screen = QGuiApplication::primaryScreen();
    if (screen) {
        int screenW = screen->availableGeometry().width();
        int screenH = screen->availableGeometry().height();
        setPosition((screenW - width()) / 2, (screenH - height()) / 2);
    }

    m_engine = new QQmlEngine(this);
    m_component = new QQmlComponent(m_engine, QUrl("qrc:/qml/SettingsWindow.qml"));
    if (!m_component->isError()) {
        QQuickItem* root = qobject_cast<QQuickItem*>(m_component->create());
        if (root) root->setParentItem(contentItem());
    }

    loadSettings();

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("org.rocket.Settings");
    bus.registerObject("/org/rocket/Settings", this);
}

SettingsWindow::~SettingsWindow() {
    delete m_component;
    delete m_engine;
}

bool SettingsWindow::settingsVisible() const { return m_visible; }
QString SettingsWindow::currentSection() const { return m_currentSection; }

void SettingsWindow::setCurrentSection(const QString& section) {
    if (m_currentSection == section) return;
    m_currentSection = section;
    emit currentSectionChanged();
}

void SettingsWindow::show() {
    m_visible = true;
    QQuickWindow::show();
    QQuickWindow::raise();
    QQuickWindow::requestActivate();
    emit settingsVisibleChanged();
}

void SettingsWindow::hide() {
    m_visible = false;
    QQuickWindow::hide();
    emit settingsVisibleChanged();
}

void SettingsWindow::toggle() {
    if (m_visible) hide();
    else show();
}

QVariant SettingsWindow::getSetting(const QString& group, const QString& key) {
    if (!m_settings.contains(group)) return {};
    const QJsonObject groupObj = m_settings[group].toObject();
    if (!groupObj.contains(key)) return {};
    return groupObj[key].toVariant();
}

void SettingsWindow::setSetting(const QString& group, const QString& key, const QVariant& value) {
    QJsonObject groupObj = m_settings[group].toObject();
    groupObj[key] = QJsonValue::fromVariant(value);
    m_settings[group] = groupObj;
    saveSettings();
    emit settingChanged(group, key, value);
}

void SettingsWindow::loadSettings() {
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                         + "/rocket-desktop/settings.json";
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly)) return;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    m_settings = doc.object();
}

void SettingsWindow::saveSettings() {
    QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                         + "/rocket-desktop/settings.json";
    QDir().mkpath(QFileInfo(configPath).absolutePath());
    QFile file(configPath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(m_settings).toJson());
        file.close();
    }
}
