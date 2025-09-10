#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    qputenv("QT_MULTIMEDIA_PREFERRED_PLUGINS", "directshow");
    QGuiApplication app(argc, argv);

    app.setOrganizationName("Odizinne");
    app.setApplicationName("MediaPlayer");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Odizinne.MediaPlayer", "Main");

    return app.exec();
}
