#pragma once

#include <QObject>
#include <QTimer>
#include <QString>

namespace Rocket {

class Clock : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString time READ time NOTIFY timeChanged)
    Q_PROPERTY(QString date READ date NOTIFY timeChanged)
    Q_PROPERTY(QString dayOfWeek READ dayOfWeek NOTIFY timeChanged)
    Q_PROPERTY(bool is24h READ is24h WRITE setIs24h NOTIFY is24hChanged)

public:
    explicit Clock(QObject* parent = nullptr);

    QString time() const;
    QString date() const;
    QString dayOfWeek() const;
    bool is24h() const;
    void setIs24h(bool v);

signals:
    void timeChanged();
    void is24hChanged();

private:
    QTimer* m_timer;
    bool m_24h = true;
    void update();
};

}
