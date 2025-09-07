#include "windowspowereventfilter.h"

#ifdef Q_OS_WIN
#include <Windows.h>
#include <QGuiApplication>
#include <QTimer>
#include <QDebug>

WindowsPowerEventFilter::WindowsPowerEventFilter(QObject *parent)
    : QObject(parent), m_installed(false)
{
    if (QGuiApplication::instance()) {
        QGuiApplication::instance()->installNativeEventFilter(this);
        m_installed = true;
        qDebug() << "Windows power event filter installed";
    }
}

WindowsPowerEventFilter::~WindowsPowerEventFilter()
{
    if (m_installed && QGuiApplication::instance()) {
        QGuiApplication::instance()->removeNativeEventFilter(this);
        qDebug() << "Windows power event filter removed";
    }
}

bool WindowsPowerEventFilter::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
    Q_UNUSED(result)

    if (eventType == "windows_generic_MSG") {
        MSG *msg = static_cast<MSG*>(message);

        if (msg->message == WM_POWERBROADCAST) {
            switch (msg->wParam) {
            case PBT_APMRESUMEAUTOMATIC:
                qDebug() << "System resumed automatically from sleep";
                QTimer::singleShot(1000, this, &WindowsPowerEventFilter::systemResumed);
                break;
            case PBT_APMRESUMESUSPEND:
                qDebug() << "System resumed from suspend";
                QTimer::singleShot(1000, this, &WindowsPowerEventFilter::systemResumed);
                break;
            case PBT_APMSUSPEND:
                qDebug() << "System going to sleep";
                emit systemSuspending();
                break;
            case PBT_APMQUERYSUSPEND:
                qDebug() << "System asking permission to sleep";
                break;
            }
        }
    }

    return false; // Let other filters process the event too
}

#else
// Non-Windows implementation - empty
WindowsPowerEventFilter::WindowsPowerEventFilter(QObject *parent)
    : QObject(parent)
{
    qDebug() << "Power event filter not supported on this platform";
}
#endif
