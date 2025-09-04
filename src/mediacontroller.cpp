#include "MediaController.h"

MediaController* MediaController::s_instance = nullptr;

MediaController::MediaController(QObject *parent) : QObject(parent)
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
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)

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
