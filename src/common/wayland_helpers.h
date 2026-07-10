#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

namespace Rocket {

class WaylandHelpers : public QObject {
    Q_OBJECT
public:
    explicit WaylandHelpers(QObject* parent = nullptr);

    Q_INVOKABLE QString currentDesktop() const;
    Q_INVOKABLE int workspaceCount() const;
    Q_INVOKABLE int currentWorkspace() const;
    Q_INVOKABLE void switchWorkspace(int index);
    Q_INVOKABLE QVariantList runningWindows() const;
    Q_INVOKABLE void focusWindow(const QString& title);
    Q_INVOKABLE void closeWindow(const QString& title);
    Q_INVOKABLE void maximizeWindow(const QString& title);
    Q_INVOKABLE void minimizeWindow(const QString& title);
    Q_INVOKABLE void tileWindowLeft(const QString& title);
    Q_INVOKABLE void tileWindowRight(const QString& title);

    static WaylandHelpers& instance();

private:
    int m_currentWorkspace = 0;
    int m_workspaceCount = 4;
};

}
