#pragma once

#include <qfuturewatcher.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvariant.h>

namespace caelestia {

struct RawWorkshopEntry {
    QString path;
    QString preview;
    QString title;
    QString workshopDir;
    QString id;
};

class WorkshopEntry : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("WorkshopEntry instances can only be retrieved from CUtils")

    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString preview READ preview CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString relativePath READ relativePath CONSTANT)
    Q_PROPERTY(QString parentDir READ parentDir CONSTANT)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(bool isLive READ isLive CONSTANT)

public:
    explicit WorkshopEntry(const QString& path, const QString& preview, const QString& title,
        const QString& workshopDir, const QString& id, QObject* parent = nullptr)
        : QObject(parent)
        , m_path(path)
        , m_preview(preview)
        , m_title(title)
        , m_workshopDir(workshopDir)
        , m_id(id) {}

    [[nodiscard]] QString path() const { return m_path; }

    [[nodiscard]] QString preview() const { return m_preview; }

    [[nodiscard]] QString name() const { return m_title; }

    [[nodiscard]] QString title() const { return m_title; }

    [[nodiscard]] QString relativePath() const { return m_title; }

    [[nodiscard]] QString parentDir() const { return m_workshopDir; }

    [[nodiscard]] QString id() const { return m_id; }

    [[nodiscard]] bool isLive() const { return true; }

private:
    QString m_path;
    QString m_preview;
    QString m_title;
    QString m_workshopDir;
    QString m_id;
};

class CUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QList<WorkshopEntry*> workshopWallpapers READ workshopWallpapers NOTIFY workshopWallpapersChanged)

public:
    explicit CUtils(QObject* parent = nullptr);
    ~CUtils() override;

    Q_INVOKABLE void saveItem(
        QQuickItem* target, const QUrl& path, const QJSValue& onSaved = {}, const QJSValue& onFailed = {});
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, const QJSValue& onSaved = {},
        const QJSValue& onFailed = {});

    Q_INVOKABLE static bool copyFile(const QUrl& source, const QUrl& target, bool overwrite = true);
    Q_INVOKABLE static bool deleteFile(const QUrl& path);
    Q_INVOKABLE static QString toLocalFile(const QUrl& url);
    Q_INVOKABLE static bool dirExists(const QString& path);

    Q_INVOKABLE static qreal clamp(qreal value, qreal min, qreal max);

    Q_INVOKABLE static QString enumToString(QObject* target, const QString& property, const QVariant& value = {});

    Q_INVOKABLE static QQuickItem* findChild(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildren(QQuickItem* root, const QString& name);
    Q_INVOKABLE static QList<QQuickItem*> findChildrenMatching(QQuickItem* root, const QString& pattern);

    Q_INVOKABLE void reloadWorkshopWallpapers(const QString& workshopDir);

    [[nodiscard]] QList<WorkshopEntry*> workshopWallpapers() const { return m_workshopWallpapers; }
    [[nodiscard]] static QString version();
    [[nodiscard]] static QString qtVersion();

signals:
    void workshopWallpapersChanged();
    void workshopWallpapersLoaded(const QList<WorkshopEntry*>& wallpapers);

private:
    void setWorkshopWallpapersFromRaw(const QList<RawWorkshopEntry>& rawEntries);

    QList<WorkshopEntry*> m_workshopWallpapers;
    QFutureWatcher<QList<RawWorkshopEntry>>* m_workshopWatcher = nullptr;
    QString m_pendingWorkshopDir;
};

} // namespace caelestia
