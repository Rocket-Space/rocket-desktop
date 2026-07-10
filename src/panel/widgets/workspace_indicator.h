#pragma once

#include <QObject>
#include <QVariantList>

namespace Rocket {

class WorkspaceIndicator : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentWorkspace READ currentWorkspace WRITE setCurrentWorkspace NOTIFY currentWorkspaceChanged)
    Q_PROPERTY(int workspaceCount READ workspaceCount WRITE setWorkspaceCount NOTIFY workspaceCountChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)

public:
    explicit WorkspaceIndicator(QObject* parent = nullptr);

    int currentWorkspace() const;
    int workspaceCount() const;
    QVariantList workspaces() const;

    void setCurrentWorkspace(int ws);
    void setWorkspaceCount(int count);

    Q_INVOKABLE void switchTo(int index);

signals:
    void currentWorkspaceChanged();
    void workspaceCountChanged();
    void workspacesChanged();
    void workspaceSwitched(int index);

private:
    int m_current = 1;
    int m_count = 4;
};

}
