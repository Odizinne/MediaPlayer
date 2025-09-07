#ifndef WINDOWSPOWEREVENTFILTER_H
#define WINDOWSPOWEREVENTFILTER_H

#include <QObject>
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



#endif // WINDOWSPOWEREVENTFILTER_H
