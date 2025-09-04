#ifndef MEDIACONTROLLER_H
#define MEDIACONTROLLER_H

#include <QObject>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QFileInfo>
#include <QUrl>
#include <QStandardPaths>
#include <QDir>
#include <QClipboard>
#include <QMimeData>

class MediaController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    static MediaController* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static MediaController* instance();

    Q_INVOKABLE QString getInitialMediaPath() const;
    Q_INVOKABLE QString formatDuration(qint64 milliseconds);
    Q_INVOKABLE QString getFileName(const QString &filePath);
    Q_INVOKABLE qint64 getFileSize(const QString &filePath);
    Q_INVOKABLE QString formatFileSize(qint64 bytes);
    Q_INVOKABLE void copyPathToClipboard(const QString &filePath);

private:
    explicit MediaController(QObject *parent = nullptr);
    static MediaController* s_instance;
    QString m_initialMediaPath;
};

#endif // MEDIACONTROLLER_H