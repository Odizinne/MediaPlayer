import QtQuick
import QtQuick.Controls.FluentWinUI3
import QtQuick.Controls.impl

Item {
    id: forwardOverlay
    width: 120
    height: 120
    z: 1000
    opacity: 0.0
    scale: 1.0

    signal triggered()

    Rectangle {
        anchors.fill: parent
        color: palette.window
        opacity: 0.5
        radius: width
    }

    Column {
        anchors.centerIn: parent
        spacing: 5

        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/forward.svg"
            sourceSize.width: 60
            sourceSize.height: 60
            color: palette.windowText
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "+10s"
            color: palette.windowText
            font.pointSize: 12
            font.bold: true
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Timer {
        id: forwardHideTimer
        interval: 1500
        onTriggered: forwardOverlay.opacity = 0.0
    }

    function hide() {
        if (opacity > 0) {
            opacity = 0
            forwardHideTimer.stop()
        }
    }

    function trigger() {
        triggered()
        opacity = 1.0
        forwardHideTimer.restart()
    }
}
