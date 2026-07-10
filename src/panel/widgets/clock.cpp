#include "clock.h"
#include <QTime>
#include <QDate>

namespace Rocket {

Clock::Clock(QObject* parent) : QObject(parent) {
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &Clock::update);
    m_timer->start(1000);
    update();
}

QString Clock::time() const {
    QTime now = QTime::currentTime();
    if (m_24h) return now.toString("HH:mm");
    return now.toString("h:mm AP");
}

QString Clock::date() const {
    return QDate::currentDate().toString("dd/MM/yyyy");
}

QString Clock::dayOfWeek() const {
    return QDate::currentDate().toString("dddd");
}

bool Clock::is24h() const { return m_24h; }

void Clock::setIs24h(bool v) {
    if (m_24h != v) {
        m_24h = v;
        emit is24hChanged();
        emit timeChanged();
    }
}

void Clock::update() {
    emit timeChanged();
}

}
