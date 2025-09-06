import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Controls.impl
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import Odizinne.MediaPlayer

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    minimumWidth: 800
    minimumHeight: 600
    title: "MediaPlayer"
    Universal.theme: Universal.System
    Universal.accent: palette.highlight

    // Audio device tracking
    property var currentAudioOutput: null

    Component.onDestruction: {
        MediaController.setPreventSleep(false)
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
            if (audioOutput) {
                audioOutput.device = device
            }
        }
    }

    function playNext() {
        var nextFile = MediaController.getNextFile()
        console.log("Next file:", nextFile, "Has next:", MediaController.hasNext)
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
        MediaController.setCursorState(MediaController.Normal)
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: {
            controlsToolbar.opacity = 0.0
            MediaController.setCursorState(MediaController.Hidden)
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
            volumeIndicator.show() // Add this line
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
            volumeIndicator.show() // Add this line
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: window.visibility === Window.FullScreen
        onActivated: window.toggleFullscreen()
    }

    Shortcut {
        sequence: "F11"
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
            forwardOverlay.trigger() // Add this line
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
            rewindOverlay.trigger() // Add this line
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
        audioOutput: AudioOutput {
            id: audioOutput
            volume: volumeSlider.value
            muted: muteButton.checked
            device: window.currentAudioOutput
        }
        videoOutput: Common.isVideo ? videoOutput : null

        onPlaybackStateChanged: {
            MediaController.setPreventSleep(playbackState === MediaPlayer.PlayingState)
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

                console.log("Loaded media. Playlist size:", MediaController.playlistSize,
                            "Current index:", MediaController.currentIndex,
                            "Has next:", MediaController.hasNext,
                            "Has previous:", MediaController.hasPrevious)
                MediaController.debugPlaylist()
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.log("Error loading media:", Common.currentMediaPath)
                window.title = "MediaPlayer - Error loading media"
                MediaController.setPreventSleep(false)
            } else if (mediaStatus === MediaPlayer.EndOfMedia && MediaController.hasNext) {
                window.playNext()
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                // No next file, disable sleep prevention
                MediaController.setPreventSleep(false)
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

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
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

    // Rewind overlay
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
            // Hide the forward overlay if it's visible
            if (forwardOverlay.opacity > 0) {
                forwardHideTimer.stop()
                forwardOverlay.opacity = 0.0
            }

            opacity = 1.0
            rewindHideTimer.restart()
        }
    }

    // Forward overlay
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
            // Hide the rewind overlay if it's visible
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
        }

        VideoOutput {
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
                    // Stop the hide timer while dragging
                    hideTimer.stop()

                    if (mediaPlayer.playing) {
                        mediaPlayer.pause()
                        wasPlaying = true
                    } else {
                        wasPlaying = false
                    }
                } else {
                    // Resume hide timer when done dragging
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

        // Time labels row (left side)
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 15
            anchors.verticalCenterOffset: 20  // Changed from 10 to 20 (more toward bottom)
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

        // Media control buttons row (centered)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 20  // Changed from 10 to 20 (more toward bottom)
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
                        // Stop the hide timer while dragging volume
                        hideTimer.stop()
                    } else {
                        // Resume hide timer when done dragging
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
