import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../common" as Common

Item {
    id: root

    property bool visible: false
    property string searchText: ""
    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0

    signal launchApp(string desktopFile)
    signal closed()

    anchors.centerIn: parent
    width: 600
    height: 400

    onVisibleChanged: {
        if (visible) {
            searchText = ""
            filterApps()
            searchInput.forceActiveFocus()
            openAnimation.start()
        } else {
            closeAnimation.start()
        }
    }

    function filterApps() {
        var results = []
        var query = searchText.toLowerCase()
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]
            if (query === "" || fuzzyMatch(app.name.toLowerCase(), query)) {
                results.push(app)
            }
        }
        filteredApps = results
        selectedIndex = 0
    }

    function fuzzyMatch(text, pattern) {
        var pi = 0
        for (var ti = 0; ti < text.length && pi < pattern.length; ti++) {
            if (text[ti] === pattern[pi]) pi++
        }
        return pi === pattern.length
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex < filteredApps.length) {
            root.launchApp(filteredApps[selectedIndex].desktopFile)
            root.visible = false
        }
    }

    NumberAnimation {
        id: openAnimation
        target: launcherContainer
        property: "scale"
        from: 0.9
        to: 1.0
        duration: 200
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnimation
        target: launcherContainer
        property: "scale"
        from: 1.0
        to: 0.9
        duration: 150
        easing.type: Easing.InCubic
        onFinished: {
            if (!root.visible) root.closed()
        }
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "transparent"
        visible: root.visible
        z: -1

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    Rectangle {
        id: launcherContainer
        anchors.fill: parent
        color: Common.Theme.surface
        border.color: Common.Theme.border
        border.width: 1
        radius: Common.Theme.radius
        scale: root.visible ? 1.0 : 0.9
        opacity: root.visible ? 1.0 : 0.0
        visible: root.visible

        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Common.Theme.gap
            spacing: Common.Theme.gap

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 8
                color: Common.Theme.background
                border.color: searchInput.activeFocus ? Common.Theme.accent : Common.Theme.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "\u26B2"
                        font.pixelSize: 16
                        color: searchInput.activeFocus ? Common.Theme.accent : Common.Theme.text
                        opacity: 0.6
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Common.Theme.text
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSize
                        clip: true
                        focus: root.visible
                        cursorVisible: true

                        onTextChanged: {
                            root.searchText = text
                            root.filterApps()
                        }

                        Keys.onDownPressed: {
                            if (root.selectedIndex < root.filteredApps.length - 1)
                                root.selectedIndex++
                        }
                        Keys.onUpPressed: {
                            if (root.selectedIndex > 0)
                                root.selectedIndex--
                        }
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onEscapePressed: root.visible = false

                        Text {
                            visible: searchInput.text === "" && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search applications..."
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            color: Common.Theme.text
                            opacity: 0.3
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.border
            }

            GridView {
                id: appsGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: (width - Common.Theme.gap) / 4
                cellHeight: 90
                model: root.filteredApps
                currentIndex: root.selectedIndex
                highlightRangeMode: GridView.ApplyRange
                preferredHighlightBegin: 0
                preferredHighlightHeight: height

                highlight: Rectangle {
                    radius: 8
                    color: Common.Theme.withAlpha(Common.Theme.accent, 0.12)
                    border.color: Common.Theme.withAlpha(Common.Theme.accent, 0.3)
                    border.width: 1

                    Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                delegate: Item {
                    width: appsGrid.cellWidth
                    height: appsGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: appMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.1) : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 44
                                height: 44
                                radius: 10
                                color: Common.Theme.withAlpha(Common.Theme.accent, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.pixelSize: 20
                                    font.bold: true
                                    color: Common.Theme.accent
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name || "App"
                                font.family: Common.Theme.fontFamily
                                font.pixelSize: Common.Theme.fontSizeSmall
                                color: Common.Theme.text
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index
                                root.launchSelected()
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.filteredApps.length + " applications"
                font.family: Common.Theme.fontFamily
                font.pixelSize: Common.Theme.fontSizeSmall
                color: Common.Theme.text
                opacity: 0.3
            }
        }
    }
}
