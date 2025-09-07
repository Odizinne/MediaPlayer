#include "windowspowereventfilter.h"
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
    }
}

WindowsPowerEventFilter::~WindowsPowerEventFilter()
{
    if (m_installed && QGuiApplication::instance()) {
        QGuiApplication::instance()->removeNativeEventFilter(this);
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
                QTimer::singleShot(1000, this, &WindowsPowerEventFilter::systemResumed);
                break;
            case PBT_APMRESUMESUSPEND:
                QTimer::singleShot(1000, this, &WindowsPowerEventFilter::systemResumed);
                break;
            case PBT_APMSUSPEND:
                emit systemSuspending();
                break;
            case PBT_APMQUERYSUSPEND:
                break;
            }
        }
    }

    return false;
}

