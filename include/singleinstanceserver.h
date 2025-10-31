#ifndef SINGLEINSTANCESERVER_H
#define SINGLEINSTANCESERVER_H

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QString>

class SingleInstanceServer : public QObject
{
    Q_OBJECT

public:
    explicit SingleInstanceServer(QObject *parent = nullptr);
    ~SingleInstanceServer();

    /**
     * Attempts to connect to an existing instance and send a file path
     * @return true if successfully sent to existing instance, false if no existing instance
     */
    bool connectToExistingInstance(const QString &filePath);

    /**
     * Starts the local server to listen for new instances
     * @return true if server started successfully
     */
    bool startServer();

    /**
     * Gets the server name (socket name)
     */
    QString getServerName() const { return m_serverName; }

signals:
    /**
     * Emitted when another instance sends a file path to this instance
     */
    void filePathReceived(const QString &filePath);

private slots:
    void onNewConnection();
    void onClientSocketReadyRead();
    void onClientSocketDisconnected();

private:
    QLocalServer *m_server;
    QString m_serverName;
    static const int MESSAGE_TIMEOUT_MS = 5000;

    void cleanupSocket(QLocalSocket *socket);
};

#endif // SINGLEINSTANCESERVER_H
