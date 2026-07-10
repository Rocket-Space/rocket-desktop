#pragma once

#include <QObject>
#include <QVariantList>

namespace Rocket {

class Taskbar : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)

public:
    explicit Taskbar(QObject* parent = nullptr);

    QVariantList windows() const;
    void refresh();

    Q_INVOKABLE void focusWindow(qint64 id);
    Q_INVOKABLE void closeWindow(qint64 id);
    Q_INVOKABLE void minimizeWindow(qint64 id);

signals:
    void windowsChanged();

private:
    QVariantList m_windows;
};

}
