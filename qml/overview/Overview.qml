import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../common" as Common

Item {
    id: root

    property bool active: false
    property var windows: []

    signal windowSelected(int id)
    signal windowClosed(int id)
    signal exited()

    anchors.fill: parent
    visible: active
    z: 100

    onActiveChanged: {
        if (active) {
            fadeIn.start()
            arrangeWindows()
        } else {
            fadeOut.start()
        }
    }

    function arrangeWindows() {
        if (windows.length === 0) return
        var cols = Math.ceil(Math.sqrt(windows.length))
        var rows = Math.ceil(windows.length / cols)
        var cardW = Math.min(320, (width - 60) / cols - 20)
        var cardH = Math.min(220, (height - 80) / rows - 20)

        for (var i = 0; i < windowsGridRepeater.count; i++) {
            var item = windowsGridRepeater.itemAt(i)
            if (item) {
                var col = i % cols
                var row = Math.floor(i / cols)
                item.targetX = 30 + col * (cardW + 20)
                item.targetY = 40 + row * (cardH + 20)
                item.targetW = cardW
                item.targetH = cardH
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: overlay
        property: "opacity"
        from: 0; to: 0.7
        duration: 250
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: fadeOut
        target: overlay
        property: "opacity"
        from: 0.7; to: 0
        duration: 200
        easing.type: Easing.InCubic
        onFinished: {
            if (!active) root.exited()
        }
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Common.Theme.background
        opacity: active ? 0.7 : 0
        visible: opacity > 0

        MouseArea {
            anchors.fill: parent
            onClicked: root.active = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item { Layout.preferredHeight: 16 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Overview"
            font.family: Common.Theme.fontFamily
            font.pixelSize: Common.Theme.fontSizeTitle
            font.bold: true
            color: Common.Theme.accent
            opacity: 0.9
        }

        Item { Layout.preferredHeight: 12 }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                id: windowsGridRepeater
                model: root.windows

                Item {
                    id: windowCard
                    property real targetX: 0
                    property real targetY: 0
                    property real targetW: 200
                    property real targetH: 150
                    property bool isHovered: cardMouse.containsMouse

                    x: targetX
                    y: targetY
                    width: targetW
                    height: targetH

                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    scale: isHovered ? 1.04 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    z: isHovered ? 10 : 1

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Theme.radius
                        color: Common.Theme.surface
                        border.color: modelData.active ? Common.Theme.accent : Common.Theme.border
                        border.width: 1
                    }

                    Rectangle {
                        id: titleBar
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        radius: Common.Theme.radius
                        color: Common.Theme.withAlpha(Common.Theme.accent, 0.1)

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.radius
                            color: parent.color
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 6

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: modelData.active ? Common.Theme.accent : Common.Theme.text
                                opacity: modelData.active ? 1.0 : 0.4
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title || "Window"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: closeBtnArea.containsMouse ? Common.Theme.error : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u00D7"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Common.Theme.error
                                }

                                MouseArea {
                                    id: closeBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.windowClosed(modelData.id)
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.top: titleBar.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        radius: 4
                        color: Common.Theme.background
                        opacity: 0.6
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.windowSelected(modelData.id)
                            root.active = false
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 16 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Click a window to focus \u2022 Esc to exit"
            font.family: Common.Theme.fontFamily
            font.pixelSize: Common.Theme.fontSizeSmall
            color: Common.Theme.text
            opacity: 0.3
        }

        Item { Layout.preferredHeight: 16 }
    }

    Keys.onEscapePressed: root.active = false
}
