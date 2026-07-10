#include "config_manager.h"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>

namespace Rocket {

ConfigManager& ConfigManager::instance() {
    static ConfigManager inst;
    return inst;
}

void ConfigManager::setConfigDir(const QString& dir) {
    m_configDir = dir;
}

QString ConfigManager::configDir() const {
    if (!m_configDir.isEmpty()) return m_configDir;
    return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/rocket";
}

void ConfigManager::ensureConfigDir() {
    QDir dir(configDir());
    if (!dir.exists()) dir.mkpath(".");
}

void ConfigManager::load() {
    ensureConfigDir();
    m_data.clear();

    QDir dir(configDir());
    for (const auto& entry : dir.entryList({"*.conf"}, QDir::Files)) {
        QFile file(dir.filePath(entry));
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) continue;

        QString section;
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.isEmpty() || line.startsWith('#') || line.startsWith(';')) continue;

            if (line.startsWith('[') && line.endsWith(']')) {
                section = line.mid(1, line.length() - 2);
                continue;
            }

            int eq = line.indexOf('=');
            if (eq < 0) continue;

            QString key = line.left(eq).trimmed();
            QString value = line.mid(eq + 1).trimmed();

            if (value.startsWith('"') && value.endsWith('"'))
                value = value.mid(1, value.length() - 2);

            QString fullKey = section.isEmpty() ? key : section + "/" + key;
            m_data[fullKey] = value;
        }
    }
}

void ConfigManager::reload() { load(); }

QString ConfigManager::getString(const QString& group, const QString& key, const QString& defaultValue) const {
    QString fullKey = group + "/" + key;
    return m_data.value(fullKey, defaultValue).toString();
}

int ConfigManager::getInt(const QString& group, const QString& key, int defaultValue) const {
    QString fullKey = group + "/" + key;
    if (!m_data.contains(fullKey)) return defaultValue;
    return m_data.value(fullKey).toInt();
}

bool ConfigManager::getBool(const QString& group, const QString& key, bool defaultValue) const {
    QString fullKey = group + "/" + key;
    if (!m_data.contains(fullKey)) return defaultValue;
    QString val = m_data.value(fullKey).toString().toLower();
    return val == "true" || val == "1" || val == "yes";
}

QStringList ConfigManager::getStringList(const QString& group, const QString& key, const QStringList& defaultValue) const {
    QString fullKey = group + "/" + key;
    if (!m_data.contains(fullKey)) return defaultValue;
    return m_data.value(fullKey).toString().split(',', Qt::SkipEmptyParts);
}

void ConfigManager::setString(const QString& group, const QString& key, const QString& value) {
    m_data[group + "/" + key] = value;
}

void ConfigManager::setInt(const QString& group, const QString& key, int value) {
    m_data[group + "/" + key] = value;
}

void ConfigManager::setBool(const QString& group, const QString& key, bool value) {
    m_data[group + "/" + key] = value ? "true" : "false";
}

}
