import QtQuick.Controls.FluentWinUI3
import QtQuick.Controls.impl
import QtQuick
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: pipWindow

    property real containerHeight: Screen.height / 6
    property real videoWidth: 16
    property real videoHeight: 9
    property real videoAspectRatio: videoWidth / videoHeight
    width: containerHeight * videoAspectRatio + 50
    height: containerHeight + 50
    visible: false
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    transientParent: null
    color: "transparent"
    opacity: 0

    property bool isPlaying: false
    property real minContainerHeight: Screen.height / 6
    property real maxContainerHeight: Screen.height / 3
    property alias videoContainer: videoContainer

    signal exitPIP()
    signal togglePlayback()

    // Animations
    PropertyAnimation { id: showAnimation; target: pipWindow; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
    PropertyAnimation { id: hideAnimation; target: pipWindow; property: "opacity"; from: 1; to: 0; duration: 300; easing.type: Easing.OutCubic; onFinished: pipWindow.visible = false }

    function showPIPWindow() {
        y = 20
        x = Screen.width - width - 20
        visible = true
        showAnimation.start()
        scaleShowAnimation.start()
    }

    function hidePIPWindow() {
        hideAnimation.start()
        scaleHideAnimation.start()
    }

    Item {
        id: rootItem
        anchors.fill: parent
        anchors.margins: 25
        scale: 0.5

        PropertyAnimation { id: scaleShowAnimation; target: rootItem; property: "scale"; from: 0.5; to: 1; duration: 300; easing.type: Easing.OutCubic }
        PropertyAnimation { id: scaleHideAnimation; target: rootItem; property: "scale"; from: 1; to: 0.5; duration: 300; easing.type: Easing.OutCubic }

        DropShadow { anchors.fill: maskedContent; source: maskedContent; radius: 24; samples: 33; color: "#CC000000"; horizontalOffset: 0; verticalOffset: 4 }

        Item {
            id: maskedContent
            anchors.fill: parent

            Rectangle {
                id: contentRect
                anchors.fill: parent
                color: "black"
                visible: false

                Item {
                    id: videoContainer
                    width: pipWindow.containerHeight * pipWindow.videoAspectRatio
                    height: pipWindow.containerHeight
                    anchors.centerIn: parent
                }

                Item {
                    id: controlsOverlay
                    anchors.fill: parent
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.5 }

                    IconImage {
                        id: closePIP
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 10
                        anchors.rightMargin: 10
                        source: "qrc:/icons/close.svg"
                        width: 18 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        height: 18 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        opacity: 0.7
                        color: "white"
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }

                    Rectangle {
                        id: playPauseBG
                        anchors.centerIn: parent
                        color: palette.window
                        opacity: 0
                        radius: width/2
                        width: 80 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        height: 80 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }

                    IconImage {
                        id: playPause
                        anchors.centerIn: parent
                        source: pipWindow.isPlaying ? "qrc:/icons/pause.svg" : "qrc:/icons/play.svg"
                        width: 42 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        height: 42 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        opacity: 0.7
                        color: "white"
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }

                    IconImage {
                        id: resizeHandle
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.bottomMargin: 0
                        anchors.rightMargin: 0
                        width: 36 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        height: 36 * (pipWindow.containerHeight / pipWindow.minContainerHeight)
                        color: "white"
                        source: "qrc:/icons/resize.svg"
                    }
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: contentRect
                maskSource: Rectangle { width: contentRect.width; height: contentRect.height; radius: 8 }
            }
        }
    }

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        anchors.margins: 20
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.AllButtons

        property bool isResizing: false
        property real startContainerHeight
        property real pressX
        property real pressY
        property string pressedTarget: ""
        property bool hasMoved: false

        function isInCloseArea(x, y) {
            let scale = pipWindow.containerHeight / pipWindow.minContainerHeight
            return x >= width - 28*scale && x <= width - 10*scale &&
                   y >= 10*scale && y <= 28*scale
        }

        function isInPlayPauseArea(x, y) {
            let bx = playPauseBG.x
            let by = playPauseBG.y
            let bw = playPauseBG.width
            let bh = playPauseBG.height
            return x >= bx && x <= bx + bw &&
                   y >= by && y <= by + bh
        }

        function isInResizeArea(x, y) {
            let scale = pipWindow.containerHeight / pipWindow.minContainerHeight
            return x >= width - 36*scale && x <= width &&
                   y >= height - 36*scale && y <= height
        }

        onIsResizingChanged: { if (!isResizing) controlsOverlay.opacity = 0 }
        onEntered: controlsOverlay.opacity = 1
        onExited: controlsOverlay.opacity = 0

        onPressed: mouse => {
            pressX = mouse.x
            pressY = mouse.y
            hasMoved = false
            pressedTarget = ""

            if (isInResizeArea(mouse.x, mouse.y)) {
                isResizing = true
                startContainerHeight = pipWindow.containerHeight
            } else {
                if (isInCloseArea(mouse.x, mouse.y))
                    pressedTarget = "close"
                else if (isInPlayPauseArea(mouse.x, mouse.y))
                    pressedTarget = "playpause"
            }
        }

        onReleased: mouse => {
            if (isResizing) { isResizing = false; return }
            if (!hasMoved) {
                if (pressedTarget === "close") pipWindow.exitPIP()
                else if (pressedTarget === "playpause") pipWindow.togglePlayback()
            }
        }

        onPositionChanged: mouse => {
            if (!pressed) cursorShape = isInResizeArea(mouse.x, mouse.y) ? Qt.SizeFDiagCursor : Qt.ArrowCursor

            if (isResizing) {
                controlsOverlay.opacity = 1
                let deltaY = mouse.y - pressY
                let newContainerHeight = startContainerHeight + deltaY
                newContainerHeight = Math.max(pipWindow.minContainerHeight, Math.min(pipWindow.maxContainerHeight, newContainerHeight))
                pipWindow.containerHeight = newContainerHeight
                pipWindow.height = newContainerHeight + 40
                pipWindow.width = newContainerHeight * pipWindow.videoAspectRatio + 40
            } else {
                if (!hasMoved && (mouse.x !== pressX || mouse.y !== pressY) && !isInResizeArea(pressX, pressY)) {
                    hasMoved = true
                    pipWindow.startSystemMove()
                }
                controlsOverlay.opacity = 1
                closePIP.opacity = mouse.x >= closePIP.x && mouse.x <= closePIP.x + closePIP.width &&
                                   mouse.y >= closePIP.y && mouse.y <= closePIP.y + closePIP.height ? 1 : 0.7
                playPause.opacity = mouse.x >= playPauseBG.x && mouse.x <= playPauseBG.x + playPauseBG.width &&
                                    mouse.y >= playPauseBG.y && mouse.y <= playPauseBG.y + playPauseBG.height ? 1 : 0.7
                playPauseBG.opacity = playPause.opacity === 1 ? 0.7 : 0
            }
        }
    }
}
