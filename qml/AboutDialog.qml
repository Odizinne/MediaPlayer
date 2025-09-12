import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.FluentWinUI3
import Odizinne.MediaPlayer

Dialog {
    width: 310

    ColumnLayout {
        anchors.fill: parent

        Image {
            Layout.alignment: Qt.AlignCenter
            source: "qrc:/icons/icon.png"
            sourceSize.width: 96
            sourceSize.height: 96
        }

        Label {
            Layout.alignment: Qt.AlignCenter
            text: VersionHelper.getAppName()
            font.pixelSize: 22
            font.bold: true
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 4

            Label {
                Layout.alignment: Qt.AlignCenter
                text: VersionHelper.getAppVersion()
                font.pixelSize: 11
                opacity: 0.7
            }

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "by <a href='#'>Odizinne</a>"
                font.pixelSize: 13
                textFormat: Text.RichText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://github.com/Odizinne/" + VersionHelper.getAppName())
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "Donate"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: Qt.openUrlExternally("https://ko-fi.com/odizinne")
        }
        Button {
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
}
