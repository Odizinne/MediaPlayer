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
#include <QTimer>
#include <QSettings>
#include <Windows.h>
#include "windowspowereventfilter.h"
#include "singleinstanceserver.h"

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
    Q_PROPERTY(QVariantList audioTracks READ getAudioTracks NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList subtitleTracks READ getSubtitleTracks NOTIFY tracksChanged)
    Q_PROPERTY(int activeAudioTrack READ getActiveAudioTrack WRITE setActiveAudioTrack NOTIFY tracksChanged)
    Q_PROPERTY(int activeSubtitleTrack READ getActiveSubtitleTrack WRITE setActiveSubtitleTrack NOTIFY tracksChanged)

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
    Q_INVOKABLE QString formatDuration(qint64 duration);
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
    Q_INVOKABLE void updateTracks(const QVariantList &audioTracks, const QVariantList &subtitleTracks, int activeAudio, int activeSubtitle);
    Q_INVOKABLE void selectDefaultTracks();

    void setInstanceServer(SingleInstanceServer *server);

    bool hasNext() const;
    bool hasPrevious() const;
    int getCurrentIndex() const;
    int getPlaylistSize() const;

    QString getCurrentTitle() const { return m_currentTitle; }
    QString getCurrentArtist() const { return m_currentArtist; }
    QString getCurrentAlbum() const { return m_currentAlbum; }
    QString getCurrentCoverArtUrl() const { return m_currentCoverArtUrl; }

    QVariantList getAudioTracks() const { return m_audioTracks; }
    QVariantList getSubtitleTracks() const { return m_subtitleTracks; }
    int getActiveAudioTrack() const { return m_activeAudioTrack; }
    int getActiveSubtitleTrack() const { return m_activeSubtitleTrack; }
    void setActiveAudioTrack(int track);
    void setActiveSubtitleTrack(int track);

signals:
    void playlistChanged();
    void metadataChanged();
    void systemResumed();
    void tracksChanged();
    void trackSelectionRequested(const QString &audioLanguage, const QString &subtitleLanguage, bool autoSelectSubtitles);
    void fileReceivedFromAnotherInstance(const QString &filePath);

private slots:
    void onMetadataChanged();
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status);
    void onFilePathReceivedFromInstance(const QString &filePath);

private:
    explicit MediaController(QObject *parent = nullptr);
    ~MediaController();
    static MediaController* s_instance;
    QString m_initialMediaPath;
    SingleInstanceServer* m_instanceServer;

    QStringList m_playlist;
    int m_currentIndex;

    QMediaPlayer* m_metadataPlayer;
    QAudioOutput* m_metadataAudioOutput;
    QString m_currentTitle;
    QString m_currentArtist;
    QString m_currentAlbum;
    QString m_currentCoverArtUrl;

    QVariantList m_audioTracks;
    QVariantList m_subtitleTracks;
    int m_activeAudioTrack;
    int m_activeSubtitleTrack;

    static CoverArtImageProvider* s_coverArtProvider;

    QStringList getSupportedMediaFiles(const QDir &directory) const;
    bool isMediaFile(const QString &fileName) const;
    void extractMetadataFromFile(const QString &filePath);
    bool m_sleepPrevented = false;
    WindowsPowerEventFilter* m_powerEventFilter;
};

#endif // MEDIACONTROLLER_H
