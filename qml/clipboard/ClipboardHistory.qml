import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Common

Item {
    id: root

    property bool active: false
    property string searchText: ""
    property var pinnedItems: []
    property var historyItems: []
    property int selectedIndex: -1

    signal closed()
    signal itemCopied(string text)
    signal itemPinned(int id)
    signal itemUnpinned(int id)
    signal itemDeleted(int id)

    anchors.centerIn: parent
    width: 350
    height: 500
    visible: active
    z: 150

    function filteredItems() {
        var query = searchText.toLowerCase()
        var items = pinnedItems.concat(historyItems)
        if (query === "") return items
        return items.filter(function(item) {
            return item.text.toLowerCase().indexOf(query) !== -1
        })
    }

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.surface
        border.color: Common.Theme.border
        border.width: 1
        radius: Common.Theme.radius

        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Common.Theme.gap
            spacing: Common.Theme.gap

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\u2398"
                    font.pixelSize: 18
                    color: Common.Theme.accent
                }

                Text {
                    text: "Clipboard"
                    font.family: Common.Theme.fontFamily
                    font.pixelSize: Common.Theme.fontSizeLarge
                    font.bold: true
                    color: Common.Theme.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: clearAllArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.error, 0.2) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        font.pixelSize: 12
                        color: clearAllArea.containsMouse ? Common.Theme.error : Common.Theme.text
                        opacity: 0.6
                    }

                    MouseArea {
                        id: clearAllArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.historyItems = []
                        }
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: closeClipArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.error, 0.2) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\u00D7"
                        font.pixelSize: 14
                        font.bold: true
                        color: closeClipArea.containsMouse ? Common.Theme.error : Common.Theme.text
                        opacity: 0.6
                    }

                    MouseArea {
                        id: closeClipArea
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

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: Common.Theme.background
                border.color: clipSearch.activeFocus ? Common.Theme.accent : Common.Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: "\u26B2"
                        font.pixelSize: 13
                        color: Common.Theme.text
                        opacity: 0.4
                    }

                    TextInput {
                        id: clipSearch
                        Layout.fillWidth: true
                        color: Common.Theme.text
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSize
                        clip: true
                        focus: root.active
                        cursorVisible: true

                        onTextChanged: root.searchText = text

                        Keys.onEscapePressed: {
                            root.active = false
                            root.closed()
                        }

                        Text {
                            visible: clipSearch.text === "" && !clipSearch.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search clipboard..."
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

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: clipContent.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Common.Theme.withAlpha(Common.Theme.accent, 0.3)
                    }
                    background: Rectangle {
                        color: "transparent"
                    }
                }

                ColumnLayout {
                    id: clipContent
                    width: parent.width
                    spacing: Common.Theme.gap

                    ColumnLayout {
                        visible: root.pinnedItems.length > 0
                        spacing: 4

                        Text {
                            text: "Pinned"
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeSmall
                            color: Common.Theme.accent
                            opacity: 0.7
                            Layout.leftMargin: 4
                            Layout.bottomMargin: 2
                        }

                        Repeater {
                            model: root.pinnedItems

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: clipItemContent.implicitHeight + 20
                                radius: 8
                                color: itemArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.1) : Common.Theme.withAlpha(Common.Theme.accent, 0.06)
                                border.color: Common.Theme.withAlpha(Common.Theme.accent, 0.2)
                                border.width: 1

                                ColumnLayout {
                                    id: clipItemContent
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "\u2605"
                                            font.pixelSize: 10
                                            color: Common.Theme.accent
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.text || ""
                                            font.family: Common.Theme.fontFamily
                                            font.pixelSize: Common.Theme.fontSize
                                            color: Common.Theme.text
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.timestamp || ""
                                            font.family: Common.Theme.fontFamily
                                            font.pixelSize: Common.Theme.fontSizeSmall - 1
                                            color: Common.Theme.text
                                            opacity: 0.3
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            width: 20; height: 16; radius: 4
                                            color: pinDelArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.error, 0.2) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\u2193"
                                                font.pixelSize: 11
                                                color: pinDelArea.containsMouse ? Common.Theme.error : Common.Theme.text
                                                opacity: 0.5
                                            }

                                            MouseArea {
                                                id: pinDelArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.itemUnpinned(modelData.id)
                                            }
                                        }

                                        Rectangle {
                                            width: 20; height: 16; radius: 4
                                            color: pinCopyArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.success, 0.2) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\u2398"
                                                font.pixelSize: 10
                                                color: pinCopyArea.containsMouse ? Common.Theme.success : Common.Theme.text
                                                opacity: 0.5
                                            }

                                            MouseArea {
                                                id: pinCopyArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.itemCopied(modelData.text)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.itemCopied(modelData.text)
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.pinnedItems.length > 0 && root.historyItems.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Common.Theme.border
                    }

                    Text {
                        visible: root.historyItems.length > 0
                        text: "History"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSizeSmall
                        color: Common.Theme.text
                        opacity: 0.4
                        Layout.leftMargin: 4
                        Layout.bottomMargin: 2
                    }

                    Repeater {
                        model: root.filteredItems().filter(function(item) {
                            return root.pinnedItems.indexOf(item) === -1
                        })

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: histItemContent.implicitHeight + 20
                            radius: 8
                            color: histArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.08) : "transparent"

                            ColumnLayout {
                                id: histItemContent
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.text || ""
                                    font.family: Common.Theme.fontFamily
                                    font.pixelSize: Common.Theme.fontSize
                                    color: Common.Theme.text
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.timestamp || ""
                                        font.family: Common.Theme.fontFamily
                                        font.pixelSize: Common.Theme.fontSizeSmall - 1
                                        color: Common.Theme.text
                                        opacity: 0.3
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 20; height: 16; radius: 4
                                        color: histPinArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.2) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u2191"
                                            font.pixelSize: 11
                                            color: histPinArea.containsMouse ? Common.Theme.accent : Common.Theme.text
                                            opacity: 0.5
                                        }

                                        MouseArea {
                                            id: histPinArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.itemPinned(modelData.id)
                                        }
                                    }

                                    Rectangle {
                                        width: 20; height: 16; radius: 4
                                        color: histCopyArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.success, 0.2) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u2398"
                                            font.pixelSize: 10
                                            color: histCopyArea.containsMouse ? Common.Theme.success : Common.Theme.text
                                            opacity: 0.5
                                        }

                                        MouseArea {
                                            id: histCopyArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.itemCopied(modelData.text)
                                        }
                                    }

                                    Rectangle {
                                        width: 20; height: 16; radius: 4
                                        color: histDelArea.containsMouse ? Common.Theme.withAlpha(Common.Theme.error, 0.2) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u2715"
                                            font.pixelSize: 10
                                            color: histDelArea.containsMouse ? Common.Theme.error : Common.Theme.text
                                            opacity: 0.5
                                        }

                                        MouseArea {
                                            id: histDelArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.itemDeleted(modelData.id)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: histArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.itemCopied(modelData.text)
                            }
                        }
                    }

                    Text {
                        visible: root.filteredItems().length === 0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                        text: "No items found"
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: Common.Theme.fontSize
                        color: Common.Theme.text
                        opacity: 0.3
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.border
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.filteredItems().length + " items"
                font.family: Common.Theme.fontFamily
                font.pixelSize: Common.Theme.fontSizeSmall - 1
                color: Common.Theme.text
                opacity: 0.25
            }
        }
    }

    Keys.onEscapePressed: {
        root.active = false
        root.closed()
    }
}
