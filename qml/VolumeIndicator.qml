import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick

Rectangle {
    id: control
    height: volLyt.implicitHeight + 40
    width: volLyt.implicitWidth + 40
    color: Qt.rgba(0, 0, 0, 0.8)
    property alias value: customProgressBar.value
    ColumnLayout {
        id: volLyt
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Item {
            id: customProgressBar
            Layout.preferredWidth: 10
            Layout.preferredHeight: 80
            Layout.alignment: Qt.AlignHCenter
            property real value: 0
            property real from: 0
            property real to: 1
            property real position: (value - from) / (to - from)

            Rectangle {
                anchors.fill: parent
                color: "#515151"
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width
                height: parent.height * customProgressBar.position
                color: palette.highlight

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Rectangle {
                id: progressTip
                color: "white"
                width: parent.width
                height: parent.width
                x: 0
                y: parent.height - parent.width - (parent.height - parent.width) * customProgressBar.position

                Behavior on y {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        TextMetrics {
            id: textMetrics
            font: label.font
            text: "999"
        }

        Label {
            id: label
            text: Math.round(customProgressBar.value * 100).toString()
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: textMetrics.width
            horizontalAlignment: Text.AlignHCenter
            color: "white"
        }
    }
}
