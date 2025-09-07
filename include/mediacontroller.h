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
#include <QImage>
#include <QPixmap>
#include <QQmlImageProviderBase>
#include <QQuickImageProvider>
#include <QMediaMetaData>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <Windows.h>
#include "windowspowereventfilter.h"

class CoverArtImageProvider : public QQuickImageProvider
{
public:
    CoverArtImageProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    void setCoverArt(const QString &filePath, const QImage &image);
    void clearCoverArt(const QString &filePath);

private:
    QHash<QString, QImage> m_coverImages;
};

class MediaController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool hasNext READ hasNext NOTIFY playlistChanged)
    Q_PROPERTY(bool hasPrevious READ hasPrevious NOTIFY playlistChanged)
    Q_PROPERTY(int currentIndex READ getCurrentIndex NOTIFY playlistChanged)
    Q_PROPERTY(int playlistSize READ getPlaylistSize NOTIFY playlistChanged)
    Q_PROPERTY(QString currentTitle READ getCurrentTitle NOTIFY metadataChanged)
    Q_PROPERTY(QString currentArtist READ getCurrentArtist NOTIFY metadataChanged)
    Q_PROPERTY(QString currentAlbum READ getCurrentAlbum NOTIFY metadataChanged)
    Q_PROPERTY(QString currentCoverArtUrl READ getCurrentCoverArtUrl NOTIFY metadataChanged)

public:
    static MediaController* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);
    static MediaController* instance();

    enum CursorState {
        Normal,
        Hidden
    };
    Q_ENUM(CursorState)

    Q_INVOKABLE void setCursorState(CursorState state);
    Q_INVOKABLE QString getInitialMediaPath() const;
    Q_INVOKABLE QString formatDuration(qint64 milliseconds);
    Q_INVOKABLE QString getFileName(const QString &filePath);
    Q_INVOKABLE qint64 getFileSize(const QString &filePath);
    Q_INVOKABLE QString formatFileSize(qint64 bytes);
    Q_INVOKABLE void copyPathToClipboard(const QString &filePath);
    Q_INVOKABLE void loadMediaMetadata(const QString &filePath);
    Q_INVOKABLE void buildPlaylistFromFile(const QString &filePath);
    Q_INVOKABLE QString getNextFile() const;
    Q_INVOKABLE QString getPreviousFile() const;
    Q_INVOKABLE void setCurrentFile(const QString &filePath);
    Q_INVOKABLE void setPreventSleep(bool prevent);
    Q_INVOKABLE void copyFilePathToClipboard(const QString &filePath);
    Q_INVOKABLE void openInExplorer(const QString &filePath);

    bool hasNext() const;
    bool hasPrevious() const;
    int getCurrentIndex() const;
    int getPlaylistSize() const;

    QString getCurrentTitle() const { return m_currentTitle; }
    QString getCurrentArtist() const { return m_currentArtist; }
    QString getCurrentAlbum() const { return m_currentAlbum; }
    QString getCurrentCoverArtUrl() const { return m_currentCoverArtUrl; }

signals:
    void playlistChanged();
    void metadataChanged();
    void systemResumed();

private slots:
    void onMetadataChanged();
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status);

private:
    explicit MediaController(QObject *parent = nullptr);
    static MediaController* s_instance;
    QString m_initialMediaPath;

    QStringList m_playlist;
    int m_currentIndex;

    QMediaPlayer* m_metadataPlayer;
    QAudioOutput* m_metadataAudioOutput;
    QString m_currentTitle;
    QString m_currentArtist;
    QString m_currentAlbum;
    QString m_currentCoverArtUrl;

    static CoverArtImageProvider* s_coverArtProvider;

    QStringList getSupportedMediaFiles(const QDir &directory) const;
    bool isMediaFile(const QString &fileName) const;
    void extractMetadataFromFile(const QString &filePath);
    bool m_sleepPrevented = false;
    WindowsPowerEventFilter* m_powerEventFilter;
};

#endif // MEDIACONTROLLER_H
