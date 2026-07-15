#include "app_database.h"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QProcess>
#include <QStandardPaths>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>

AppDatabase* AppDatabase::s_instance = nullptr;

AppDatabase* AppDatabase::instance() {
    if (!s_instance) {
        s_instance = new AppDatabase();
    }
    return s_instance;
}

AppDatabase::AppDatabase(QObject* parent)
    : QObject(parent) {
    scan();
}

int AppDatabase::count() const {
    return m_apps.size();
}

void AppDatabase::scan() {
    m_apps.clear();

    QStringList searchPaths = {
        QDir::homePath() + "/.local/share/applications",
        "/usr/share/applications",
        "/usr/local/share/applications"
    };

    for (const QString& path : searchPaths) {
        QDir dir(path);
        if (!dir.exists()) continue;

        const QStringList desktopFiles = dir.entryList(
            QStringList() << "*.desktop", QDir::Files);

        for (const QString& file : desktopFiles) {
            parseDesktopFile(dir.absoluteFilePath(file), path);
        }
    }

    emit countChanged();
    emit appsChanged();
}

QString AppDatabase::extractValue(const QString& line) const {
    int eqPos = line.indexOf('=');
    if (eqPos == -1) return {};
    return line.mid(eqPos + 1).trimmed();
}

QString AppDatabase::extractField(const QString& content, const QString& field) const {
    const QStringList lines = content.split('\n');
    bool inDesktopEntry = false;

    for (const QString& line : lines) {
        const QString trimmed = line.trimmed();

        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
            inDesktopEntry = (trimmed == "[Desktop Entry]");
            continue;
        }

        if (!inDesktopEntry) continue;

        if (trimmed.startsWith(field + '=')) {
            return extractValue(trimmed);
        }
    }
    return {};
}

void AppDatabase::parseDesktopFile(const QString& filePath, const QString& sourcePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QTextStream stream(&file);
    const QString content = stream.readAll();
    file.close();

    const QString noDisplay = extractField(content, "NoDisplay");
    if (noDisplay.compare("true", Qt::CaseInsensitive) == 0) return;

    const QString hidden = extractField(content, "Hidden");
    if (hidden.compare("true", Qt::CaseInsensitive) == 0) return;

    QJsonObject app;
    app["name"] = extractField(content, "Name");
    app["exec"] = extractField(content, "Exec");
    app["icon"] = extractField(content, "Icon");
    app["categories"] = extractField(content, "Categories");
    app["comment"] = extractField(content, "Comment");
    app["desktopFile"] = filePath;
    
    // Determine app source type
    QString source = "user";
    if (sourcePath.startsWith("/usr/share/applications") || sourcePath.startsWith("/usr/local/share/applications")) {
        source = "system";
    }
    app["source"] = source;

    if (app["name"].toString().isEmpty()) return;
    if (app["exec"].toString().isEmpty()) return;

    m_apps.append(app);
}

QJsonArray AppDatabase::getAllApps() const {
    QJsonArray arr;
    for (const QJsonObject& app : m_apps) {
        arr.append(app);
    }
    return arr;
}

QJsonArray AppDatabase::search(const QString& query) const {
    QJsonArray arr;
    if (query.isEmpty()) return getAllApps();

    const QString lower = query.toLower();

    for (const QJsonObject& app : m_apps) {
        const QString name = app["name"].toString().toLower();
        const QString categories = app["categories"].toString().toLower();
        const QString comment = app["comment"].toString().toLower();

        if (name.contains(lower) || categories.contains(lower) || comment.contains(lower)) {
            arr.append(app);
        }
    }
    return arr;
}

bool AppDatabase::launchByDesktopFile(const QString& desktopFilePath) {
    for (const QJsonObject& app : m_apps) {
        if (app["desktopFile"].toString() == desktopFilePath) {
            const QString exec = app["exec"].toString();
            if (exec.isEmpty()) return false;

            QString command = exec;
            command.remove(QRegularExpression("%[fFuUdDnvm]"));

            return QProcess::startDetached(command);
        }
    }
    return false;
}
