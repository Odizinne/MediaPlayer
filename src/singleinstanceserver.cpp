#include "singleinstanceserver.h"
#include <QLocalSocket>
#include <QDataStream>
#include <QDebug>
#include <QCoreApplication>

SingleInstanceServer::SingleInstanceServer(QObject *parent)
    : QObject(parent), m_server(nullptr)
{
    // Use application name as server name to ensure uniqueness
    m_serverName = QCoreApplication::applicationName() + "_SingleInstance";
}

SingleInstanceServer::~SingleInstanceServer()
{
    if (m_server) {
        m_server->close();
        delete m_server;
    }
}

bool SingleInstanceServer::connectToExistingInstance(const QString &filePath)
{
    QLocalSocket socket;
    socket.connectToServer(m_serverName);

    if (!socket.waitForConnected(MESSAGE_TIMEOUT_MS)) {
        return false;  // No existing instance
    }

    // Send file path to existing instance
    QDataStream out(&socket);
    out << filePath;

    if (!socket.waitForBytesWritten(MESSAGE_TIMEOUT_MS)) {
        qWarning() << "Failed to send file path to existing instance";
        return false;
    }

    socket.disconnectFromServer();
    socket.waitForDisconnected(1000);

    qDebug() << "Sent file to existing instance:" << filePath;
    return true;
}

bool SingleInstanceServer::startServer()
{
    // Remove any stale server
    QLocalServer::removeServer(m_serverName);

    m_server = new QLocalServer(this);
    connect(m_server, &QLocalServer::newConnection, this, &SingleInstanceServer::onNewConnection);

    if (!m_server->listen(m_serverName)) {
        qWarning() << "Failed to start local server:" << m_server->errorString();
        return false;
    }

    qDebug() << "Local server started on:" << m_serverName;
    return true;
}

void SingleInstanceServer::onNewConnection()
{
    QLocalSocket *socket = m_server->nextPendingConnection();
    if (!socket) {
        return;
    }

    connect(socket, &QLocalSocket::readyRead, this, &SingleInstanceServer::onClientSocketReadyRead);
    connect(socket, &QLocalSocket::disconnected, this, &SingleInstanceServer::onClientSocketDisconnected);
}

void SingleInstanceServer::onClientSocketReadyRead()
{
    QLocalSocket *socket = qobject_cast<QLocalSocket *>(sender());
    if (!socket) {
        return;
    }

    QDataStream in(socket);
    QString filePath;
    in >> filePath;

    if (!filePath.isEmpty()) {
        qDebug() << "Received file path from another instance:" << filePath;
        emit filePathReceived(filePath);
    }

    cleanupSocket(socket);
}

void SingleInstanceServer::onClientSocketDisconnected()
{
    QLocalSocket *socket = qobject_cast<QLocalSocket *>(sender());
    if (socket) {
        cleanupSocket(socket);
    }
}

void SingleInstanceServer::cleanupSocket(QLocalSocket *socket)
{
    if (socket) {
        socket->close();
        socket->deleteLater();
    }
}
