import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../common" as Common

Item {
    id: root

    property int activeWorkspace: 0
    property var windows: []
    property string clockTime: Qt.formatDateTime(new Date(), "HH:mm")
    property bool launcherVisible: false

    property real batteryLevel: 100
    property bool batteryCharging: false
    property string networkName: "Connected"
    property bool networkConnected: true
    property int volumeLevel: 75
    property bool volumeMuted: false
    property real cpuUsage: 0
    property bool bluetoothEnabled: false

    signal workspaceChanged(int index)
    signal windowClicked(int id)
    signal windowCloseClicked(int id)
    signal launcherToggled()
    signal statusClicked(string area)
    signal openTerminal(string command)

    width: root.Window ? root.Window.width : 800
    height: 44
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: 8

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockTime = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            updateSystemStats()
        }
    }

    function updateSystemStats() {
        try {
            var cpuFile = "/proc/stat"
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file://" + cpuFile, false)
            xhr.send()
            if (xhr.status === 200) {
                var lines = xhr.responseText.split("\n")
                if (lines.length > 0) {
                    var parts = lines[0].split(/\s+/)
                    if (parts.length >= 5) {
                        var user = parseInt(parts[1]) || 0
                        var nice = parseInt(parts[2]) || 0
                        var system = parseInt(parts[3]) || 0
                        var idle = parseInt(parts[4]) || 0
                        var total = user + nice + system + idle
                        root.cpuUsage = Math.round((total - idle) / total * 100)
                    }
                }
            }
        } catch(e) {}
    }

    function getBatteryIcon() {
        if (root.batteryCharging) return "\u26A1"
        if (root.batteryLevel > 75) return "\u25CF"
        if (root.batteryLevel > 50) return "\u25D4"
        if (root.batteryLevel > 25) return "\u25D1"
        return "\u25D2"
    }

    function getVolumeIcon() {
        if (root.volumeMuted || root.volumeLevel === 0) return "\u2716"
        if (root.volumeLevel < 33) return "\u266A"
        if (root.volumeLevel < 66) return "\u266B"
        return "\u266C"
    }

    function getNetworkIcon() {
        return root.networkConnected ? "\u25C8" : "\u25CE"
    }

    function getBluetoothIcon() {
        return root.bluetoothEnabled ? "\u25B8" : "\u25B9"
    }

    Rectangle {
        id: panelBg
        anchors.fill: parent
        color: Common.Theme.panel
        border.color: Common.Theme.border
        border.width: 1
        radius: Common.Theme.radius
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 0

        // Workspace dots
        RowLayout {
            id: workspaceDots
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 4

                Rectangle {
                    width: root.activeWorkspace === index ? 16 : 8
                    height: 8
                    radius: 4
                    color: root.activeWorkspace === index ? Common.Theme.accent : Common.Theme.text
                    opacity: root.activeWorkspace === index ? 1.0 : 0.3

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

        // Taskbar
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

        // Clock
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

        // Status widgets
        RowLayout {
            id: statusArea
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            // CPU Monitor
            Rectangle {
                width: cpuLayout.implicitWidth + 16
                height: 28
                radius: 6
                color: cpuMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                RowLayout {
                    id: cpuLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "\u25A3"
                        font.pixelSize: 12
                        color: Common.Theme.accent
                    }

                    Text {
                        text: root.cpuUsage + "%"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Common.Theme.text
                    }
                }

                MouseArea {
                    id: cpuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openTerminal("htop || btop || top")
                }

                ToolTip {
                    visible: cpuMouse.containsMouse
                    text: "CPU: " + root.cpuUsage + "%\nClick to open htop"
                    delay: 500
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                color: Common.Theme.border
                opacity: 0.5
            }

            // Battery
            Rectangle {
                width: batteryLayout.implicitWidth + 16
                height: 28
                radius: 6
                color: batteryMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                RowLayout {
                    id: batteryLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: getBatteryIcon()
                        font.pixelSize: 12
                        color: root.batteryCharging ? "#00ff88" : (root.batteryLevel < 20 ? "#ff3355" : Common.Theme.text)
                    }

                    Text {
                        text: Math.round(root.batteryLevel) + "%"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Common.Theme.text
                        visible: root.batteryLevel < 100 || root.batteryCharging
                    }
                }

                MouseArea {
                    id: batteryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openTerminal("powerprofilesctl get && upower -i /org/freedesktop/UPower/devices/battery_BAT0")
                }

                ToolTip {
                    visible: batteryMouse.containsMouse
                    text: "Battery: " + Math.round(root.batteryLevel) + "%" + (root.batteryCharging ? " (Charging)" : "") + "\nClick for details"
                    delay: 500
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                color: Common.Theme.border
                opacity: 0.5
            }

            // Network
            Rectangle {
                width: networkLayout.implicitWidth + 16
                height: 28
                radius: 6
                color: networkMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                RowLayout {
                    id: networkLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: getNetworkIcon()
                        font.pixelSize: 12
                        color: root.networkConnected ? "#00ff88" : "#ff3355"
                    }

                    Text {
                        text: root.networkConnected ? (root.networkName || "WiFi") : "Offline"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Common.Theme.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Layout.maximumWidth: 80
                    }
                }

                MouseArea {
                    id: networkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openTerminal("nmtui || nmcli device wifi list")
                }

                ToolTip {
                    visible: networkMouse.containsMouse
                    text: "Network: " + (root.networkConnected ? root.networkName : "Disconnected") + "\nClick to open nmtui"
                    delay: 500
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                color: Common.Theme.border
                opacity: 0.5
            }

            // Volume
            Rectangle {
                width: volumeLayout.implicitWidth + 16
                height: 28
                radius: 6
                color: volumeMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                RowLayout {
                    id: volumeLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: getVolumeIcon()
                        font.pixelSize: 12
                        color: root.volumeMuted ? "#ff3355" : Common.Theme.text
                    }

                    Text {
                        text: root.volumeMuted ? "Muted" : root.volumeLevel + "%"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Common.Theme.text
                    }
                }

                MouseArea {
                    id: volumeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openTerminal("pavucontrol || pwvucontrol || alsamixer")
                    onWheel: {
                        if (wheel.angleDelta.y > 0) {
                            root.volumeLevel = Math.min(100, root.volumeLevel + 5)
                        } else {
                            root.volumeLevel = Math.max(0, root.volumeLevel - 5)
                        }
                    }
                }

                ToolTip {
                    visible: volumeMouse.containsMouse
                    text: "Volume: " + (root.volumeMuted ? "Muted" : root.volumeLevel + "%") + "\nClick for mixer, Scroll to adjust"
                    delay: 500
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                color: Common.Theme.border
                opacity: 0.5
            }

            // Bluetooth
            Rectangle {
                width: bluetoothLayout.implicitWidth + 16
                height: 28
                radius: 6
                color: bluetoothMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : "transparent"

                RowLayout {
                    id: bluetoothLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: getBluetoothIcon()
                        font.pixelSize: 12
                        color: root.bluetoothEnabled ? "#00d4ff" : Common.Theme.text
                        opacity: root.bluetoothEnabled ? 1.0 : 0.5
                    }
                }

                MouseArea {
                    id: bluetoothMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openTerminal("bluetoothctl || blueman-manager")
                }

                ToolTip {
                    visible: bluetoothMouse.containsMouse
                    text: "Bluetooth: " + (root.bluetoothEnabled ? "Enabled" : "Disabled") + "\nClick to open bluetoothctl"
                    delay: 500
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

        // Launcher button
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
