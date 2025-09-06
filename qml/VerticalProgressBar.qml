import QtQuick
import QtQuick.Controls.Universal

ProgressBar {
    id: control
    implicitHeight: 100
    implicitWidth: 15

    contentItem: Rectangle {
        implicitWidth: 15
        implicitHeight: 100
        color: "transparent"

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width
            height: parent.height * control.position
            color: control.Universal.accent
        }
    }

    background: Rectangle {
        implicitHeight: 100
        implicitWidth: 15
        width: 10
        height: 100
        color: control.Universal.baseLowColor
    }
}
