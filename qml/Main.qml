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

    // Mouse tracking properties
    property bool mouseActive: true
    property int hideControlsDelay: 3000 // 3 seconds

    Timer {
        id: hideControlsTimer
        interval: window.hideControlsDelay
        onTriggered: {
            if (Common.currentMediaPath !== "" && window.visibility === Window.FullScreen) {
                window.mouseActive = false
            }
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


    Component.onCompleted: {
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
        }
        videoOutput: Common.isVideo ? videoOutput : null

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                if (Common.isVideo && videoOutput.sourceRect.width > 0) {
                    Common.mediaWidth = videoOutput.sourceRect.width
                    Common.mediaHeight = videoOutput.sourceRect.height
                }
                window.title = Common.getFileName(Common.currentMediaPath) + " - MediaPlayer"
                mediaPlayer.play()  // Auto-play when media is loaded
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.log("Error loading media:", Common.currentMediaPath)
                window.title = "MediaPlayer - Error loading media"
            }
        }

        //onPlaybackStateChanged: {
        //    // show overlay only when toggling play/pause, not on stop
        //    if (playbackState === MediaPlayer.PlayingState || playbackState === MediaPlayer.PausedState) {
        //        overlay.trigger()
        //    }
        //}

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
            text: Common.currentMediaPath !== "" ? Common.getFileName(Common.currentMediaPath) : ""
            width: Math.min(300, implicitWidth)
            elide: Text.ElideMiddle
            opacity: 0.5
        }
    }

    Item {
        id: overlay
        anchors.centerIn: parent
        width: 120
        height: 120
        z: 1000
        opacity: 0.0
        scale: 0.0   // start from zero

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

            // Continuous scale: 0 → 0.25 quickly, then 0.25 → 1
            SequentialAnimation {
                PropertyAnimation { target: overlay; property: "scale"; from: 0.0; to: 0.25; duration: 150; easing.type: Easing.OutBack }
                PropertyAnimation { target: overlay; property: "scale"; from: 0.25; to: 1.0; duration: 650; easing.type: Easing.OutCubic }
            }

            // Opacity: fade in while scale 0 → 0.25, then fade out while scale 0.25 → 1
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

            onPositionChanged: {
                window.mouseActive = true
                hideControlsTimer.restart()
            }

            onEntered: {
                window.mouseActive = true
                hideControlsTimer.restart()
            }
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

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        contextMenu.popup()
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Universal.background
            visible: !Common.isVideo && Common.currentMediaPath !== ""

            Column {
                anchors.centerIn: parent
                spacing: 20

                Rectangle {
                    width: 120
                    height: 120
                    color: Universal.accent
                    radius: 60
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pointSize: 48
                        color: "white"
                    }
                }

                Label {
                    text: Common.getFileName(Common.currentMediaPath)
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pointSize: 16
                    font.bold: true
                }

                Label {
                    text: MediaController.formatDuration(mediaPlayer.duration)
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.7
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

    Menu {
        id: contextMenu
        opacity: Common.currentMediaPath !== "" ? 1 : 0

        MenuItem {
            text: "Copy media path"
            enabled: Common.currentMediaPath !== ""
            onTriggered: MediaController.copyPathToClipboard(Common.currentMediaPath)
        }

        MenuSeparator {}

        MenuItem {
            text: "Restart"
            enabled: Common.currentMediaPath !== ""
            onTriggered: mediaPlayer.setPosition(0)
        }

        MenuItem {
            text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
            enabled: Common.currentMediaPath !== ""
            onTriggered: mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                             mediaPlayer.pause() : mediaPlayer.play()
        }
    }

    ToolBar {
        visible: Common.currentMediaPath !== ""
        opacity: (window.visibility !== Window.FullScreen) || window.mouseActive ? 1.0 : 0.0
        height: ctrlLyt.implicitHeight + 30
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        background: Rectangle {
            color: Universal.background
            opacity: 0.7
        }

        ColumnLayout {
            id: ctrlLyt
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // Media controls row
            RowLayout {
                Layout.fillWidth: true

                // Previous/Restart button
                ToolButton {
                    icon.source: "qrc:/icons/prev.svg"
                    Layout.preferredWidth: height
                    onClicked: mediaPlayer.setPosition(0)
                    ToolTip.visible: hovered
                    ToolTip.text: "Restart"
                }

                // Play/Pause button
                ToolButton {
                    icon.source: mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                                     "qrc:/icons/pause.svg" : "qrc:/icons/play.svg"
                    Layout.preferredWidth: height
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

                // Stop button
                ToolButton {
                    icon.source: "qrc:/icons/stop.svg"
                    Layout.preferredWidth: height
                    onClicked: mediaPlayer.stop()
                    ToolTip.visible: hovered
                    ToolTip.text: "Stop"
                }

                // Next button (placeholder - you can implement playlist logic later)
                ToolButton {
                    icon.source: "qrc:/icons/next.svg"
                    Layout.preferredWidth: height
                    enabled: false // Disable for now since there's no playlist
                    ToolTip.visible: hovered
                    ToolTip.text: "Next (coming soon)"
                }

                Item { Layout.fillWidth: true }

                // Time labels
                Label {
                    text: MediaController.formatDuration(mediaPlayer.position)
                    opacity: 0.7
                    font.pointSize: 9
                }

                Label {
                    text: "/"
                    opacity: 0.5
                    font.pointSize: 9
                }

                Label {
                    text: MediaController.formatDuration(mediaPlayer.duration)
                    opacity: 0.7
                    font.pointSize: 9
                }

                Item { Layout.fillWidth: true }

                // Audio controls
                ToolButton {
                    id: muteButton
                    icon.source: checked ? "qrc:/icons/volume_mute.svg" : "qrc:/icons/volume.svg"
                    checkable: true
                    Layout.preferredWidth: height
                    ToolTip.visible: hovered
                    ToolTip.text: checked ? "Unmute" : "Mute"
                }

                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 100
                    from: 0
                    to: 1
                    value: 1
                    ToolTip.visible: hovered
                    ToolTip.text: "Volume: " + Math.round(value * 100) + "%"
                }

                ToolButton {
                    icon.source: window.visibility === Window.FullScreen ? "qrc:/icons/fit.svg" : "qrc:/icons/fullscreen.svg"
                    Layout.preferredWidth: height
                    onClicked: window.toggleFullscreen()
                    enabled: Common.isVideo && Common.currentMediaPath !== ""
                    visible: Common.isVideo
                    ToolTip.visible: hovered
                    ToolTip.text: window.visibility === Window.FullScreen ? "Exit fullscreen" : "Enter fullscreen"
                }
            }

            Slider {
                id: progressSlider
                Layout.fillWidth: true
                from: 0
                to: Math.max(mediaPlayer.duration, 1)
                value: mediaPlayer.position
                enabled: mediaPlayer.seekable && mediaPlayer.duration > 0
                property bool wasPlaying: false
                onPressedChanged: {
                    if (pressed && mediaPlayer.playing) {
                        mediaPlayer.pause()
                        wasPlaying = true
                    } else if (pressed && !mediaPlayer.playing) {
                        wasPlaying = false
                    }

                    if (!pressed && mediaPlayer.duration > 0) {
                        mediaPlayer.setPosition(value)
                        if (wasPlaying) {
                            mediaPlayer.play()
                        } else {
                            mediaPlayer.pause()
                        }
                    }
                }

                Binding {
                    target: progressSlider
                    property: "value"
                    value: mediaPlayer.position
                    when: !progressSlider.pressed && mediaPlayer.duration > 0
                }
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
            mouseActive = true
            hideControlsTimer.stop()
        } else {
            window.showFullScreen()
            mouseActive = true
            hideControlsTimer.restart()
        }
    }
}
