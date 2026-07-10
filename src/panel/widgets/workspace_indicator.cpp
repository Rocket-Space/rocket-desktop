#include "workspace_indicator.h"
#include <QJsonObject>

namespace Rocket {

WorkspaceIndicator::WorkspaceIndicator(QObject* parent) : QObject(parent) {}

int WorkspaceIndicator::currentWorkspace() const { return m_current; }
int WorkspaceIndicator::workspaceCount() const { return m_count; }

QVariantList WorkspaceIndicator::workspaces() const {
    QVariantList list;
    for (int i = 1; i <= m_count; ++i) {
        QJsonObject ws;
        ws["index"] = i;
        ws["active"] = (i == m_current);
        list.append(ws);
    }
    return list;
}

void WorkspaceIndicator::setCurrentWorkspace(int ws) {
    if (ws >= 1 && ws <= m_count && ws != m_current) {
        m_current = ws;
        emit currentWorkspaceChanged();
        emit workspacesChanged();
    }
}

void WorkspaceIndicator::setWorkspaceCount(int count) {
    if (count > 0 && count != m_count) {
        m_count = count;
        emit workspaceCountChanged();
        emit workspacesChanged();
    }
}

void WorkspaceIndicator::switchTo(int index) {
    if (index >= 1 && index <= m_count) {
        setCurrentWorkspace(index);
        emit workspaceSwitched(index);
    }
}

}
