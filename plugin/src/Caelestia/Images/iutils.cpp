#include "iutils.hpp"

#include <qimagereader.h>

#include "cachingimageprovider.hpp"

namespace caelestia::images {

using Qt::StringLiterals::operator""_s;

QImage readSourceImage(const QString& path) {
    QImageReader reader(path);
    if (reader.supportsAnimation()) {
        const int count = reader.imageCount();
        const int target = count > 1 ? std::min(count / 2, 5) : 0;
        QImage img;
        for (int i = 0; i <= target; ++i) {
            const QImage next = reader.read();
            if (next.isNull())
                break;
            img = next;
        }
        if (!img.isNull())
            return img;
    }
    return reader.read();
}

IUtils::IUtils(QObject* parent)
    : QObject(parent) {}

IUtils* IUtils::create(QQmlEngine* engine, QJSEngine* jsEngine) {
    Q_UNUSED(jsEngine);

    engine->addImageProvider(u"ccache"_s, new CachingImageProvider(CachingImageProvider::FillMode::Crop));
    engine->addImageProvider(u"fcache"_s, new CachingImageProvider(CachingImageProvider::FillMode::Fit));
    engine->addImageProvider(u"scache"_s, new CachingImageProvider(CachingImageProvider::FillMode::Stretch));

    return new IUtils(engine);
}

QUrl IUtils::urlForPath(const QString& path, int fillMode) {
    if (path.isEmpty())
        return {};

    QString prefix;
    switch (fillMode) {
    case 1: // Image.PreserveAspectFit
        prefix = u"fcache"_s;
        break;
    case 2: // Image.PreserveAspectCrop
        prefix = u"ccache"_s;
        break;
    default: // Image.Stretch or any other ones
        prefix = u"scache"_s;
        break;
    }

    QUrl url;
    url.setScheme(u"image"_s);
    url.setHost(prefix);
    url.setPath(path.startsWith(u'/') ? path : u'/' + path);
    return url;
}

} // namespace caelestia::images
