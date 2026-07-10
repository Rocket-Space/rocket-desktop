pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property color background: "#0d0d1a"
    readonly property color surface: "#151525"
    readonly property color panel: Qt.rgba(0.051, 0.051, 0.102, 0.88)
    readonly property color text: "#e0e0ff"
    readonly property color accent: "#00d4ff"
    readonly property color secondary: "#ff00aa"
    readonly property color success: "#00ff88"
    readonly property color warning: "#ffaa00"
    readonly property color error: "#ff3355"
    readonly property color border: Qt.rgba(0, 0.831, 1, 0.25)

    readonly property int gap: 8
    readonly property int radius: 12

    readonly property string fontFamily: "Noto Sans"
    readonly property int fontSize: 11
    readonly property int fontSizeSmall: 9
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeTitle: 18

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }
}
