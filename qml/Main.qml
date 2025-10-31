pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.FluentWinUI3
import QtQuick.Controls.impl
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia
import Odizinne.MediaPlayer

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 720 + 40
    minimumWidth: 1280
    minimumHeight: 720 + 40
    title: "MediaPlayer"

    property bool anyMenuOpen: audioTracksMenu.opened || subtitleTracksMenu.opened || settingsDialog.visible || contextMenu.opened || aboutDialog.visible
    property var currentAudioOutput: null

    PictureInPictureWindow {
        id: pipWindow
        isPlaying: mediaPlayer.playbackState === MediaPlayer.PlayingState
        videoWidth: videoOutput ? videoOutput.videoSink.videoSize.width : 0
        videoHeight: videoOutput ? videoOutput.videoSink.videoSize.height : 0
    }

    Connections {
        target: fullscreenOverlay
        function onRequestShowFullScreen() {
            window.showFullScreen()
            window.showControls()
        }

        function onRequestShowNormal() {
            window.showNormal()
            controlsToolbar.opacity = 1.0
            hideTimer.stop()
        }
    }

    FullscreenTransitionOverlay {
        id: fullscreenOverlay
        mainWindowFullscreen: window.visibility === Window.FullScreen
    }

    function toggleFullscreen() {
        if (Common.isTransitioningToFullscreen) {
            return
        }

        Common.isTransitioningToFullscreen = true
        fullscreenOverlay.visible = true
        fullscreenOverlay.startAnimation()
    }

    onAnyMenuOpenChanged: {
        if (!anyMenuOpen) {
            menuClosedRecentlyTimer.restart()
        }
    }

    Connections {
        target: MediaController
        function onTrackSelectionRequested(audioLanguage, subtitleLanguage, autoSelectSubtitles) {
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

        function onSystemResumed() {
            Qt.callLater(window.performAudioRecovery)
        }

        function onFileReceivedFromAnotherInstance(filePath) {
            // Bring window to foreground
            window.raise()
            window.requestActivate()

            // Load the received file
            Qt.callLater(() => {
                // Convert local file path to file:// URL if needed
                var sourceUrl = filePath.startsWith("file://") ? filePath : "file:///" + filePath.replace(/\\/g, "/")
                Common.loadMedia(sourceUrl)
                mediaPlayer.source = sourceUrl
            })
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

    Connections {
        target: pipWindow
        function onExitPIP() {
            window.togglePictureInPicture()
        }

        function onTogglePlayback() {
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                mediaPlayer.pause()
            } else {
                mediaPlayer.play()
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
                volume: Common.mediaVolume
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
            mediaPlayer.stop()
            mediaPlayer.source = ""
            Qt.callLater(() => {
                Common.loadMedia(nextFile)
                mediaPlayer.source = nextFile
            })
        }
    }

    function playPrevious() {
        if (mediaPlayer.position > 5000) {
            mediaPlayer.setPosition(0)
        } else {
            var previousFile = MediaController.getPreviousFile()
            if (previousFile !== "") {
                mediaPlayer.stop()
                mediaPlayer.source = ""
                Qt.callLater(() => {
                    Common.loadMedia(previousFile)
                    mediaPlayer.source = previousFile
                })
            } else {
                mediaPlayer.setPosition(0)
            }
        }
    }

    function togglePictureInPicture() {
        if (Common.isPIP) {
            Common.isPIP = false
            videoOutput.parent = container
            width = 1280
            height = 720 + 40
            showNormal()
            hideTimer.restart()
            pipWindow.hidePIPWindow()
        } else {
            Common.isPIP = true
            sleepButton.checked = false
            videoOutput.parent = pipWindow.videoContainer
            close()
            hideTimer.stop()
            pipWindow.showPIPWindow()
            let wasPlaying = mediaPlayer.playbackState === MediaPlayer.PlayingState
            if (!wasPlaying) {
                mediaPlayer.play()
                Qt.callLater(() => {
                    if (!wasPlaying) {
                        mediaPlayer.pause()
                    }
                })
            }
        }
    }

    function showControls() {
        if (Common.toolbarsAnimating) return
        Common.controlsVisible = true
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
            if (!Common.isVideo) {
                return
            }
            if (window.anyMenuOpen || Common.mouseOverControls) {
                hideTimer.restart()
                return
            }
            Common.controlsVisible = false
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
            var newVolume = Common.mediaVolume + 0.05
            if (newVolume > 1.0) {
                newVolume = 1.0
            }
            Common.mediaVolume = newVolume
            volumeIndicator.show()
        }
    }

    Shortcut {
        sequence: "Down"
        onActivated: {
            var newVolume = Common.mediaVolume - 0.05
            if (newVolume < 0.0) {
                newVolume = 0.0
            }
            Common.mediaVolume = newVolume
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
        enabled: Common.currentMediaPath !== "" && Common.isVideo
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequences: [StandardKey.Open]
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
        audioOutput: playbackState === MediaPlayer.PlayingState ? (audioOutputLoader.item as AudioOutput) : null
        videoOutput: Common.isVideo ? videoOutput : null

        onPlaybackStateChanged: {
            MediaController.setPreventSleep(playbackState === MediaPlayer.PlayingState)
        }

        onTracksChanged: {
            MediaController.updateTracks(audioTracks, subtitleTracks, activeAudioTrack, activeSubtitleTrack)

            if (audioTracks.length > 0 || subtitleTracks.length > 0) {
                selectTracksWithPreferences(UserSettings.preferredAudioLanguage, UserSettings.preferredSubtitleLanguage, UserSettings.autoSelectSubtitles)
            }
        }

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                if (Common.isVideo) {
                    if (mediaPlayer.hasVideo && videoOutput.sourceRect.width > 0) {
                        Common.mediaWidth = videoOutput.sourceRect.width
                        Common.mediaHeight = videoOutput.sourceRect.height
                        Qt.callLater(() => mediaPlayer.play())
                    } else {
                        Qt.callLater(() => {
                            if (mediaPlayer.hasVideo) {
                                mediaPlayer.play()
                            }
                        })
                    }
                } else {
                    mediaPlayer.play()
                }
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

        function selectTracksWithPreferences(audioLanguage, subtitleLanguage, autoSelectSubtitles) {
            if (audioTracks.length > 1) {
                var preferredAudioIndex = findTrackByLanguage(audioTracks, audioLanguage)
                if (preferredAudioIndex >= 0) {
                    activeAudioTrack = preferredAudioIndex
                }
            }

            if (autoSelectSubtitles && subtitleTracks.length > 0) {
                var preferredSubtitleIndex = findTrackByLanguage(subtitleTracks, subtitleLanguage)
                if (preferredSubtitleIndex >= 0) {
                    activeSubtitleTrack = preferredSubtitleIndex
                }
            }
        }

        function findTrackByLanguage(tracks, preferredLang) {
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
            for (var i = 0; i < tracks.length; i++) {
                var track = tracks[i]
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
                        for (var j = 0; j < searchTerms.length; j++) {
                            var term = searchTerms[j]
                            if (language && language === term) {
                                return i
                            }
                            if (title && title.indexOf(term) >= 0) {
                                return i
                            }
                        }
                    } catch (e) {
                        console.log("Error accessing track", i, "metadata:", e)
                    }
                }
            }
            return -1
        }

        onErrorOccurred: function(error, errorString) {
            console.log("Media error:", errorString)
        }
    }

    header: ToolBar {
        height: 40
        visible: window.visibility !== Window.FullScreen
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        topInset: 0
        leftInset: 0
        rightInset: 0
        bottomInset: 0

        NFToolButton {
            id: openButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            icon.source: "qrc:/icons/file.svg"
            icon.color: palette.accent
            text: "Open media"
            onClicked: fileDialog.open()
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 40

            NFToolButton {
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

                    ButtonGroup {
                        id: audioButtonGroup
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
                            checked: mediaPlayer.activeAudioTrack === index
                            ButtonGroup.group: audioButtonGroup
                            onTriggered: {
                                mediaPlayer.activeAudioTrack = index
                                trackOverlay.show(true)
                            }
                        }
                    }
                }
            }

            NFToolButton {
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

                    ButtonGroup {
                        id: subtitleButtonGroup
                    }

                    MenuItem {
                        text: "Off"
                        checkable: true
                        checked: mediaPlayer.activeSubtitleTrack === -1
                        ButtonGroup.group: subtitleButtonGroup
                        onTriggered: {
                            mediaPlayer.activeSubtitleTrack = -1
                            trackOverlay.show(false)
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
                            checked: mediaPlayer.activeSubtitleTrack === index
                            ButtonGroup.group: subtitleButtonGroup
                            onTriggered: {
                                mediaPlayer.activeSubtitleTrack = index
                                trackOverlay.show(false)
                            }
                        }
                    }
                }
            }

            NFToolButton {
                id: settingsButton
                Layout.preferredHeight: 40
                icon.source: "qrc:/icons/cog.svg"
                text: "Settings"

                onClicked: settingsDialog.open()
            }

            NFToolButton {
                Layout.preferredHeight: 40
                icon.source: "qrc:/icons/info.svg"
                onClicked: aboutDialog.open()
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

    AboutDialog {
        id: aboutDialog
        anchors.centerIn: parent
    }

    SettingsDialog {
        id: settingsDialog
        anchors.centerIn: parent
    }

    ContinuePlayingDialog {
        id: continuePlayingDialog
        anchors.centerIn: parent
        onAccepted: {
            window.playNext()
        }
    }

    VolumeIndicator {
        z: 1001
        visible: Common.currentMediaPath !== ""
        id: volumeIndicator
        y: controlsToolbar.y - height - 20
        x: (parent.width - width) / 2
        value: Common.mediaVolume
    }

    ToolBar {
        id: fullscreenToolbar
        visible: window.visibility === Window.FullScreen && Common.currentMediaPath !== ""
        opacity: Common.controlsVisible ? 1.0 : 0.0
        height: 45
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Common.controlsVisible ? (UserSettings.floatingUi ? 20 : 0) : -height
        anchors.rightMargin: UserSettings.floatingUi ? 20 : 0
        anchors.leftMargin: UserSettings.floatingUi ? 20 : 0
        anchors.bottomMargin: UserSettings.floatingUi ? 20 : 0

        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        topInset: 0
        leftInset: 0
        rightInset: 0
        bottomInset: 0
        z: 1000

        HoverHandler {
            id: fullscreenToolbarHover
            enabled: !Common.toolbarsAnimating
            onHoveredChanged: {
                if (hovered) {
                    Common.mouseOverControls = true
                } else {
                    Common.mouseOverControls = false
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        hideTimer.restart()
                    }
                }
            }

            onPointChanged: {
                if (hovered) {
                    Common.mouseOverControls = true
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
                onRunningChanged: Common.toolbarsAnimating = running
            }
        }

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
                onRunningChanged: Common.toolbarsAnimating = running
            }
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        background: Rectangle {
            color: palette.window
            radius: UserSettings.floatingUi ? 8 : 0
            opacity: UserSettings.uiOpacity
        }

        // Left side - Track buttons
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            NFToolButton {
                height: 45
                width: 45
                icon.source: "qrc:/icons/file.svg"
                icon.color: palette.accent
                onClicked: fileDialog.open()
            }

            NFToolButton {
                icon.source: "qrc:/icons/track.svg"
                visible: mediaPlayer.audioTracks.length > 1
                width: 45
                height: 45
                onClicked: audioTracksMenu.popup()
            }

            NFToolButton {
                icon.source: "qrc:/icons/subtitle.svg"
                visible: mediaPlayer.subtitleTracks.length > 0
                width: 45
                height: 45
                onClicked: subtitleTracksMenu.popup()
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
                font.pointSize: 9
                opacity: 0.8
                visible: text !== ""
            }
        }

        Row {
            anchors.right: settingsToolButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 5
            spacing: 5

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/icons/clock.svg"
                sourceSize.width: 14
                sourceSize.height: 14
                color: palette.windowText

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 1.0
                        to: 0.5
                        duration: 1000
                    }

                    NumberAnimation {
                        from: 0.5
                        to: 1.0
                        duration: 1000
                    }
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: palette.windowText
                text: Common.currentTime
                font.pointSize: 11
                opacity: 0.7
            }
        }

        NFToolButton {
            id: settingsToolButton
            anchors.right: aboutBtn.left
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/cog.svg"
            height: 45
            width: 45
            onClicked: settingsDialog.open()
        }

        NFToolButton {
            id: aboutBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 45
            width: 45
            icon.source: "qrc:/icons/info.svg"
            onClicked: aboutDialog.open()
        }
    }

    Rectangle {
        id: trackOverlay
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 200
        height: 80
        color: Qt.rgba(0, 0, 0, 0.8)
        opacity: 0.0
        radius: 5
        z: 1001

        property string trackType: ""
        property string trackText: ""

        Column {
            anchors.centerIn: parent
            spacing: 5

            Label {
                text: trackOverlay.trackType
                color: "white"
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: trackOverlay.trackText
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        Timer {
            id: trackHideTimer
            interval: 2000
            onTriggered: trackOverlay.opacity = 0.0
        }

        function show(audio) {
            if (audio) {
                trackType = "Audio Track"
                var current = mediaPlayer.activeAudioTrack
                if (current >= 0 && current < mediaPlayer.audioTracks.length) {
                    var track = mediaPlayer.audioTracks[current]
                    if (track && track.stringValue) {
                        var language = track.stringValue(6) || ""
                        var title = track.stringValue(0) || ""
                        trackText = title || language || "Track " + (current + 1)
                    } else {
                        trackText = "Track " + (current + 1)
                    }
                } else {
                    trackText = "None"
                }
            } else {
                trackType = "Subtitles"
                var current = mediaPlayer.activeSubtitleTrack
                if (current >= 0 && current < mediaPlayer.subtitleTracks.length) {
                    var track = mediaPlayer.subtitleTracks[current]
                    if (track && track.stringValue) {
                        var language = track.stringValue(6) || ""
                        var title = track.stringValue(0) || ""
                        trackText = title || language || "Track " + (current + 1)
                    } else {
                        trackText = "Track " + (current + 1)
                    }
                } else {
                    trackText = "Off"
                }
            }

            opacity = 1.0
            trackHideTimer.restart()
        }
    }

    ForwardOverlay {
        id: forwardOverlay
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: parent.width / 4
        Connections {
            target: rewindOverlay
            function onTriggered() {
                forwardOverlay.hide()
            }
        }
    }

    RewindOverlay {
        id: rewindOverlay
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: parent.width / 4
        Connections {
            target: forwardOverlay
            function onTriggered() {
                rewindOverlay.hide()
            }
        }
    }

    PlaybackOverlay {
        id: overlay
        anchors.centerIn: parent
        source: mediaPlayer.playbackState === MediaPlayer.PlayingState
                ? "qrc:/icons/pause.svg"
                : "qrc:/icons/play.svg"
    }

    Timer {
        id: menuClosedRecentlyTimer
        interval: 200
        onTriggered: {}
    }

    Item {
        id: container
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: Common.isVideo && Common.currentMediaPath !== ""
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: Common.currentMediaPath !== ""
            acceptedButtons: Qt.NoButton
            onPositionChanged: window.showControls()
            onEntered: window.showControls()
            onWheel: function(wheel) {
                var delta = wheel.angleDelta.y / 120
                var volumeStep = 0.05
                var newVolume = Common.mediaVolume + (delta * volumeStep)

                if (newVolume > 1.0) {
                    newVolume = 1.0
                } else if (newVolume < 0.0) {
                    newVolume = 0.0
                }

                Common.mediaVolume = newVolume
                volumeIndicator.show()
                window.showControls()
            }
        }

        VideoOutput {
            ContextMenu.menu: Menu {
                id: contextMenu
                enabled: !Common.isPIP

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

                    ButtonGroup {
                        id: contextAudioButtonGroup
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
                            checked: mediaPlayer.activeAudioTrack === index
                            ButtonGroup.group: contextAudioButtonGroup
                            onTriggered: {
                                mediaPlayer.activeAudioTrack = index
                            }
                        }
                    }
                }

                Menu {
                    title: "Subtitles"
                    enabled: mediaPlayer.subtitleTracks.length > 0

                    ButtonGroup {
                        id: contextSubtitleButtonGroup
                    }

                    MenuItem {
                        text: "Off"
                        checkable: true
                        checked: mediaPlayer.activeSubtitleTrack === -1
                        ButtonGroup.group: contextSubtitleButtonGroup
                        onTriggered: {
                            mediaPlayer.activeSubtitleTrack = -1
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
                            checked: mediaPlayer.activeSubtitleTrack === index
                            ButtonGroup.group: contextSubtitleButtonGroup
                            onTriggered: {
                                mediaPlayer.activeSubtitleTrack = index
                            }
                        }
                    }
                }

                MenuSeparator {}
                MenuItem {
                    text: window.visibility === Window.FullScreen ? qsTr("Exit Fullscreen") : qsTr("Enter Fullscreen")
                    enabled: Common.currentMediaPath !== "" && Common.isVideo
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
                    if (menuClosedRecentlyTimer.running) return
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
            color: window.color
            visible: !Common.isVideo && Common.currentMediaPath !== ""

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 15
                spacing: 20

                Rectangle {
                    width: 200
                    height: 200
                    color: palette.base
                    radius: 8

                    Image {
                        id: albumArtImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: MediaController.currentCoverArtUrl
                        visible: source !== "" && status === Image.Ready

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: palette.base
                            border.width: 2
                            visible: parent.visible
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        source: "qrc:/icons/music.svg"
                        sourceSize.width: 64
                        sourceSize.height: 64
                        color: palette.windowText
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

    TextMetrics {
        id: timelineFontMetrics
        font.pointSize: 11
        text: "88:88:88"
    }

    ToolBar {
        id: controlsToolbar
        visible: Common.currentMediaPath !== ""
        opacity: Common.controlsVisible ? 1.0 : 0.0
        height: 120
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Common.controlsVisible ? (UserSettings.floatingUi ? 20 : 0) : -height
        anchors.leftMargin: UserSettings.floatingUi ? 20 : 0
        anchors.rightMargin: UserSettings.floatingUi ? 20 : 0

        HoverHandler {
            id: controlsToolbarHover
            enabled: !Common.toolbarsAnimating
            onHoveredChanged: {
                if (hovered) {
                    Common.mouseOverControls = true
                } else {
                    Common.mouseOverControls = false
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        hideTimer.restart()
                    }
                }
            }

            onPointChanged: {
                if (hovered) {
                    Common.mouseOverControls = true
                }
            }
        }

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
                onRunningChanged: Common.toolbarsAnimating = running
            }
        }

        Behavior on anchors.rightMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
                onRunningChanged: Common.toolbarsAnimating = running
            }
        }

        background: Rectangle {
            color: Common.isVideo ? palette.window : palette.base
            radius: UserSettings.floatingUi ? 8 : 0
            opacity: Common.isVideo ? UserSettings.uiOpacity : 1.0
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            Label {
                id: currentTimeLabel
                text: MediaController.formatDuration(mediaPlayer.position)
                opacity: 0.7
                font.pointSize: 11
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: timelineFontMetrics.width
                horizontalAlignment: Text.AlignRight
            }

            NFSlider {
                id: progressSlider

                from: 0
                to: Math.max(mediaPlayer.duration, 1)
                value: mediaPlayer.position
                enabled: mediaPlayer.seekable && mediaPlayer.duration > 0
                property bool wasPlaying: false
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                onPressedChanged: {
                    if (pressed) {
                        if (mediaPlayer.playing) {
                            mediaPlayer.pause()
                            wasPlaying = true
                        } else {
                            wasPlaying = false
                        }
                    } else {
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
                }

                Binding {
                    target: progressSlider
                    property: "value"
                    value: mediaPlayer.position
                    when: !progressSlider.pressed && mediaPlayer.duration > 0
                }
            }

            Label {
                id: totalTimeLabel
                text: MediaController.formatDuration(mediaPlayer.duration)
                opacity: 0.7
                font.pointSize: 11
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: timelineFontMetrics.width
                horizontalAlignment: Text.AlignLeft
            }
        }

        NFToolButton {
            id: sleepButton
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            icon.source: "qrc:/icons/sleep.svg"
            width: 48
            height: 48
            checkable: true
            ToolTip.visible: hovered
            ToolTip.text: checked ? "Sleep mode: ON (will ask before playing next)" : "Sleep mode: OFF"
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20
            spacing: 6

            NFToolButton {
                icon.source: "qrc:/icons/prev.svg"
                width: 48
                height: 48
                enabled: MediaController.hasPrevious || mediaPlayer.position > 5000
                onClicked: {
                    window.playPrevious()
                }
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

            NFToolButton {
                icon.source: "qrc:/icons/rewind.svg"
                width: 48
                height: 48
                onClicked: {
                    var newPosition = mediaPlayer.position - 10000
                    if (newPosition < 0) {
                        newPosition = 0
                    }
                    mediaPlayer.setPosition(newPosition)
                    rewindOverlay.trigger()
                }
                ToolTip.visible: hovered
                ToolTip.text: "Rewind 10 seconds"
            }

            NFToolButton {
                icon.source: mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                                 "qrc:/icons/pause.svg" : "qrc:/icons/play.svg"
                width: 48
                height: 48
                onClicked: {
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        mediaPlayer.pause()
                    } else {
                        mediaPlayer.play()
                    }
                    overlay.trigger()
                }
                ToolTip.visible: hovered
                ToolTip.text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
            }

            NFToolButton {
                icon.source: "qrc:/icons/forward.svg"
                width: 48
                height: 48
                onClicked: {
                    var newPosition = mediaPlayer.position + 10000
                    if (newPosition > mediaPlayer.duration) {
                        newPosition = mediaPlayer.duration
                    }
                    mediaPlayer.setPosition(newPosition)
                    forwardOverlay.trigger()
                }
                ToolTip.visible: hovered
                ToolTip.text: "Forward 10 seconds"
            }

            NFToolButton {
                icon.source: "qrc:/icons/next.svg"
                width: 48
                height: 48
                enabled: MediaController.hasNext
                onClicked: {
                    window.playNext()
                }
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

            NFToolButton {
                id: muteButton
                icon.source: checked || Common.mediaVolume === 0 ? "qrc:/icons/volume_mute.svg" : "qrc:/icons/volume.svg"
                checkable: true
                width: 48
                height: 48
                ToolTip.visible: hovered
                ToolTip.text: checked ? "Unmute" : "Mute"
            }

            NFSlider {
                id: volumeSlider
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1
                value: Common.mediaVolume
                onValueChanged: Common.mediaVolume = value
                ToolTip.visible: hovered
                ToolTip.text: "Volume: " + Math.round(value * 100) + "%"
            }

            NFToolButton {
                id: togglePIPButton
                icon.source: "qrc:/icons/pip.svg"
                width: 48
                height: 48
                ToolTip.visible: hovered
                ToolTip.text: "Picture In Picture"
                onClicked: window.togglePictureInPicture()
            }

            NFToolButton {
                icon.source: window.visibility === Window.FullScreen ? "qrc:/icons/fit.svg" : "qrc:/icons/fullscreen.svg"
                width: 48
                height: 48
                onClicked: {
                    window.toggleFullscreen()
                }
                enabled: Common.currentMediaPath !== "" && Common.isVideo
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
}
