pragma Singleton

import QtCore

Settings {
    property string preferredAudioLanguage: "en"
    property string preferredSubtitleLanguage: "en"
    property bool autoSelectSubtitles: true

    function resetPreferences() {
        preferredAudioLanguage = "en"
        preferredSubtitleLanguage = "en"
        autoSelectSubtitles = true
    }
}
