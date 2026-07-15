#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QStringList>

class AppDatabase : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    static AppDatabase* instance();

    int count() const;

    Q_INVOKABLE QJsonArray getAllApps() const;
    Q_INVOKABLE QJsonArray search(const QString& query) const;
    Q_INVOKABLE bool launchByDesktopFile(const QString& desktopFilePath);

    void scan();

signals:
    void countChanged();
    void appsChanged();

private:
    explicit AppDatabase(QObject* parent = nullptr);
    ~AppDatabase() override = default;
    AppDatabase(const AppDatabase&) = delete;
    AppDatabase& operator=(const AppDatabase&) = delete;

    void parseDesktopFile(const QString& filePath, const QString& sourcePath);
    QString extractValue(const QString& line) const;
    QString extractField(const QString& content, const QString& field) const;

    QList<QJsonObject> m_apps;
    static AppDatabase* s_instance;
};
