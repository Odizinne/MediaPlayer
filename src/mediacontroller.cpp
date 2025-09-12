#include "mediacontroller.h"
#include <QCursor>
#include <QProcess>

MediaController* MediaController::s_instance = nullptr;
CoverArtImageProvider* MediaController::s_coverArtProvider = nullptr;

CoverArtImageProvider::CoverArtImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage CoverArtImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QImage image = m_coverImages.value(id);

    if (image.isNull()) {
        image = QImage(256, 256, QImage::Format_ARGB32);
        image.fill(Qt::transparent);

        if (size) {
            *size = image.size();
        }
        return image;
    }

    if (size) {
        *size = image.size();
    }

    if (requestedSize.isValid()) {
        return image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    return image;
}

void CoverArtImageProvider::setCoverArt(const QString &filePath, const QImage &image)
{
    QString key = QUrl::fromLocalFile(filePath).toString();
    m_coverImages[key] = image;
}

void CoverArtImageProvider::clearCoverArt(const QString &filePath)
{
    QString key = QUrl::fromLocalFile(filePath).toString();
    m_coverImages.remove(key);
}

MediaController::MediaController(QObject *parent)
    : QObject(parent), m_currentIndex(-1), m_metadataPlayer(nullptr),
    m_metadataAudioOutput(nullptr), m_activeAudioTrack(-1), m_activeSubtitleTrack(-1)
{
    if (!s_coverArtProvider) {
        s_coverArtProvider = new CoverArtImageProvider();
    }

    m_metadataPlayer = new QMediaPlayer(this);
    m_metadataAudioOutput = new QAudioOutput(this);
    m_metadataPlayer->setAudioOutput(m_metadataAudioOutput);

    connect(m_metadataPlayer, &QMediaPlayer::metaDataChanged,
            this, &MediaController::onMetadataChanged);
    connect(m_metadataPlayer, &QMediaPlayer::mediaStatusChanged,
            this, &MediaController::onMediaStatusChanged);

    QStringList args = QGuiApplication::arguments();

    if (args.size() > 1) {
        QString filePath = args.at(1);
        QFileInfo fileInfo(filePath);

        if (fileInfo.exists() && fileInfo.isFile()) {
            m_initialMediaPath = QUrl::fromLocalFile(fileInfo.absoluteFilePath()).toString();
        }
    }

    m_powerEventFilter = new WindowsPowerEventFilter(this);
    connect(m_powerEventFilter, &WindowsPowerEventFilter::systemResumed,
            this, &MediaController::systemResumed);
}

MediaController* MediaController::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine);
    Q_UNUSED(jsEngine);

    if (!s_instance) {
        s_instance = new MediaController();

        if (qmlEngine && s_coverArtProvider) {
            qmlEngine->addImageProvider("coverart", s_coverArtProvider);
        }
    }
    return s_instance;
}

MediaController* MediaController::instance()
{
    return s_instance;
}

void MediaController::loadMediaMetadata(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return;
    }

    m_currentTitle.clear();
    m_currentArtist.clear();
    m_currentAlbum.clear();
    m_currentCoverArtUrl.clear();

    m_metadataPlayer->setSource(QUrl(filePath));

    QSettings settings("Odizinne", "MediaPlayer");
    QString audioLanguage = settings.value("preferredAudioLanguage", "en").toString();
    QString subtitleLanguage = settings.value("preferredSubtitleLanguage", "en").toString();
    bool autoSelectSubtitles = settings.value("autoSelectSubtitles", true).toBool();

    qDebug() << "MediaController: Read preferences - Audio:" << audioLanguage
             << "Subtitle:" << subtitleLanguage << "Auto-select:" << autoSelectSubtitles;

    emit trackSelectionRequested(audioLanguage, subtitleLanguage, autoSelectSubtitles);
}

void MediaController::onMediaStatusChanged(QMediaPlayer::MediaStatus status)
{
    if (status == QMediaPlayer::LoadedMedia) {
        onMetadataChanged();
    }
}

void MediaController::onMetadataChanged()
{
    QMediaMetaData metaData = m_metadataPlayer->metaData();

    m_currentTitle = metaData.stringValue(QMediaMetaData::Title);
    m_currentArtist = metaData.stringValue(QMediaMetaData::AlbumArtist);
    if (m_currentArtist.isEmpty()) {
        m_currentArtist = metaData.stringValue(QMediaMetaData::ContributingArtist);
    }
    m_currentAlbum = metaData.stringValue(QMediaMetaData::AlbumTitle);

    QVariant coverArtVariant = metaData.value(QMediaMetaData::CoverArtImage);
    if (coverArtVariant.isValid()) {
        QImage coverImage = coverArtVariant.value<QImage>();
        if (!coverImage.isNull()) {
            QString currentSource = m_metadataPlayer->source().toString();
            s_coverArtProvider->setCoverArt(currentSource, coverImage);
            m_currentCoverArtUrl = "image://coverart/" + currentSource;
        }
    }

    if (m_currentTitle.isEmpty()) {
        QString currentSource = m_metadataPlayer->source().toString();
        m_currentTitle = getFileName(currentSource);

        int lastDot = m_currentTitle.lastIndexOf('.');
        if (lastDot > 0) {
            m_currentTitle = m_currentTitle.left(lastDot);
        }
    }

    emit metadataChanged();
}

QString MediaController::getInitialMediaPath() const
{
    return m_initialMediaPath;
}

QString MediaController::formatDuration(qint64 duration)
{
    if (duration <= 0) return "00:00:00";

    int hours = duration / 3600000;
    int minutes = (duration % 3600000) / 60000;
    int seconds = (duration % 60000) / 1000;

    return QString("%1:%2:%3")
        .arg(hours, 2, 10, QChar('0'))
        .arg(minutes, 2, 10, QChar('0'))
        .arg(seconds, 2, 10, QChar('0'));
}

QString MediaController::getFileName(const QString &filePath)
{
    if (filePath.isEmpty()) return "";

    QString path = filePath;
    if (path.startsWith("file://")) {
        path = path.mid(7);
    }

    int lastSlash = qMax(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    return lastSlash >= 0 ? path.mid(lastSlash + 1) : path;
}

qint64 MediaController::getFileSize(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    return fileInfo.size();
}

QString MediaController::formatFileSize(qint64 bytes)
{
    if (bytes == 0) return "0 B";

    double k = 1024.0;
    QStringList sizes = {"B", "KB", "MB", "GB"};
    int i = qFloor(qLn(bytes) / qLn(k));

    return QString::number(bytes / qPow(k, i), 'f', 1) + " " + sizes[i];
}

void MediaController::copyPathToClipboard(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(localPath);
}

void MediaController::buildPlaylistFromFile(const QString &filePath)
{
    m_playlist.clear();
    m_currentIndex = -1;

    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        qDebug() << "File doesn't exist or is not a file";
        emit playlistChanged();
        return;
    }

    QDir directory = fileInfo.dir();
    m_playlist = getSupportedMediaFiles(directory);
    QString currentAbsolutePath = fileInfo.absoluteFilePath();

    for (int i = 0; i < m_playlist.size(); ++i) {
        QString playlistAbsolutePath = QFileInfo(m_playlist[i]).absoluteFilePath();

        if (playlistAbsolutePath == currentAbsolutePath) {
            m_currentIndex = i;
            break;
        }
    }

    if (m_currentIndex == -1) {
        qDebug() << "WARNING: Current file not found in playlist!";
    }

    emit playlistChanged();
}

QString MediaController::getNextFile() const
{
    if (m_playlist.isEmpty() || m_currentIndex < 0 || m_currentIndex >= m_playlist.size() - 1) {
        return QString();
    }

    return QUrl::fromLocalFile(m_playlist[m_currentIndex + 1]).toString();
}

QString MediaController::getPreviousFile() const
{
    if (m_playlist.isEmpty() || m_currentIndex <= 0) {
        return QString();
    }

    return QUrl::fromLocalFile(m_playlist[m_currentIndex - 1]).toString();
}

bool MediaController::hasNext() const
{
    return !m_playlist.isEmpty() && m_currentIndex >= 0 && m_currentIndex < m_playlist.size() - 1;
}

bool MediaController::hasPrevious() const
{
    return !m_playlist.isEmpty() && m_currentIndex > 0;
}

void MediaController::setCurrentFile(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    QString currentAbsolutePath = fileInfo.absoluteFilePath();

    for (int i = 0; i < m_playlist.size(); ++i) {
        QString playlistAbsolutePath = QFileInfo(m_playlist[i]).absoluteFilePath();
        if (playlistAbsolutePath == currentAbsolutePath) {
            if (m_currentIndex != i) {
                m_currentIndex = i;
                emit playlistChanged();
            }
            break;
        }
    }
}

int MediaController::getCurrentIndex() const
{
    return m_currentIndex;
}

int MediaController::getPlaylistSize() const
{
    return m_playlist.size();
}

QStringList MediaController::getSupportedMediaFiles(const QDir &directory) const
{
    QStringList nameFilters;
    nameFilters << "*.mp4" << "*.avi" << "*.mov" << "*.mkv" << "*.webm" << "*.wmv" << "*.m4v" << "*.flv"
                << "*.mp3" << "*.wav" << "*.flac" << "*.ogg" << "*.aac" << "*.wma" << "*.m4a";

    QStringList files = directory.entryList(nameFilters, QDir::Files, QDir::Name);
    QStringList absolutePaths;

    for (const QString &file : std::as_const(files)) {
        absolutePaths << directory.absoluteFilePath(file);
    }

    return absolutePaths;
}

bool MediaController::isMediaFile(const QString &fileName) const
{
    QString lowerName = fileName.toLower();
    QStringList extensions = {".mp4", ".avi", ".mov", ".mkv", ".webm", ".wmv", ".m4v", ".flv",
                              ".mp3", ".wav", ".flac", ".ogg", ".aac", ".wma", ".m4a"};

    for (const QString &ext : extensions) {
        if (lowerName.endsWith(ext)) {
            return true;
        }
    }
    return false;
}

void MediaController::setCursorState(CursorState state)
{
    switch (state) {
    case Normal:
        QGuiApplication::restoreOverrideCursor();
        break;
    case Hidden:
        QGuiApplication::setOverrideCursor(QCursor(Qt::BlankCursor));
        break;
    }
}

void MediaController::setPreventSleep(bool prevent)
{
    if (prevent && !m_sleepPrevented) {
        SetThreadExecutionState(ES_CONTINUOUS | ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED);
        m_sleepPrevented = true;
    } else if (!prevent && m_sleepPrevented) {
        SetThreadExecutionState(ES_CONTINUOUS);
        m_sleepPrevented = false;
    }
}

void MediaController::copyFilePathToClipboard(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(localPath);
}

void MediaController::openInExplorer(const QString &filePath)
{
    QString localPath = filePath;
    if (localPath.startsWith("file://")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists()) {
        return;
    }

    QStringList args;
    args << "/select," << QDir::toNativeSeparators(localPath);
    QProcess::startDetached("explorer", args);
}

void MediaController::setActiveAudioTrack(int track)
{
    if (m_activeAudioTrack != track) {
        m_activeAudioTrack = track;
        qDebug() << "MediaController: Audio track changed to" << track;
        emit tracksChanged();
    }
}

void MediaController::setActiveSubtitleTrack(int track)
{
    if (m_activeSubtitleTrack != track) {
        m_activeSubtitleTrack = track;
        qDebug() << "MediaController: Subtitle track changed to" << track;
        emit tracksChanged();
    }
}

void MediaController::updateTracks(const QVariantList &audioTracks, const QVariantList &subtitleTracks, int activeAudio, int activeSubtitle)
{
    bool changed = false;

    if (m_audioTracks != audioTracks) {
        m_audioTracks = audioTracks;
        changed = true;
    }

    if (m_subtitleTracks != subtitleTracks) {
        m_subtitleTracks = subtitleTracks;
        changed = true;
    }

    if (m_activeAudioTrack != activeAudio) {
        m_activeAudioTrack = activeAudio;
        changed = true;
    }

    if (m_activeSubtitleTrack != activeSubtitle) {
        m_activeSubtitleTrack = activeSubtitle;
        changed = true;
    }

    if (changed) {
        emit tracksChanged();
    }
}

void MediaController::selectDefaultTracks()
{
    qDebug() << "Track selection is now handled in QML";
}

