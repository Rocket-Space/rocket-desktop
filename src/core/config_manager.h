#pragma once

#include <QString>
#include <QVariantMap>

namespace Rocket {

class ConfigManager {
public:
    static ConfigManager& instance();

    void load();
    void reload();

    QString getString(const QString& group, const QString& key, const QString& defaultValue = {}) const;
    int getInt(const QString& group, const QString& key, int defaultValue = 0) const;
    bool getBool(const QString& group, const QString& key, bool defaultValue = false) const;
    QStringList getStringList(const QString& group, const QString& key, const QStringList& defaultValue = {}) const;

    void setString(const QString& group, const QString& key, const QString& value);
    void setInt(const QString& group, const QString& key, int value);
    void setBool(const QString& group, const QString& key, bool value);

    QString configDir() const;
    void setConfigDir(const QString& dir);

private:
    ConfigManager() = default;
    QString m_configDir;
    QVariantMap m_data;
    void ensureConfigDir();
};

}
