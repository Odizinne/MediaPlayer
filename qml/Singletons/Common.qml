pragma Singleton

import QtQuick
import Odizinne.MediaPlayer

Item {
    property string currentMediaPath: ""
    property real mediaWidth: 0
    property real mediaHeight: 0
    property int mediaFileSize: 0
    property bool enableScaleAnimation: false
    property bool isVideo: false

    function loadMedia(mediaPath) {
        currentMediaPath = mediaPath
        mediaFileSize = MediaController.getFileSize(mediaPath)

        // Build playlist from the current file's directory
        MediaController.buildPlaylistFromFile(mediaPath)

        // Update current file in the playlist
        MediaController.setCurrentFile(mediaPath)

        // Load metadata for audio files
        MediaController.loadMediaMetadata(mediaPath)

        // Determine if it's a video file
        var path = mediaPath.toString().toLowerCase()
        isVideo = path.includes('.mp4') || path.includes('.avi') ||
                  path.includes('.mov') || path.includes('.mkv') ||
                  path.includes('.webm') || path.includes('.wmv') ||
                  path.includes('.m4v') || path.includes('.flv')
    }

    function getFileName(filePath) {
        if (filePath === "") return ""

        var path = filePath.toString()
        if (path.startsWith("file://")) {
            path = path.substring(7)
        }

        var lastSlash = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'))
        return lastSlash >= 0 ? path.substring(lastSlash + 1) : path
    }

    function formatFileSize(bytes) {
        if (bytes === 0) return "0 B"

        var k = 1024
        var sizes = ["B", "KB", "MB", "GB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))

        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i]
    }
}
