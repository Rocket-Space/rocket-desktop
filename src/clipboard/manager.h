#pragma once

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QTimer>
#include <QDBusAbstractAdaptor>

struct ClipboardEntry {
    QString text;
    qint64 timestamp;
    bool pinned;
};

class ClipboardManagerAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.rocket.Clipboard")

public:
    explicit ClipboardManagerAdaptor(QObject* parent);

public slots:
    Q_SCRIPTABLE QJsonArray GetHistory();
    Q_SCRIPTABLE QString GetLatest();
    Q_SCRIPTABLE void Clear();
    Q_SCRIPTABLE void RemoveItem(int index);
    Q_SCRIPTABLE void PinItem(int index);
    Q_SCRIPTABLE QJsonArray Search(const QString& query);
};

class ClipboardManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY historyChanged)

public:
    static ClipboardManager* instance();

    int count() const;

    Q_INVOKABLE QJsonArray getHistory() const;
    Q_INVOKABLE QString getLatest() const;
    Q_INVOKABLE void clear();
    Q_INVOKABLE void removeItem(int index);
    Q_INVOKABLE void pinItem(int index);
    Q_INVOKABLE QJsonArray search(const QString& query) const;

signals:
    void clipboardChanged(const QString& text);
    void historyChanged();

private:
    explicit ClipboardManager(QObject* parent = nullptr);
    ~ClipboardManager() override = default;
    ClipboardManager(const ClipboardManager&) = delete;
    ClipboardManager& operator=(const ClipboardManager&) = delete;

    void pollClipboard();
    void addEntry(const QString& text);
    void pruneUnpinned();

    QList<ClipboardEntry> m_entries;
    QTimer* m_pollTimer;
    QString m_lastText;
    ClipboardManagerAdaptor* m_adaptor;
    static ClipboardManager* s_instance;
    static constexpr int MAX_ENTRIES = 50;
    static constexpr int POLL_INTERVAL_MS = 250;
};
