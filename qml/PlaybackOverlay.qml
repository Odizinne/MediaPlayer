import QtQuick
import QtQuick.Controls.impl

Item {
    id: overlay
    width: 120
    height: 120
    z: 1000
    opacity: 0.0
    scale: 0.0

    property alias source: symbol.source

    Rectangle {
        anchors.fill: parent
        color: palette.window
        opacity: 0.5
        radius: width
    }

    IconImage {
        id: symbol
        anchors.fill: parent

        sourceSize.width: 80
        sourceSize.height: 80
        color: palette.windowText
    }

    ParallelAnimation {
        id: showAnim
        running: false

        SequentialAnimation {
            PropertyAnimation { target: overlay; property: "scale"; from: 0.0; to: 0.25; duration: 150; easing.type: Easing.OutBack }
            PropertyAnimation { target: overlay; property: "scale"; from: 0.25; to: 1.0; duration: 650; easing.type: Easing.OutCubic }
        }

        SequentialAnimation {
            PropertyAnimation { target: overlay; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.InQuad }
            PropertyAnimation { target: overlay; property: "opacity"; from: 1; to: 0; duration: 650; easing.type: Easing.OutQuad }
        }
    }

    function trigger() { showAnim.restart() }
}
