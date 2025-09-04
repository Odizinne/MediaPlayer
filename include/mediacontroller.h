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
#include <QStringList>
#include <QDebug>

class MediaController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Playlist properties for QML binding
    Q_PROPERTY(bool hasNext READ hasNext NOTIFY playlistChanged)
    Q_PROPERTY(bool hasPrevious READ hasPrevious NOTIFY playlistChanged)
    Q_PROPERTY(int currentIndex READ getCurrentIndex NOTIFY playlistChanged)
    Q_PROPERTY(int playlistSize READ getPlaylistSize NOTIFY playlistChanged)

public:
    static MediaController* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static MediaController* instance();

    Q_INVOKABLE QString getInitialMediaPath() const;
    Q_INVOKABLE QString formatDuration(qint64 milliseconds);
    Q_INVOKABLE QString getFileName(const QString &filePath);
    Q_INVOKABLE qint64 getFileSize(const QString &filePath);
    Q_INVOKABLE QString formatFileSize(qint64 bytes);
    Q_INVOKABLE void copyPathToClipboard(const QString &filePath);

    // Playlist functions
    Q_INVOKABLE void buildPlaylistFromFile(const QString &filePath);
    Q_INVOKABLE QString getNextFile() const;
    Q_INVOKABLE QString getPreviousFile() const;
    Q_INVOKABLE void setCurrentFile(const QString &filePath);
    Q_INVOKABLE void debugPlaylist() const;

    // Property getters
    bool hasNext() const;
    bool hasPrevious() const;
    int getCurrentIndex() const;
    int getPlaylistSize() const;

signals:
    void playlistChanged();

private:
    explicit MediaController(QObject *parent = nullptr);
    static MediaController* s_instance;
    QString m_initialMediaPath;

    // Playlist data
    QStringList m_playlist;
    int m_currentIndex;

    QStringList getSupportedMediaFiles(const QDir &directory) const;
    bool isMediaFile(const QString &fileName) const;
};

#endif // MEDIACONTROLLER_H
