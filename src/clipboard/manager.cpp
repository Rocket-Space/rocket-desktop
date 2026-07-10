#include "manager.h"
#include <QClipboard>
#include <QGuiApplication>
#include <QDBusConnection>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

ClipboardManager* ClipboardManager::s_instance = nullptr;

ClipboardManager* ClipboardManager::instance() {
    if (!s_instance) {
        s_instance = new ClipboardManager();
    }
    return s_instance;
}

ClipboardManager::ClipboardManager(QObject* parent)
    : QObject(parent)
    , m_pollTimer(new QTimer(this))
    , m_adaptor(new ClipboardManagerAdaptor(this)) {
    m_pollTimer->setInterval(POLL_INTERVAL_MS);
    connect(m_pollTimer, &QTimer::timeout, this, &ClipboardManager::pollClipboard);
    m_pollTimer->start();

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("org.rocket.Clipboard");
    bus.registerObject("/org/rocket/Clipboard", this);
}

int ClipboardManager::count() const {
    return m_entries.size();
}

void ClipboardManager::pollClipboard() {
    QClipboard* clipboard = QGuiApplication::clipboard();
    if (!clipboard) return;

    const QString text = clipboard->text();
    if (text.isEmpty() || text == m_lastText) return;

    m_lastText = text;
    addEntry(text);
}

void ClipboardManager::addEntry(const QString& text) {
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries[i].text == text && !m_entries[i].pinned) {
            m_entries.removeAt(i);
            break;
        }
    }

    ClipboardEntry entry;
    entry.text = text;
    entry.timestamp = QDateTime::currentMSecsSinceEpoch();
    entry.pinned = false;

    m_entries.prepend(entry);

    pruneUnpinned();
    emit clipboardChanged(text);
    emit historyChanged();
}

void ClipboardManager::pruneUnpinned() {
    while (m_entries.size() > MAX_ENTRIES) {
        for (int i = m_entries.size() - 1; i >= 0; --i) {
            if (!m_entries[i].pinned) {
                m_entries.removeAt(i);
                break;
            }
        }
        if (m_entries.size() <= MAX_ENTRIES) break;
    }
}

QJsonArray ClipboardManager::getHistory() const {
    QJsonArray arr;
    for (int i = 0; i < m_entries.size(); ++i) {
        const ClipboardEntry& entry = m_entries[i];
        QJsonObject obj;
        obj["index"] = i;
        obj["text"] = entry.text;
        obj["timestamp"] = entry.timestamp;
        obj["pinned"] = entry.pinned;
        arr.append(obj);
    }
    return arr;
}

QString ClipboardManager::getLatest() const {
    if (m_entries.isEmpty()) return {};
    return m_entries.first().text;
}

void ClipboardManager::clear() {
    QList<ClipboardEntry> pinned;
    for (const ClipboardEntry& entry : m_entries) {
        if (entry.pinned) {
            pinned.append(entry);
        }
    }
    m_entries = pinned;
    emit historyChanged();
}

void ClipboardManager::removeItem(int index) {
    if (index < 0 || index >= m_entries.size()) return;
    m_entries.removeAt(index);
    emit historyChanged();
}

void ClipboardManager::pinItem(int index) {
    if (index < 0 || index >= m_entries.size()) return;
    m_entries[index].pinned = !m_entries[index].pinned;
    emit historyChanged();
}

QJsonArray ClipboardManager::search(const QString& query) const {
    QJsonArray arr;
    const QString lower = query.toLower();

    for (int i = 0; i < m_entries.size(); ++i) {
        const ClipboardEntry& entry = m_entries[i];
        if (entry.text.toLower().contains(lower)) {
            QJsonObject obj;
            obj["index"] = i;
            obj["text"] = entry.text;
            obj["timestamp"] = entry.timestamp;
            obj["pinned"] = entry.pinned;
            arr.append(obj);
        }
    }
    return arr;
}

ClipboardManagerAdaptor::ClipboardManagerAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

QJsonArray ClipboardManagerAdaptor::GetHistory() {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) return manager->getHistory();
    return {};
}

QString ClipboardManagerAdaptor::GetLatest() {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) return manager->getLatest();
    return {};
}

void ClipboardManagerAdaptor::Clear() {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) manager->clear();
}

void ClipboardManagerAdaptor::RemoveItem(int index) {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) manager->removeItem(index);
}

void ClipboardManagerAdaptor::PinItem(int index) {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) manager->pinItem(index);
}

QJsonArray ClipboardManagerAdaptor::Search(const QString& query) {
    auto* manager = qobject_cast<ClipboardManager*>(parent());
    if (manager) return manager->search(query);
    return {};
}
