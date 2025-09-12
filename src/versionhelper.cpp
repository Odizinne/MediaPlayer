#include "versionhelper.h"
#include "version.h"

VersionHelper* VersionHelper::s_instance = nullptr;

VersionHelper::VersionHelper(QObject *parent)
    : QObject(parent)
{
}

VersionHelper* VersionHelper::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine);
    Q_UNUSED(jsEngine);

    if (!s_instance) {
        s_instance = new VersionHelper();
    }
    return s_instance;
}

VersionHelper* VersionHelper::instance()
{
    return s_instance;
}

QString VersionHelper::getAppVersion() const
{
    return APP_VERSION_STRING;
}

QString VersionHelper::getQtVersion() const
{
    return QT_VERSION_STRING;
}

QString VersionHelper::getCommitHash() const
{
    return QString(GIT_COMMIT_HASH);
}

QString VersionHelper::getBuildTimestamp() const
{
    return QString(BUILD_TIMESTAMP);
}

QString VersionHelper::getAppName() const
{
    return QString(APP_NAME);
}
