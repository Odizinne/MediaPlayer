pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia
import Odizinne.MediaPlayer

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    minimumWidth: 1000
    minimumHeight: 700
    title: "MediaPlayer"
    Universal.theme: Universal.System
    Universal.accent: palette.highlight

    property var currentAudioOutput: null

    Component.onDestruction: {
        MediaController.setPreventSleep(false)
    }

    Connections {
        target: MediaController
        function onSystemResumed() {
            Qt.callLater(window.performAudioRecovery)
        }

        function onTrackSelectionRequested(audioLanguage, subtitleLanguage, autoSelectSubtitles) {
            console.log("Track selection requested - Audio:", audioLanguage, "Subtitle:", subtitleLanguage, "Auto:", autoSelectSubtitles)
            if (mediaPlayer.audioTracks.length > 0 || mediaPlayer.subtitleTracks.length > 0) {
                Qt.callLater(() => {
                                 mediaPlayer.selectTracksWithPreferences(audioLanguage, subtitleLanguage, autoSelectSubtitles)
                             })
            }
        }

        function onTracksChanged() {
            audioTracksMenu.updateMenu()
            subtitleTracksMenu.updateMenu()
        }
    }

    Connections {
        target: mediaPlayer
        function onPlaybackStateChanged() {
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                if (window.visibility === Window.FullScreen) {
                    hideTimer.restart()
                }
            } else {
                hideTimer.stop()
                controlsToolbar.opacity = 1.0
                MediaController.setCursorState(MediaController.Normal)
            }
        }
    }

    function performAudioRecovery() {
        try {
            updateAudioDevice()

            audioOutputLoader.active = false
            audioOutputLoader.active = true
        } catch (error) {
            console.log("Error in Loader-based recovery:", error)
        }
    }

    Loader {
        id: audioOutputLoader
        sourceComponent: Component {
            AudioOutput {
                device: window.currentAudioOutput
                volume: volumeSlider.value
                muted: muteButton.checked
            }
        }
    }

    MediaDevices {
        id: mediaDevices
        onAudioOutputsChanged: {
            window.updateAudioDevice()
        }
    }

    function updateAudioDevice() {
        const device = mediaDevices.defaultAudioOutput
        if (device.id !== (currentAudioOutput ? currentAudioOutput.id : "")) {
            currentAudioOutput = device
            if (audioOutputLoader.item) {
                audioOutputLoader.item.device = device
            }
        }
    }

    function playNext() {
        var nextFile = MediaController.getNextFile()
        if (nextFile !== "") {
            Common.loadMedia(nextFile)
            mediaPlayer.source = nextFile
        }
    }

    function playPrevious() {
        if (mediaPlayer.position > 5000) {
            mediaPlayer.setPosition(0)
        } else {
            var previousFile = MediaController.getPreviousFile()
            if (previousFile !== "") {
                Common.loadMedia(previousFile)
                mediaPlayer.source = previousFile
            } else {
                mediaPlayer.setPosition(0)
            }
        }
    }

    function showControls() {
        controlsToolbar.opacity = 1.0
        fullscreenToolbar.opacity = 1.0
        MediaController.setCursorState(MediaController.Normal)

        if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
            hideTimer.restart()
        } else {
            hideTimer.stop()
        }
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            controlsToolbar.opacity = 0.0
            fullscreenToolbar.opacity = 0.0
            MediaController.setCursorState(MediaController.Hidden)
        }
    }

    Shortcut {
        sequence: "M"
        onActivated: {
            muteButton.checked = !muteButton.checked
            volumeIndicator.show()
        }
    }

    Shortcut {
        sequence: "Up"
        onActivated: {
            var newVolume = volumeSlider.value + 0.05
            if (newVolume > 1.0) {
                newVolume = 1.0
            }
            volumeSlider.value = newVolume
            volumeIndicator.show()
        }
    }

    Shortcut {
        sequence: "Down"
        onActivated: {
            var newVolume = volumeSlider.value - 0.05
            if (newVolume < 0.0) {
                newVolume = 0.0
            }
            volumeSlider.value = newVolume
            volumeIndicator.show()
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: window.visibility === Window.FullScreen
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequence: "F11"
        enabled: Common.currentMediaPath !== ""
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequence: StandardKey.Open
        onActivated: fileDialog.open()
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                mediaPlayer.pause()
            } else {
                mediaPlayer.play()
            }
            overlay.trigger()
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            var newPosition = mediaPlayer.position + 10000
            if (newPosition > mediaPlayer.duration) {
                newPosition = mediaPlayer.duration
            }
            mediaPlayer.setPosition(newPosition)
            forwardOverlay.trigger()
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            var newPosition = mediaPlayer.position - 10000
            if (newPosition < 0) {
                newPosition = 0
            }
            mediaPlayer.setPosition(newPosition)
            rewindOverlay.trigger()
        }
    }

    Shortcut {
        sequence: "Ctrl+Right"
        onActivated: {
            if (MediaController.hasNext) {
                window.playNext()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Left"
        onActivated: window.playPrevious()
    }

//    Shortcut {
//        sequence: "A"
//        onActivated: {
//            var tracks = mediaPlayer.audioTracks
//            if (tracks.length > 1) {
//                var current = mediaPlayer.activeAudioTrack
//                var next = (current + 1) % tracks.length
//                mediaPlayer.activeAudioTrack = next
//                audioTrackOverlay.show()
//            }
//        }
//    }
//
//    Shortcut {
//        sequence: "S"
//        onActivated: {
//            var tracks = mediaPlayer.subtitleTracks
//            if (tracks.length > 0) {
//                var current = mediaPlayer.activeSubtitleTrack
//                var next = current >= tracks.length - 1 ? -1 : current + 1
//                mediaPlayer.activeSubtitleTrack = next
//                subtitleOverlay.show()
//            }
//        }
//    }

    Component.onCompleted: {
        updateAudioDevice()
        var initialPath = MediaController.getInitialMediaPath()
        if (initialPath !== "") {
            Common.loadMedia(initialPath)
            mediaPlayer.source = initialPath
        }
    }

    MediaPlayer {
        id: mediaPlayer
        audioOutput: audioOutputLoader.item as AudioOutput
        videoOutput: Common.isVideo ? videoOutput : null

        onPlaybackStateChanged: {
            MediaController.setPreventSleep(playbackState === MediaPlayer.PlayingState)
        }

        onTracksChanged: {
            console.log("MediaPlayer tracks changed - Audio:", audioTracks.length, "Subtitle:", subtitleTracks.length)
            MediaController.updateTracks(audioTracks, subtitleTracks, activeAudioTrack, activeSubtitleTrack)

            Qt.callLater(() => {
                             selectTracksWithPreferences(UserSettings.preferredAudioLanguage, UserSettings.preferredSubtitleLanguage, UserSettings.autoSelectSubtitles)
                         })
        }

        onActiveAudioTrackChanged: {
            console.log("MediaPlayer active audio track changed to:", activeAudioTrack)
            MediaController.setActiveAudioTrack(activeAudioTrack)
        }

        onActiveSubtitleTrackChanged: {
            console.log("MediaPlayer active subtitle track changed to:", activeSubtitleTrack)
            MediaController.setActiveSubtitleTrack(activeSubtitleTrack)
        }

        function selectTracksWithPreferences(audioLanguage, subtitleLanguage, autoSelectSubtitles) {
            console.log("=== QML TRACK SELECTION WITH PREFERENCES ===")
            console.log("Audio tracks:", audioTracks.length, "Subtitle tracks:", subtitleTracks.length)
            console.log("Current audio track:", activeAudioTrack, "Current subtitle track:", activeSubtitleTrack)
            console.log("Preferences - Audio:", audioLanguage, "Subtitle:", subtitleLanguage, "Auto:", autoSelectSubtitles)

            if (audioTracks.length > 1) {
                var preferredAudioIndex = findTrackByLanguage(audioTracks, audioLanguage)
                if (preferredAudioIndex >= 0 && preferredAudioIndex !== activeAudioTrack) {
                    console.log("Selecting audio track", preferredAudioIndex, "for language", audioLanguage)
                    activeAudioTrack = preferredAudioIndex
                }
            }

            if (autoSelectSubtitles && subtitleTracks.length > 0) {
                var preferredSubtitleIndex = findTrackByLanguage(subtitleTracks, subtitleLanguage)
                if (preferredSubtitleIndex >= 0 && preferredSubtitleIndex !== activeSubtitleTrack) {
                    console.log("Selecting subtitle track", preferredSubtitleIndex, "for language", subtitleLanguage)
                    activeSubtitleTrack = preferredSubtitleIndex
                }
            }

            console.log("=== END QML TRACK SELECTION ===")
        }

        function findTrackByLanguage(tracks, preferredLang) {
            console.log("Finding track for language:", preferredLang, "in", tracks.length, "tracks")

            var langMap = {
                "en": ["eng", "en", "english"],
                "fr": ["fre", "fra", "fr", "french", "français", "francais"],
                "de": ["ger", "deu", "de", "german", "deutsch"],
                "es": ["spa", "es", "spanish", "español", "espanol"],
                "it": ["ita", "it", "italian", "italiano"],
                "ja": ["jpn", "ja", "japanese"],
                "pt": ["por", "pt", "portuguese", "português", "portugues"],
                "ru": ["rus", "ru", "russian", "русский"],
                "zh": ["chi", "zho", "zh", "chinese", "中文", "mandarin"],
                "ko": ["kor", "ko", "korean", "한국어"]
            }

            var searchTerms = langMap[preferredLang.toLowerCase()] || [preferredLang.toLowerCase()]
            console.log("Search terms:", searchTerms)

            for (var i = 0; i < tracks.length; i++) {
                var track = tracks[i]
                console.log("Examining track", i)

                if (track) {
                    var language = ""
                    var title = ""

                    try {
                        if (track.stringValue !== undefined) {
                            language = track.stringValue(6) || ""
                            title = track.stringValue(0) || ""
                        }

                        language = language.toLowerCase()
                        title = title.toLowerCase()

                        console.log("Track", i, "- Language:", language, "Title:", title)

                        for (var j = 0; j < searchTerms.length; j++) {
                            var term = searchTerms[j]

                            if (language && language === term) {
                                console.log("✓ Exact language match:", language, "==", term)
                                return i
                            }

                            if (title && title.indexOf(term) >= 0) {
                                console.log("✓ Title contains match:", title, "contains", term)
                                return i
                            }
                        }

                    } catch (e) {
                        console.log("Error accessing track", i, "metadata:", e)
                    }
                }
            }

            console.log("✗ No match found for language:", preferredLang)
            return -1
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                if (Common.isVideo && videoOutput.sourceRect.width > 0) {
                    Common.mediaWidth = videoOutput.sourceRect.width
                    Common.mediaHeight = videoOutput.sourceRect.height
                }
                var fileName = Common.getFileName(Common.currentMediaPath)
                var playlistInfo = ""
                if (MediaController.playlistSize > 1) {
                    playlistInfo = " (" + (MediaController.currentIndex + 1) + "/" + MediaController.playlistSize + ")"
                }
                window.title = fileName + playlistInfo + " - MediaPlayer"
                mediaPlayer.play()
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.log("Error loading media:", Common.currentMediaPath)
                window.title = "MediaPlayer - Error loading media"
                MediaController.setPreventSleep(false)
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                MediaController.setPreventSleep(false)

                if (sleepButton.checked && MediaController.hasNext) {
                    continuePlayingDialog.open()
                } else if (MediaController.hasNext) {
                    window.playNext()
                }
            }
        }

        onErrorOccurred: function(error, errorString) {
            console.log("Media error:", errorString)
        }
    }

    header: ToolBar {
        height: 40
        visible: window.visibility !== Window.FullScreen

        background: Rectangle {
            implicitHeight: 48
            color: Universal.background
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: window.showControls()
            onEntered: window.showControls()
            propagateComposedEvents: true
        }

        ToolButton {
            id: openButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            icon.source: "qrc:/icons/file.svg"
            Universal.foreground: Universal.accent
            text: "Open media"
            onClicked: fileDialog.open()
        }

        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            ToolButton {
                id: audioTracksButton
                Layout.preferredHeight: 40
                icon.source: "qrc:/icons/track.svg"
                text: "Audio"
                visible: mediaPlayer.audioTracks.length > 1

                onClicked: audioTracksMenu.popup()

                Menu {
                    id: audioTracksMenu

                    function updateMenu() {
                        close()
                    }

                    Repeater {
                        model: mediaPlayer.audioTracks.length
                        MenuItem {
                            required property int index

                            text: {
                                var track = mediaPlayer.audioTracks[index]
                                if (track && track.stringValue) {
                                    var language = track.stringValue(6) || ""
                                    var title = track.stringValue(0) || ""
                                    return title || language || ("Track " + (index + 1))
                                }
                                return "Track " + (index + 1)
                            }
                            checkable: true
                            checked: MediaController.activeAudioTrack === index
                            onTriggered: {
                                mediaPlayer.activeAudioTrack = index
                                audioTrackOverlay.show()
                            }
                        }
                    }
                }
            }

            ToolButton {
                id: subtitleTracksButton
                Layout.preferredHeight: 40
                icon.source: "qrc:/icons/subtitle.svg"
                text: "Subtitles"
                visible: mediaPlayer.subtitleTracks.length > 0

                onClicked: subtitleTracksMenu.popup()

                Menu {
                    id: subtitleTracksMenu

                    function updateMenu() {
                        close()
                    }

                    MenuItem {
                        text: "Off"
                        checkable: true
                        checked: MediaController.activeSubtitleTrack === -1
                        onTriggered: {
                            mediaPlayer.activeSubtitleTrack = -1
                            subtitleOverlay.show()
                        }
                    }

                    MenuSeparator {}

                    Repeater {
                        model: mediaPlayer.subtitleTracks.length
                        MenuItem {
                            required property int index

                            text: {
                                var track = mediaPlayer.subtitleTracks[index]
                                if (track && track.stringValue) {
                                    var language = track.stringValue(6) || ""
                                    var title = track.stringValue(0) || ""
                                    return title || language || ("Track " + (index + 1))
                                }
                                return "Track " + (index + 1)
                            }
                            checkable: true
                            checked: MediaController.activeSubtitleTrack === index
                            onTriggered: {
                                mediaPlayer.activeSubtitleTrack = index
                                subtitleOverlay.show()
                            }
                        }
                    }
                }
            }

            ToolButton {
                id: settingsButton
                Layout.preferredHeight: 40
                icon.source: "qrc:/icons/cog.svg"
                text: "Settings"

                onClicked: settingsMenu.popup()

                Menu {
                    id: settingsMenu

                    Menu {
                        title: "Default Audio Language"

                        MenuItem {
                            text: "English"
                            checkable: true
                            checked: UserSettings.preferredAudioLanguage === "en"
                            onTriggered: UserSettings.preferredAudioLanguage = "en"
                        }
                        MenuItem {
                            text: "French"
                            checkable: true
                            checked: UserSettings.preferredAudioLanguage === "fr"
                            onTriggered: UserSettings.preferredAudioLanguage = "fr"
                        }
                        MenuItem {
                            text: "German"
                            checkable: true
                            checked: UserSettings.preferredAudioLanguage === "de"
                            onTriggered: UserSettings.preferredAudioLanguage = "de"
                        }
                        MenuItem {
                            text: "Spanish"
                            checkable: true
                            checked: UserSettings.preferredAudioLanguage === "es"
                            onTriggered: UserSettings.preferredAudioLanguage = "es"
                        }
                        MenuItem {
                            text: "Japanese"
                            checkable: true
                            checked: UserSettings.preferredAudioLanguage === "ja"
                            onTriggered: UserSettings.preferredAudioLanguage = "ja"
                        }
                    }

                    Menu {
                        title: "Default Subtitle Language"

                        MenuItem {
                            text: "English"
                            checkable: true
                            checked: UserSettings.preferredSubtitleLanguage === "en"
                            onTriggered: UserSettings.preferredSubtitleLanguage = "en"
                        }
                        MenuItem {
                            text: "French"
                            checkable: true
                            checked: UserSettings.preferredSubtitleLanguage === "fr"
                            onTriggered: UserSettings.preferredSubtitleLanguage = "fr"
                        }
                        MenuItem {
                            text: "German"
                            checkable: true
                            checked: UserSettings.preferredSubtitleLanguage === "de"
                            onTriggered: UserSettings.preferredSubtitleLanguage = "de"
                        }
                        MenuItem {
                            text: "Spanish"
                            checkable: true
                            checked: UserSettings.preferredSubtitleLanguage === "es"
                            onTriggered: UserSettings.preferredSubtitleLanguage = "es"
                        }
                        MenuItem {
                            text: "Japanese"
                            checkable: true
                            checked: UserSettings.preferredSubtitleLanguage === "ja"
                            onTriggered: UserSettings.preferredSubtitleLanguage = "ja"
                        }
                    }

                    MenuSeparator {}

                    MenuItem {
                        text: "Auto-select Subtitles"
                        checkable: true
                        checked: UserSettings.autoSelectSubtitles
                        onTriggered: UserSettings.autoSelectSubtitles = !UserSettings.autoSelectSubtitles
                    }

                    MenuSeparator {}

                    MenuItem {
                        text: "Reset Preferences"
                        onTriggered: UserSettings.resetPreferences()
                    }
                }
            }
        }

        Label {
            id: fileLabel
            anchors.centerIn: parent
            anchors.rightMargin: 10
            text: {
                if (Common.currentMediaPath === "") return ""
                var fileName = Common.getFileName(Common.currentMediaPath)
                if (MediaController.playlistSize > 1) {
                    return fileName + " (" + (MediaController.currentIndex + 1) + "/" + MediaController.playlistSize + ")"
                }
                return fileName
            }
            width: Math.min(300, implicitWidth)
            elide: Text.ElideMiddle
            opacity: 0.5
        }
    }

    VolumeIndicator {
        z: 1001
        opacity: 0.0
        id: volumeIndicator
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        value: volumeSlider.value

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Timer {
            id: volumeHideTimer
            interval: 1500
            onTriggered: volumeIndicator.opacity = 0.0
        }

        function show() {
            opacity = 1.0
            volumeHideTimer.restart()
        }
    }

    ToolBar {
        id: fullscreenToolbar
        visible: window.visibility === Window.FullScreen && Common.currentMediaPath !== ""
        opacity: 1.0
        height: 45
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        z: 1000

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: window.showControls()
            onEntered: window.showControls()
            propagateComposedEvents: true
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        background: Rectangle {
            color: Universal.background
            opacity: 0.7
        }

        // Left side - Track buttons
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            ToolButton {
                height: 45
                width: 45
                icon.source: "qrc:/icons/file.svg"
                Universal.foreground: Universal.accent
                onClicked: fileDialog.open()
            }

            ToolButton {
                icon.source: "qrc:/icons/track.svg"
                visible: mediaPlayer.audioTracks.length > 1
                width: 45
                height: 45
                onClicked: audioTracksMenu.popup()
                onHoveredChanged: if (hovered) window.showControls()
            }

            ToolButton {
                icon.source: "qrc:/icons/subtitle.svg"
                visible: mediaPlayer.subtitleTracks.length > 0
                width: 45
                height: 45
                onClicked: subtitleTracksMenu.popup()
                onHoveredChanged: if (hovered) window.showControls()
            }
        }

        // Center - File info
        Column {
            anchors.centerIn: parent
            spacing: 2

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (Common.currentMediaPath === "") return ""
                    return Common.getFileName(Common.currentMediaPath)
                }
                color: "white"
                font.pointSize: 11
                font.bold: true
                width: Math.min(400, implicitWidth)
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (MediaController.playlistSize > 1) {
                        return (MediaController.currentIndex + 1) + " / " + MediaController.playlistSize
                    }
                    return ""
                }
                color: "white"
                font.pointSize: 9
                opacity: 0.8
                visible: text !== ""
            }
        }

        // Right side - Settings
        ToolButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/cog.svg"
            height: 45
            width: 45
            onClicked: settingsMenu.popup()
            onHoveredChanged: if (hovered) window.showControls()
        }
    }

    Rectangle {
        id: audioTrackOverlay
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 200
        height: 80
        color: Qt.rgba(0, 0, 0, 0.8)
        opacity: 0.0
        z: 1001

        Column {
            anchors.centerIn: parent
            spacing: 5

            Label {
                text: "Audio Track"
                color: "white"
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: {
                    var current = MediaController.activeAudioTrack
                    if (current >= 0 && current < mediaPlayer.audioTracks.length) {
                        var track = mediaPlayer.audioTracks[current]
                        if (track && track.stringValue) {
                            var language = track.stringValue(6) || ""
                            var title = track.stringValue(0) || ""
                            return title || language || "Track " + (current + 1)
                        }
                        return "Track " + (current + 1)
                    }
                    return "None"
                }
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Timer {
            id: audioTrackHideTimer
            interval: 2000
            onTriggered: audioTrackOverlay.opacity = 0.0
        }

        function show() {
            opacity = 1.0
            audioTrackHideTimer.restart()
        }
    }

    Rectangle {
        id: subtitleOverlay
        anchors.top: audioTrackOverlay.bottom
        anchors.right: parent.right
        anchors.margins: 20
        width: 200
        height: 80
        color: Qt.rgba(0, 0, 0, 0.8)
        opacity: 0.0
        z: 1001

        Column {
            anchors.centerIn: parent
            spacing: 5

            Label {
                text: "Subtitles"
                color: "white"
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: {
                    var current = MediaController.activeSubtitleTrack
                    if (current >= 0 && current < mediaPlayer.subtitleTracks.length) {
                        var track = mediaPlayer.subtitleTracks[current]
                        if (track && track.stringValue) {
                            var language = track.stringValue(6) || ""
                            var title = track.stringValue(0) || ""
                            return title || language || "Track " + (current + 1)
                        }
                        return "Track " + (current + 1)
                    }
                    return "Off"
                }
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Timer {
            id: subtitleHideTimer
            interval: 2000
            onTriggered: subtitleOverlay.opacity = 0.0
        }

        function show() {
            opacity = 1.0
            subtitleHideTimer.restart()
        }
    }

    Item {
        id: rewindOverlay
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: parent.width / 4
        width: 120
        height: 120
        z: 1000
        opacity: 0.0
        scale: 1.0

        Rectangle {
            anchors.fill: parent
            color: Universal.background
            opacity: 0.5
            radius: width
        }

        Column {
            anchors.centerIn: parent
            spacing: 5

            IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/icons/rewind.svg"
                sourceSize.width: 60
                sourceSize.height: 60
                color: Universal.foreground
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "-10s"
                color: Universal.foreground
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
            id: rewindHideTimer
            interval: 1500
            onTriggered: rewindOverlay.opacity = 0.0
        }

        function trigger() {
            if (forwardOverlay.opacity > 0) {
                forwardHideTimer.stop()
                forwardOverlay.opacity = 0.0
            }

            opacity = 1.0
            rewindHideTimer.restart()
        }
    }

    Item {
        id: forwardOverlay
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: parent.width / 4
        width: 120
        height: 120
        z: 1000
        opacity: 0.0
        scale: 1.0

        Rectangle {
            anchors.fill: parent
            color: Universal.background
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
                color: Universal.foreground
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "+10s"
                color: Universal.foreground
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

        function trigger() {
            if (rewindOverlay.opacity > 0) {
                rewindHideTimer.stop()
                rewindOverlay.opacity = 0.0
            }

            opacity = 1.0
            forwardHideTimer.restart()
        }
    }

    Item {
        id: overlay
        anchors.centerIn: parent
        width: 120
        height: 120
        z: 1000
        opacity: 0.0
        scale: 0.0

        Rectangle {
            anchors.fill: parent
            color: Universal.background
            opacity: 0.5
            radius: width
        }

        IconImage {
            anchors.fill: parent
            source: mediaPlayer.playbackState === MediaPlayer.PlayingState
                    ? "qrc:/icons/pause.svg"
                    : "qrc:/icons/play.svg"
            sourceSize.width: 80
            sourceSize.height: 80
            color: Universal.foreground
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

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: window.showControls()
            onEntered: window.showControls()
            onWheel: function(wheel) {
                var delta = wheel.angleDelta.y / 120
                var volumeStep = 0.05
                var newVolume = volumeSlider.value + (delta * volumeStep)

                if (newVolume > 1.0) {
                    newVolume = 1.0
                } else if (newVolume < 0.0) {
                    newVolume = 0.0
                }

                volumeSlider.value = newVolume
                volumeIndicator.show()
                window.showControls()
            }
        }

        VideoOutput {
            ContextMenu.menu: Menu {
                enter: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.95
                        to: 1.0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                exit: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 100
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 1.0
                        to: 0.95
                        duration: 100
                        easing.type: Easing.InQuad
                    }
                }
                MenuItem {
                    text: qsTr("Copy File Path")
                    enabled: Common.currentMediaPath !== ""
                    onTriggered: MediaController.copyFilePathToClipboard(Common.currentMediaPath)
                }
                MenuItem {
                    text: qsTr("Open in Explorer")
                    enabled: Common.currentMediaPath !== ""
                    onTriggered: MediaController.openInExplorer(Common.currentMediaPath)
                }
                MenuSeparator {}

                Menu {
                    title: "Audio Track"
                    enabled: mediaPlayer.audioTracks.length > 1

                    Repeater {
                        model: mediaPlayer.audioTracks.length
                        MenuItem {
                            required property int index

                            text: {
                                var track = mediaPlayer.audioTracks[index]
                                if (track && track.stringValue) {
                                    var language = track.stringValue(6) || ""
                                    var title = track.stringValue(0) || ""
                                    return title || language || ("Track " + (index + 1))
                                }
                                return "Track " + (index + 1)
                            }
                            checkable: true
                            checked: mediaPlayer.activeAudioTrack === index
                            onTriggered: mediaPlayer.activeAudioTrack = index
                        }
                    }
                }

                Menu {
                    title: "Subtitles"
                    enabled: mediaPlayer.subtitleTracks.length > 0

                    MenuItem {
                        text: "Off"
                        checkable: true
                        checked: mediaPlayer.activeSubtitleTrack === -1
                        onTriggered: mediaPlayer.activeSubtitleTrack = -1
                    }

                    MenuSeparator {}

                    Repeater {
                        model: mediaPlayer.subtitleTracks.length
                        MenuItem {
                            required property int index

                            text: {
                                var track = mediaPlayer.subtitleTracks[index]
                                if (track && track.stringValue) {
                                    var language = track.stringValue(6) || ""
                                    var title = track.stringValue(0) || ""
                                    return title || language || ("Track " + (index + 1))
                                }
                                return "Track " + (index + 1)
                            }
                            checkable: true
                            checked: mediaPlayer.activeSubtitleTrack === index
                            onTriggered: mediaPlayer.activeSubtitleTrack = index
                        }
                    }
                }

                MenuSeparator {}
                MenuItem {
                    text: window.visibility === Window.FullScreen ? qsTr("Exit Fullscreen") : qsTr("Enter Fullscreen")
                    onTriggered: window.toggleFullscreen()
                }
            }
            id: videoOutput
            anchors.fill: parent
            visible: Common.isVideo && Common.currentMediaPath !== ""
            fillMode: VideoOutput.PreserveAspectFit

            property bool waitingForDoubleClick: false

            Timer {
                id: singleClickTimer
                interval: 250
                onTriggered: {
                    mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                        mediaPlayer.pause() : mediaPlayer.play()
                    overlay.trigger()
                    videoOutput.waitingForDoubleClick = false
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    if (!videoOutput.waitingForDoubleClick) {
                        videoOutput.waitingForDoubleClick = true
                        singleClickTimer.start()
                    }
                }
                onDoubleTapped: {
                    singleClickTimer.stop()
                    videoOutput.waitingForDoubleClick = false
                    window.toggleFullscreen()
                }
                enabled: Common.currentMediaPath !== ""
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Universal.background
            visible: !Common.isVideo && Common.currentMediaPath !== ""

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 15
                spacing: 20

                Rectangle {
                    width: 200
                    height: 200
                    color: Universal.baseLowColor

                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: MediaController.currentCoverArtUrl
                        visible: source !== "" && status === Image.Ready

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Universal.baseLowColor
                            border.width: 2
                            visible: parent.visible
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        source: "qrc:/icons/music.svg"
                        sourceSize.width: 64
                        sourceSize.height: 64
                        color: Universal.foreground
                        visible: MediaController.currentCoverArtUrl === "" || albumArtImage.status === Image.Error || albumArtImage.status === Image.Null
                    }
                }

                Label {
                    text: MediaController.currentTitle || Common.getFileName(Common.currentMediaPath)
                    font.pointSize: 18
                    font.bold: true
                    width: Math.min(400, implicitWidth)
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: MediaController.currentArtist || ""
                    font.pointSize: 14
                    opacity: 0.8
                    visible: text !== ""
                    width: Math.min(350, implicitWidth)
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: MediaController.currentAlbum || ""
                    font.pointSize: 12
                    opacity: 0.6
                    visible: text !== ""
                    width: Math.min(300, implicitWidth)
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: MediaController.formatDuration(mediaPlayer.duration)
                    opacity: 0.7
                }

                Label {
                    text: MediaController.playlistSize > 1 ?
                              (MediaController.currentIndex + 1) + " of " + MediaController.playlistSize : ""
                    opacity: 0.5
                    font.pointSize: 12
                }

                Column {
                    spacing: 5
                    visible: mediaPlayer.audioTracks.length > 1 || mediaPlayer.subtitleTracks.length > 0

                    Label {
                        text: mediaPlayer.audioTracks.length > 1 ?
                                  "Audio: " + (mediaPlayer.activeAudioTrack + 1) + " of " + mediaPlayer.audioTracks.length : ""
                        opacity: 0.5
                        font.pointSize: 10
                        visible: text !== ""
                    }

                    Label {
                        text: mediaPlayer.subtitleTracks.length > 0 ?
                                  "Subtitles: " + (mediaPlayer.activeSubtitleTrack >= 0 ?
                                                       (mediaPlayer.activeSubtitleTrack + 1) + " of " + mediaPlayer.subtitleTracks.length : "Off") : ""
                        opacity: 0.5
                        font.pointSize: 10
                        visible: text !== ""
                    }
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: "Load a media file to get started"
            opacity: 0.7
            visible: Common.currentMediaPath === ""
            font.pointSize: 16
        }

        DropArea {
            id: dropArea
            anchors.fill: parent

            onEntered: function(drag) {
                if (drag.hasUrls) {
                    var supportedFormats = [".mp4", ".avi", ".mov", ".mkv", ".webm", ".wmv", ".m4v", ".flv",
                                            ".mp3", ".wav", ".flac", ".ogg", ".aac", ".wma", ".m4a"]
                    var hasMediaFile = false

                    for (var i = 0; i < drag.urls.length; i++) {
                        var url = drag.urls[i].toString().toLowerCase()
                        for (var j = 0; j < supportedFormats.length; j++) {
                            if (url.includes(supportedFormats[j])) {
                                hasMediaFile = true
                                break
                            }
                        }
                        if (hasMediaFile) break
                    }

                    if (hasMediaFile) {
                        drag.accept(Qt.CopyAction)
                    } else {
                        drag.accepted = false
                    }
                }
            }

            onDropped: function(drop) {
                if (drop.hasUrls && drop.urls.length > 0) {
                    var supportedFormats = [".mp4", ".avi", ".mov", ".mkv", ".webm", ".wmv", ".m4v", ".flv",
                                            ".mp3", ".wav", ".flac", ".ogg", ".aac", ".wma", ".m4a"]

                    for (var i = 0; i < drop.urls.length; i++) {
                        var url = drop.urls[i].toString().toLowerCase()
                        for (var j = 0; j < supportedFormats.length; j++) {
                            if (url.includes(supportedFormats[j])) {
                                Common.loadMedia(drop.urls[i])
                                mediaPlayer.source = drop.urls[i]
                                drop.accept(Qt.CopyAction)
                                return
                            }
                        }
                    }
                }
                drop.accepted = false
            }
        }
    }

    Dialog {
        id: continuePlayingDialog
        title: "Continue Playing?"
        anchors.centerIn: parent
        modal: true

        onAboutToShow: {
            window.showControls()
            hideTimer.stop()
        }

        onAccepted: {
            window.playNext()
        }

        onClosed: {
            if (window.visibility === Window.FullScreen) {
                hideTimer.restart()
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "Yes"
                highlighted: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: continuePlayingDialog.accept()
            }
            Button {
                text: "No"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: continuePlayingDialog.reject()
            }
        }
    }

    ToolBar {
        id: controlsToolbar
        visible: Common.currentMediaPath !== ""
        opacity: 1.0
        height: 120
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: window.showControls()
            onEntered: window.showControls()
            propagateComposedEvents: true
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
            }
        }

        background: Rectangle {
            color: Universal.background
            opacity: 0.7
        }

        Slider {
            id: progressSlider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            from: 0
            to: Math.max(mediaPlayer.duration, 1)
            value: mediaPlayer.position
            enabled: mediaPlayer.seekable && mediaPlayer.duration > 0
            property bool wasPlaying: false

            onPressedChanged: {
                window.showControls()

                if (pressed) {
                    hideTimer.stop()

                    if (mediaPlayer.playing) {
                        mediaPlayer.pause()
                        wasPlaying = true
                    } else {
                        wasPlaying = false
                    }
                } else {
                    hideTimer.restart()

                    if (mediaPlayer.duration > 0) {
                        mediaPlayer.setPosition(value)
                        if (wasPlaying) {
                            mediaPlayer.play()
                        } else {
                            mediaPlayer.pause()
                        }
                    }
                }
            }

            ToolTip {
                visible: progressSlider.pressed
                text: MediaController.formatDuration(progressSlider.value) + " / " + MediaController.formatDuration(mediaPlayer.duration)
                x: progressSlider.handle.x + progressSlider.handle.width / 2 - width / 2
                y: progressSlider.handle.y - height - 10

                enter: Transition {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 100; easing.type: Easing.InQuad }
                }

                exit: Transition {
                    NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100; easing.type: Easing.OutQuad }
                }
            }

            Binding {
                target: progressSlider
                property: "value"
                value: mediaPlayer.position
                when: !progressSlider.pressed && mediaPlayer.duration > 0
            }
        }

        Row {
            id: timeRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15
            anchors.verticalCenterOffset: 20
            spacing: 8

            Label {
                text: MediaController.formatDuration(mediaPlayer.position)
                opacity: 0.7
                font.pointSize: 10
            }

            Label {
                text: "/"
                opacity: 0.5
                font.pointSize: 10
            }

            Label {
                text: MediaController.formatDuration(mediaPlayer.duration)
                opacity: 0.7
                font.pointSize: 10
            }
        }

        ToolButton {
            id: sleepButton
            anchors.left: timeRow.right
            anchors.leftMargin: 10
            anchors.verticalCenter: timeRow.verticalCenter
            icon.source: "qrc:/icons/sleep.svg"
            width: 32
            height: 32
            checkable: true
            onClicked: window.showControls()
            onHoveredChanged: if (hovered) window.showControls()
            ToolTip.visible: hovered
            ToolTip.text: checked ? "Sleep mode: ON (will ask before playing next)" : "Sleep mode: OFF"
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            spacing: 6

            ToolButton {
                icon.source: "qrc:/icons/prev.svg"
                width: 48
                height: 48
                enabled: MediaController.hasPrevious || mediaPlayer.position > 5000
                onClicked: {
                    window.showControls()
                    window.playPrevious()
                }
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: {
                    if (mediaPlayer.position > 5000) {
                        return "Restart"
                    } else if (MediaController.hasPrevious) {
                        return "Previous"
                    } else {
                        return "Restart"
                    }
                }
            }

            ToolButton {
                icon.source: "qrc:/icons/rewind.svg"
                width: 48
                height: 48
                onClicked: {
                    window.showControls()
                    var newPosition = mediaPlayer.position - 10000
                    if (newPosition < 0) {
                        newPosition = 0
                    }
                    mediaPlayer.setPosition(newPosition)
                }
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: "Rewind 10 seconds"
            }

            ToolButton {
                icon.source: mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                                 "qrc:/icons/pause.svg" : "qrc:/icons/play.svg"
                width: 48
                height: 48
                onClicked: {
                    window.showControls()
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        mediaPlayer.pause()
                    } else {
                        mediaPlayer.play()
                    }
                    overlay.trigger()
                }
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
            }

            ToolButton {
                icon.source: "qrc:/icons/forward.svg"
                width: 48
                height: 48
                onClicked: {
                    window.showControls()
                    var newPosition = mediaPlayer.position + 10000
                    if (newPosition > mediaPlayer.duration) {
                        newPosition = mediaPlayer.duration
                    }
                    mediaPlayer.setPosition(newPosition)
                }
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: "Forward 10 seconds"
            }

            ToolButton {
                icon.source: "qrc:/icons/next.svg"
                width: 48
                height: 48
                enabled: MediaController.hasNext
                onClicked: {
                    window.showControls()
                    window.playNext()
                }
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: MediaController.hasNext ? "Next" : "Next (no more files)"
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 0
            anchors.verticalCenterOffset: 20
            spacing: 6

            ToolButton {
                id: muteButton
                icon.source: checked || volumeSlider.value === 0 ? "qrc:/icons/volume_mute.svg" : "qrc:/icons/volume.svg"
                checkable: true
                width: 48
                height: 48

                onClicked: window.showControls()
                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Unmute" : "Mute"
            }

            Slider {
                id: volumeSlider
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1
                value: 1

                onPressedChanged: {
                    if (pressed) {
                        window.showControls()
                        hideTimer.stop()
                    } else {
                        hideTimer.restart()
                    }
                }

                onHoveredChanged: if (hovered) window.showControls()
                ToolTip.visible: hovered
                ToolTip.text: "Volume: " + Math.round(value * 100) + "%"
            }

            ToolButton {
                icon.source: window.visibility === Window.FullScreen ? "qrc:/icons/fit.svg" : "qrc:/icons/fullscreen.svg"
                width: 48
                height: 48
                onClicked: {
                    window.showControls()
                    window.toggleFullscreen()
                }
                onHoveredChanged: if (hovered) window.showControls()
                enabled: Common.currentMediaPath !== ""
                ToolTip.visible: hovered
                ToolTip.text: window.visibility === Window.FullScreen ? "Exit fullscreen" : "Enter fullscreen"
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Open Media File"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Media files (*.mp4 *.avi *.mov *.mkv *.webm *.wmv *.m4v *.flv *.mp3 *.wav *.flac *.ogg *.aac *.wma *.m4a)",
            "Video files (*.mp4 *.avi *.mov *.mkv *.webm *.wmv *.m4v *.flv)",
            "Audio files (*.mp3 *.wav *.flac *.ogg *.aac *.wma *.m4a)",
            "All files (*)"
        ]

        onAccepted: {
            Common.loadMedia(selectedFile)
            mediaPlayer.source = selectedFile
        }
    }

    function toggleFullscreen() {
        if (window.visibility === Window.FullScreen) {
            window.showNormal()
            controlsToolbar.opacity = 1.0
            hideTimer.stop()
        } else {
            window.showFullScreen()
            showControls()
        }
    }
}
