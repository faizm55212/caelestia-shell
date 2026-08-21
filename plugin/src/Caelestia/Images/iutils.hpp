#pragma once

#include <qimage.h>
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qurl.h>

namespace caelestia::images {

QImage readSourceImage(const QString& path);

class IUtils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static IUtils* create(QQmlEngine* engine, QJSEngine* jsEngine);

    Q_INVOKABLE static QUrl urlForPath(const QString& path, int fillMode);

private:
    explicit IUtils(QObject* parent = nullptr);
};

} // namespace caelestia::images
