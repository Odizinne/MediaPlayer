import QtQuick.Controls.FluentWinUI3
import QtQuick.Controls.impl
import QtQuick.Layouts
import QtQuick
import Odizinne.MediaPlayer

Popup {
    id: popup
    visible: true
    modal: false
    opacity: 0.0
    background.implicitWidth: 200
    background.implicitHeight: 50
    closePolicy: Popup.NoAutoClose
    property alias value: customProgressBar.value
    enter: null
    exit: null

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Timer {
        id: volumeHideTimer
        interval: 1500
        onTriggered: popup.opacity = 0.0
    }

    function show() {
        opacity = 1.0
        volumeHideTimer.restart()
    }

    contentItem: RowLayout {
        IconImage {
            source: "qrc:/icons/volume.svg"
            sourceSize.width: 16
            sourceSize.height: 16
            color: palette.windowText
        }

        Item {
            id: customProgressBar
            Layout.preferredWidth: 110
            Layout.preferredHeight: 4
            Layout.alignment: Qt.AlignHCenter
            property real value: 0
            property real from: 0
            property real to: 1
            property real position: (value - from) / (to - from)

            Rectangle {
                anchors.fill: parent
                color: Common.isDarkMode ? "#9f9f9f" : "#8a8a8a"
                radius: 6
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * customProgressBar.position
                height: parent.height
                color: palette.accent
                radius: 6

                Behavior on width {
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
        }
    }
}
