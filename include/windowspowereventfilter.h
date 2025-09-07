#ifndef WINDOWSPOWEREVENTFILTER_H
#define WINDOWSPOWEREVENTFILTER_H

#include <QObject>

#ifdef Q_OS_WIN
#include <QAbstractNativeEventFilter>

class WindowsPowerEventFilter : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT

public:
    explicit WindowsPowerEventFilter(QObject *parent = nullptr);
    ~WindowsPowerEventFilter();

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

signals:
    void systemResumed();
    void systemSuspending();

private:
    bool m_installed;
};

#else
// Dummy class for non-Windows platforms
class WindowsPowerEventFilter : public QObject
{
    Q_OBJECT

public:
    explicit WindowsPowerEventFilter(QObject *parent = nullptr) : QObject(parent) {}

signals:
    void systemResumed();
    void systemSuspending();
};
#endif

#endif // WINDOWSPOWEREVENTFILTER_H
