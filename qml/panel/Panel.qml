import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../common" as Common

Item {
    id: root

    property int activeWorkspace: 0
    property var windows: []
    property var trayItems: []
    property string clockTime: Qt.formatDateTime(new Date(), "HH:mm")
    property bool launcherVisible: false

    signal workspaceChanged(int index)
    signal windowClicked(int id)
    signal windowCloseClicked(int id)
    signal launcherToggled()
    signal statusClicked(string area)

    width: parent.width - 16
    height: 44
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockTime = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Rectangle {
        id: panelBg
        anchors.fill: parent
        color: Common.Theme.panel
        border.color: Common.Theme.border
        border.width: 1
        radius: Common.Theme.radius

        Rectangle {
            anchors.fill: parent
            radius: Common.Theme.radius
            color: "transparent"
            clip: true
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 0

        RowLayout {
            id: workspaceDots
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 4

                Rectangle {
                    width: activeWorkspace === index ? 16 : 8
                    height: 8
                    radius: 4
                    color: activeWorkspace === index ? Common.Theme.accent : Common.Theme.text
                    opacity: activeWorkspace === index ? 1.0 : 0.3

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.workspaceChanged(index)
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            color: Common.Theme.border
        }

        RowLayout {
            id: taskbar
            spacing: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Repeater {
                model: root.windows

                Rectangle {
                    id: windowButton
                    property bool isActive: modelData.active || false
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.maximumWidth: 200
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    Layout.leftMargin: 1
                    Layout.rightMargin: 1
                    radius: 6
                    color: isActive ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 4
                        spacing: 4

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: isActive ? Common.Theme.accent : Common.Theme.text
                            opacity: isActive ? 1.0 : 0.4
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title || "Window"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            color: isActive ? Common.Theme.accent : Common.Theme.text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: closeArea.containsMouse ? Common.Theme.error : "transparent"
                            visible: windowButton.hovered

                            Text {
                                anchors.centerIn: parent
                                text: "\u00D7"
                                font.pixelSize: 12
                                color: Common.Theme.error
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.windowCloseClicked(modelData.id)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.windowClicked(modelData.id)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: clockLabel.implicitWidth + 20
            Layout.fillHeight: true
            color: "transparent"

            Text {
                id: clockLabel
                anchors.centerIn: parent
                text: root.clockTime
                font.family: Common.Theme.fontFamily
                font.pixelSize: Common.Theme.fontSize
                font.bold: true
                color: Common.Theme.text
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: statusArea
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: root.trayItems.length > 0 ? root.trayItems : defaultTray

                Item {
                    width: 20
                    height: 20

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon || ""
                        font.pixelSize: 14
                        color: Common.Theme.text
                        opacity: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.children[0].opacity = 1.0
                        onExited: parent.children[0].opacity = 0.8
                        onClicked: root.statusClicked(modelData.id || "")
                    }
                }
            }

            ListModel {
                id: defaultTray
                ListElement { icon: "\u26A1"; id: "battery" }
                ListElement { icon: "\u2756"; id: "network" }
                ListElement { icon: "\u266B"; id: "volume" }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            color: Common.Theme.border
        }

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: launcherArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.2) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\u25C6"
                font.pixelSize: 16
                color: launcherArea.containsMouse ? Common.Theme.accent : Common.Theme.text
                rotation: 45

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: launcherArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcherToggled()
            }
        }
    }
}
