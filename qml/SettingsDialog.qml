import QtQuick.Controls.FluentWinUI3
import QtQuick.Layouts
import QtQuick
import Odizinne.MediaPlayer

Dialog {
    standardButtons: Dialog.Close
    width: 400
    modal: true
    title: "MediaPlayer Settings"

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        RowLayout {
            Label {
                text: "Preferred audio language"
                Layout.fillWidth: true
            }

            ComboBox {
                id: audioLanguageCombo
                model: ListModel {
                    ListElement { text: "English"; value: "en" }
                    ListElement { text: "French"; value: "fr" }
                    ListElement { text: "German"; value: "de" }
                    ListElement { text: "Spanish"; value: "es" }
                    ListElement { text: "Japanese"; value: "ja" }
                }

                textRole: "text"

                Component.onCompleted: {
                    for (let i = 0; i < model.count; i++) {
                        if (model.get(i).value === UserSettings.preferredAudioLanguage) {
                            currentIndex = i
                            break
                        }
                    }
                }

                onActivated: function(index) {
                    UserSettings.preferredAudioLanguage = model.get(index).value
                }
            }
        }

        RowLayout {
            Label {
                text: "Preferred subtitles language"
                Layout.fillWidth: true
            }

            ComboBox {
                id: subtitleLanguageCombo
                model: ListModel {
                    ListElement { text: "English"; value: "en" }
                    ListElement { text: "French"; value: "fr" }
                    ListElement { text: "German"; value: "de" }
                    ListElement { text: "Spanish"; value: "es" }
                    ListElement { text: "Japanese"; value: "ja" }
                }

                textRole: "text"

                Component.onCompleted: {
                    for (let i = 0; i < model.count; i++) {
                        if (model.get(i).value === UserSettings.preferredSubtitleLanguage) {
                            currentIndex = i
                            break
                        }
                    }
                }

                onActivated: function(index) {
                    UserSettings.preferredSubtitleLanguage = model.get(index).value
                }
            }
        }

        RowLayout {
            Label {
                text: "Auto-select Subtitles"
                Layout.fillWidth: true
            }

            Switch {
                checked: UserSettings.autoSelectSubtitles
                onClicked: UserSettings.autoSelectSubtitles = !UserSettings.autoSelectSubtitles
            }
        }
    }
}
