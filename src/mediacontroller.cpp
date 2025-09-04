#include "MediaController.h"

MediaController* MediaController::s_instance = nullptr;

MediaController::MediaController(QObject *parent) : QObject(parent), m_currentIndex(-1)
{
    // Process command line arguments
    QStringList args = QGuiApplication::arguments();

    if (args.size() > 1) {
        QString filePath = args.at(1);
        QFileInfo fileInfo(filePath);

        if (fileInfo.exists() && fileInfo.isFile()) {
            m_initialMediaPath = QUrl::fromLocalFile(fileInfo.absoluteFilePath()).toString();
        }
    }
}

MediaController* MediaController::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine);
    Q_UNUSED(jsEngine);

    if (!s_instance) {
        s_instance = new MediaController();
    }
    return s_instance;
}

MediaController* MediaController::instance()
{
    return s_instance;
}

QString MediaController::getInitialMediaPath() const
{
    return m_initialMediaPath;
}

QString MediaController::formatDuration(qint64 milliseconds)
{
    if (milliseconds <= 0) return "0:00";

    int seconds = (milliseconds / 1000) % 60;
    int minutes = (milliseconds / (1000 * 60)) % 60;
    int hours = (milliseconds / (1000 * 60 * 60)) % 24;

    if (hours > 0) {
        return QString("%1:%2:%3")
        .arg(hours)
            .arg(minutes, 2, 10, QChar('0'))
            .arg(seconds, 2, 10, QChar('0'));
    } else {
        return QString("%1:%2")
        .arg(minutes)
            .arg(seconds, 2, 10, QChar('0'));
    }
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

    qDebug() << "Building playlist from:" << localPath;

    QFileInfo fileInfo(localPath);
    if (!fileInfo.exists() || !fileInfo.isFile()) {
        qDebug() << "File doesn't exist or is not a file";
        emit playlistChanged();
        return;
    }

    // Get directory and scan for media files
    QDir directory = fileInfo.dir();
    m_playlist = getSupportedMediaFiles(directory);

    qDebug() << "Found" << m_playlist.size() << "media files in directory";

    // Find current file index - compare absolute paths
    QString currentAbsolutePath = fileInfo.absoluteFilePath();
    qDebug() << "Looking for current file:" << currentAbsolutePath;

    for (int i = 0; i < m_playlist.size(); ++i) {
        QString playlistAbsolutePath = QFileInfo(m_playlist[i]).absoluteFilePath();
        qDebug() << "Comparing with playlist[" << i << "]:" << playlistAbsolutePath;

        if (playlistAbsolutePath == currentAbsolutePath) {
            m_currentIndex = i;
            qDebug() << "Found match at index:" << i;
            break;
        }
    }

    if (m_currentIndex == -1) {
        qDebug() << "WARNING: Current file not found in playlist!";
    }

    // Emit signal to update QML bindings
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

void MediaController::debugPlaylist() const
{
    qDebug() << "=== PLAYLIST DEBUG ===";
    qDebug() << "Playlist size:" << m_playlist.size();
    qDebug() << "Current index:" << m_currentIndex;
    qDebug() << "Has next:" << hasNext();
    qDebug() << "Has previous:" << hasPrevious();

    for (int i = 0; i < m_playlist.size(); ++i) {
        QString marker = (i == m_currentIndex) ? " <-- CURRENT" : "";
        qDebug() << "  " << i << ":" << QFileInfo(m_playlist[i]).fileName() << marker;
    }
    qDebug() << "======================";
}

QStringList MediaController::getSupportedMediaFiles(const QDir &directory) const
{
    QStringList nameFilters;
    nameFilters << "*.mp4" << "*.avi" << "*.mov" << "*.mkv" << "*.webm" << "*.wmv" << "*.m4v" << "*.flv"
                << "*.mp3" << "*.wav" << "*.flac" << "*.ogg" << "*.aac" << "*.wma" << "*.m4a";

    QStringList files = directory.entryList(nameFilters, QDir::Files, QDir::Name);
    QStringList absolutePaths;

    for (const QString &file : files) {
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
