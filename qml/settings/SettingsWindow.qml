import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Common

Item {
    id: root

    property bool active: false
    property int selectedIndex: 0
    property var sections: ["General", "Appearance", "Keybinds", "Power", "Network", "Bluetooth"]

    signal closed()

    anchors.centerIn: parent
    width: 800
    height: 600
    visible: active
    z: 200

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.background
        border.color: Common.Theme.border
        border.width: 1
        radius: Common.Theme.radius

        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 180
                Layout.fillHeight: true
                color: Common.Theme.surface
                radius: Common.Theme.radius

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.right
                    anchors.bottom: parent.bottom
                    width: parent.radius
                    color: parent.color
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Common.Theme.gap
                    spacing: 2

                    Text {
                        text: "Settings"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSizeTitle
                        font.bold: true
                        color: Common.Theme.accent
                        Layout.bottomMargin: 12
                        Layout.leftMargin: 4
                    }

                    Repeater {
                        model: root.sections

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 8
                            color: root.selectedIndex === index ? Common.Theme.withAlpha(Common.Theme.accent, 0.15) : sectionHover.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.08) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                font.bold: root.selectedIndex === index
                                color: root.selectedIndex === index ? Common.Theme.accent : Common.Theme.text
                            }

                            MouseArea {
                                id: sectionHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedIndex = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: closeSettingsArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.error, 0.15) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u00D7  Close"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            color: closeSettingsArea.containsMouse ? Common.Theme.error : Common.Theme.text
                            opacity: 0.7
                        }

                        MouseArea {
                            id: closeSettingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.active = false
                                root.closed()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Common.Theme.border
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    currentIndex: root.selectedIndex

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "General"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        RowLayout {
                            spacing: Common.Theme.gap
                            Layout.fillWidth: true

                            Text {
                                text: "Language"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 120
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: ["English", "Espa\u00F1ol", "Deutsch", "Fran\u00E7ais", "日本語"]
                                background: Rectangle {
                                    radius: 8
                                    color: Common.Theme.surface
                                    border.color: Common.Theme.border
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.displayText
                                    font.family: Common.Theme.fontFamily
                                    font.pixelSize: Common.Theme.fontSize
                                    color: Common.Theme.text
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }
                            }
                        }

                        RowLayout {
                            spacing: Common.Theme.gap
                            Layout.fillWidth: true

                            Text {
                                text: "Compositor"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 120
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Hyprland", "Sway", "KWin"]
                                background: Rectangle {
                                    radius: 8
                                    color: Common.Theme.surface
                                    border.color: Common.Theme.border
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.displayText
                                    font.family: Common.Theme.fontFamily
                                    font.pixelSize: Common.Theme.fontSize
                                    color: Common.Theme.text
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "Appearance"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        RowLayout {
                            spacing: Common.Theme.gap
                            Layout.fillWidth: true

                            Text {
                                text: "Theme"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 120
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Cyberpunk", "Midnight", "Neon Dark", "Minimal"]
                                background: Rectangle {
                                    radius: 8
                                    color: Common.Theme.surface
                                    border.color: Common.Theme.border
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.displayText
                                    font.family: Common.Theme.fontFamily
                                    font.pixelSize: Common.Theme.fontSize
                                    color: Common.Theme.text
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }
                            }
                        }

                        RowLayout {
                            spacing: Common.Theme.gap
                            Layout.fillWidth: true

                            Text {
                                text: "Accent Color"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 120
                            }

                            Row {
                                spacing: 8

                                Repeater {
                                    model: ["#00d4ff", "#ff00aa", "#00ff88", "#ffaa00", "#ff3355", "#aa77ff"]

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: modelData
                                        border.color: "white"
                                        border.width: 2

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: console.log("Accent:", modelData)
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: Common.Theme.gap
                            Layout.fillWidth: true

                            Text {
                                text: "Font Size"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 120
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 9; to: 16; stepSize: 1
                                value: 11
                                background: Rectangle {
                                    x: parent.leftPadding
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                    width: parent.availableWidth
                                    height: 4
                                    radius: 2
                                    color: Common.Theme.surface

                                    Rectangle {
                                        width: parent.width * parent.parent.parent.position
                                        height: parent.height
                                        radius: 2
                                        color: Common.Theme.accent
                                    }
                                }
                                handle: Rectangle {
                                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                    width: 16; height: 16; radius: 8
                                    color: Common.Theme.accent
                                    border.color: "white"
                                    border.width: 2
                                }
                            }

                            Text {
                                text: Math.round(sliderFontSize.value)
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignRight
                            }

                            Slider {
                                id: sliderFontSize
                                visible: false
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "Keybinds"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        Repeater {
                            model: [
                                { action: "Launcher", shortcut: "Super" },
                                { action: "Overview", shortcut: "Super + Tab" },
                                { action: "Close Window", shortcut: "Super + Q" },
                                { action: "Terminal", shortcut: "Super + Enter" },
                                { action: "Settings", shortcut: "Super + Comma" },
                                { action: "Clipboard", shortcut: "Super + V" },
                                { action: "Screenshot", shortcut: "Print Screen" },
                                { action: "Lock Screen", shortcut: "Super + L" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 8
                                color: keybindHover.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.08) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: Common.Theme.gap

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.action
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSize
                                        color: Common.Theme.text
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: shortcutLabel.implicitWidth + 16
                                        Layout.preferredHeight: 26
                                        radius: 6
                                        color: Common.Theme.surface
                                        border.color: Common.Theme.border
                                        border.width: 1

                                        Text {
                                            id: shortcutLabel
                                            anchors.centerIn: parent
                                            text: modelData.shortcut
                                            font.family: Common.Theme.fontFamily
                                            font.pixelSize: Common.Theme.fontSizeSmall
                                            color: Common.Theme.accent
                                        }
                                    }
                                }

                                MouseArea {
                                    id: keybindHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: console.log("Edit keybind:", modelData.action)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "Power"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        Repeater {
                            model: [
                                { label: "Suspend", icon: "\u23FE", color: Common.Theme.warning },
                                { label: "Hibernate", icon: "\u23FB", color: Common.Theme.warning },
                                { label: "Reboot", icon: "\u21BB", color: Common.Theme.accent },
                                { label: "Shutdown", icon: "\u23FB", color: Common.Theme.error }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 10
                                color: powerHover.containsMouse ? Common.Theme.withAlpha(modelData.color, 0.15) : Common.Theme.surface
                                border.color: powerHover.containsMouse ? modelData.color : Common.Theme.border
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 18
                                        color: modelData.color
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSize
                                        color: Common.Theme.text
                                    }
                                }

                                MouseArea {
                                    id: powerHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: console.log("Power action:", modelData.label)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "Network"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 10
                            color: Common.Theme.surface
                            border.color: Common.Theme.success
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    text: "\u2756"
                                    font.pixelSize: 22
                                    color: Common.Theme.success
                                }

                                ColumnLayout {
                                    spacing: 2

                                    Text {
                                        text: "Connected"
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSize
                                        font.bold: true
                                        color: Common.Theme.success
                                    }

                                    Text {
                                        text: "wlan0 \u2022 192.168.1.42"
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSizeSmall
                                        color: Common.Theme.text
                                        opacity: 0.6
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Wi-Fi Networks"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            font.bold: true
                            color: Common.Theme.text
                            Layout.topMargin: 12
                            Layout.bottomMargin: 4
                        }

                        Repeater {
                            model: ["Home_5G", "OfficeWiFi", "Guest_Network", "Cafe_Free"]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 8
                                color: netHover.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.08) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        text: "\u25C9"
                                        font.pixelSize: 10
                                        color: index === 0 ? Common.Theme.success : Common.Theme.text
                                        opacity: index === 0 ? 1 : 0.4
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSize
                                        color: Common.Theme.text
                                    }

                                    Text {
                                        text: index === 0 ? "Connected" : ""
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSizeSmall
                                        color: Common.Theme.success
                                    }
                                }

                                MouseArea {
                                    id: netHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: Common.Theme.gap

                        Text {
                            text: "Bluetooth"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeLarge
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 8
                        }

                        RowLayout {
                            spacing: Common.Theme.gap

                            Text {
                                text: "Bluetooth"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSize
                                color: Common.Theme.text
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 44; height: 24; radius: 12
                                color: btSwitch.checked ? Common.Theme.accent : Common.Theme.surface
                                border.color: Common.Theme.border
                                border.width: 1

                                Rectangle {
                                    x: btSwitch.checked ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 20; height: 20; radius: 10
                                    color: "white"

                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: btSwitch.checked = !btSwitch.checked
                                }

                                property bool checked: true
                                id: btSwitch
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Common.Theme.border
                        }

                        Text {
                            text: "Paired Devices"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            font.bold: true
                            color: Common.Theme.text
                            Layout.bottomMargin: 4
                        }

                        Repeater {
                            model: [
                                { name: "MX Keys", type: "Keyboard" },
                                { name: "AirPods Pro", type: "Headphones" },
                                { name: "MX Master 3", type: "Mouse" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 10
                                color: Common.Theme.surface
                                border.color: Common.Theme.border
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 32; height: 32; radius: 8
                                        color: Common.Theme.withAlpha(Common.Theme.accent, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.type === "Keyboard" ? "\u2328" : modelData.type === "Headphones" ? "\u266B" : "\u25CE"
                                            font.pixelSize: 16
                                            color: Common.Theme.accent
                                        }
                                    }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: modelData.name
                                                font.family: Common.Theme.fontFamily
                                                font.pixelSize: Common.Theme.fontSize
                                                color: Common.Theme.text
                                            }

                                            Text {
                                                text: modelData.type
                                                font.family: Common.Theme.fontFamily
                                                font.pixelSize: Common.Theme.fontSizeSmall
                                                color: Common.Theme.text
                                                opacity: 0.5
                                            }
                                        }

                                    Text {
                                        text: "Connected"
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSizeSmall
                                        color: Common.Theme.success
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: {
        root.active = false
        root.closed()
    }
}
