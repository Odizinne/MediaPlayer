import QtQuick
import QtQuick.Controls.FluentWinUI3

ApplicationWindow {
    id: window
    visible: false
    opacity: 0
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "black"
    x: 0
    y: 0
    width: Screen.width
    height: Screen.height

    signal requestShowFullScreen()
    signal requestShowNormal()

    property bool mainWindowFullscreen: false

    function startAnimation() {
        fadeInAnimation.start()
    }

    NumberAnimation {
        id: fadeInAnimation
        target: window
        property: "opacity"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.Linear
        onFinished: {
            if (window.mainWindowFullscreen) {
                window.requestShowNormal()
            } else {
                window.requestShowFullScreen()
            }
            fadeOutAnimation.start()
        }
    }

    NumberAnimation {
        id: fadeOutAnimation
        target: window
        property: "opacity"
        from: 1
        to: 0
        duration: 200
        easing.type: Easing.Linear
        onFinished: {
            window.visible = false
            Common.isTransitioningToFullscreen = false
        }
    }
}
