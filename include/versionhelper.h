#ifndef VERSIONHELPER_H
#define VERSIONHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QGuiApplication>

class VersionHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static VersionHelper* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static VersionHelper* instance();

    Q_INVOKABLE QString getAppVersion() const;
    Q_INVOKABLE QString getQtVersion() const;
    Q_INVOKABLE QString getCommitHash() const;
    Q_INVOKABLE QString getBuildTimestamp() const;
    Q_INVOKABLE QString getAppName() const;

private:
    explicit VersionHelper(QObject *parent = nullptr);
    static VersionHelper* s_instance;
};

#endif // VERSIONHELPER_H
