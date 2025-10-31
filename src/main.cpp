#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QLoggingCategory>
#include "singleinstanceserver.h"
#include "mediacontroller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QLoggingCategory::setFilterRules("qt.multimedia.*=false");

    app.setOrganizationName("Odizinne");
    app.setApplicationName("MediaPlayer");

    // Handle single instance
    SingleInstanceServer* instanceServer = new SingleInstanceServer();

    // Check if a file was passed as argument
    QString fileToOpen;
    if (argc > 1) {
        fileToOpen = QString::fromLocal8Bit(argv[1]);

        // Try to send to existing instance
        if (instanceServer->connectToExistingInstance(fileToOpen)) {
            // Successfully sent to existing instance, exit this one
            delete instanceServer;
            return 0;
        }
    }

    // Start the server for this instance
    instanceServer->startServer();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Odizinne.MediaPlayer", "Main");

    // Connect instance server to media controller after engine loads
    if (auto controller = MediaController::instance()) {
        controller->setInstanceServer(instanceServer);
    }

    return app.exec();
}
