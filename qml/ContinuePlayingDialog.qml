import QtQuick.Controls.FluentWinUI3

Dialog {
    id: dialog
    title: "Continue Playing?"
    anchors.centerIn: parent
    modal: true
    footer: DialogButtonBox {
        Button {
            text: "Yes"
            highlighted: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: dialog.accept()
        }
        Button {
            text: "No"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: dialog.reject()
        }
    }
}
