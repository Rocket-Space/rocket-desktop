import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Common

Item {
    id: root

    property var notifications: []
    property int spacing: Common.Theme.gap

    anchors.fill: parent

    function pushNotification(appName, summary, body, icon) {
        var n = ({
            id: Date.now(),
            appName: appName || "System",
            summary: summary || "",
            body: body || "",
            icon: icon || "\u2139",
            timestamp: Qt.formatDateTime(new Date(), "HH:mm"),
            dismissing: false
        })
        notifications = notifications.concat(n)
        dismissTimer.restart()
    }

    function dismissNotification(id) {
        for (var i = 0; i < notifications.length; i++) {
            if (notifications[i].id === id) {
                var updated = notifications.slice()
                updated.splice(i, 1)
                notifications = updated
                break
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: {
            if (notifications.length > 0) {
                dismissNotification(notifications[0].id)
                if (notifications.length > 0) dismissTimer.restart()
            }
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 16
        spacing: root.spacing
        width: 360

        Repeater {
            model: root.notifications

            Rectangle {
                id: notifCard
                Layout.fillWidth: true
                Layout.preferredHeight: notifContent.implicitHeight + 24
                radius: Common.Theme.radius
                color: Common.Theme.surface
                border.color: Common.Theme.accent
                border.width: 1
                opacity: 0
                x: 400

                Component.onCompleted: {
                    slideIn.start()
                    opacity = 1
                }

                NumberAnimation {
                    id: slideIn
                    target: notifCard
                    property: "x"
                    from: 400; to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    id: slideOut
                    target: notifCard
                    property: "x"
                    from: 0; to: 400
                    duration: 250
                    easing.type: Easing.InCubic
                    onFinished: root.dismissNotification(modelData.id)
                }

                NumberAnimation {
                    id: fadeOut
                    target: notifCard
                    property: "opacity"
                    from: 1; to: 0
                    duration: 200
                    onFinished: slideOut.start()
                }

                Timer {
                    interval: 4500
                    running: true
                    repeat: false
                    onTriggered: fadeOut.start()
                }

                ColumnLayout {
                    id: notifContent
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: Common.Theme.withAlpha(Common.Theme.accent, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 16
                                color: Common.Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.appName
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                font.bold: true
                                color: Common.Theme.accent
                            }

                            Text {
                                text: modelData.summary
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: notifCloseArea.containsMouse ? Common.Theme.error : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "\u00D7"
                                font.pixelSize: 14
                                color: Common.Theme.text
                                opacity: 0.5
                            }

                            MouseArea {
                                id: notifCloseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fadeOut.start()
                                }
                            }
                        }
                    }

                    Text {
                        text: modelData.body
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSizeSmall
                        color: Common.Theme.text
                        opacity: 0.7
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    Text {
                        text: modelData.timestamp
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSizeSmall - 1
                        color: Common.Theme.text
                        opacity: 0.3
                        Layout.alignment: Qt.AlignRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.dismissNotification(modelData.id)
                }
            }
        }
    }
}
