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
    property string currentView: "categories"
    property string currentCategory: ""

    signal launchApp(string desktopFile)
    signal openTerminal(string command)
    signal closed()

    anchors.centerIn: parent
    width: 700
    height: 500

    property var categories: [
        { name: "Apps", icon: "\u25CB", desc: "Launch applications" },
        { name: "Learn", icon: "\u2139", desc: "Documentation & help" },
        { name: "Trigger", icon: "\u25B6", desc: "Actions & utilities" },
        { name: "Style", icon: "\u2606", desc: "Theme & appearance" },
        { name: "Setup", icon: "\u2699", desc: "System settings" },
        { name: "Install", icon: "\u271A", desc: "Install packages" },
        { name: "Remove", icon: "\u2718", desc: "Remove packages" },
        { name: "Update", icon: "\u21BB", desc: "System updates" },
        { name: "About", icon: "\u24D8", desc: "About Rocket" },
        { name: "System", icon: "\u23FB", desc: "Power & session" }
    ]

    property var learnItems: [
        { name: "Keybindings", icon: "\u2328", command: "cat ~/.config/rocket/keybinds.txt 2>/dev/null || echo 'No keybinds file'" },
        { name: "Rocket Docs", icon: "\u25CB", command: "xdg-open https://github.com/Rocket-Space/rocket-desktop" },
        { name: "KWin Wiki", icon: "\u25CB", command: "xdg-open https://community.kde.org/KWin" },
        { name: "Arch Wiki", icon: "\u25CB", command: "xdg-open https://wiki.archlinux.org" }
    ]

    property var triggerItems: [
        { name: "Screenshot", icon: "\u25A3", command: "grim -g \"$(slurp)\" - | wl-copy" },
        { name: "Screen Record", icon: "\u25B6", command: "wf-recorder -f /tmp/recording.mp4" },
        { name: "Color Picker", icon: "\u25C9", command: "grim -g \"$(slurp)\" - | convert - -crop 1x1+0+0 txt:-" },
        { name: "Clipboard", icon: "\u2398", command: "cliphist list | wofi --dmenu | cliphist decode | wl-copy" },
        { name: "Timer", icon: "\u23F3", command: "kitty -e bash -c 'echo \"Timer (minutes):\"; read m; sleep $((m*60)); echo DONE | wall'" }
    ]

    property var styleItems: [
        { name: "Theme", icon: "\u2606", command: "rocket-settings --theme" },
        { name: "Wallpaper", icon: "\u25A3", command: "rocket-settings --wallpaper" },
        { name: "Font", icon: "\u25B4", command: "rocket-settings --font" },
        { name: "Corners", icon: "\u25CB", command: "rocket-settings --corners" },
        { name: "Colors", icon: "\u25C9", command: "rocket-settings --colors" }
    ]

    property var setupItems: [
        { name: "Audio", icon: "\u266B", command: "pavucontrol || pwvucontrol" },
        { name: "WiFi", icon: "\u25C8", command: "nmtui" },
        { name: "Bluetooth", icon: "\u25B8", command: "bluetoothctl" },
        { name: "Power Profile", icon: "\u26A1", command: "powerprofilesctl get" },
        { name: "Monitors", icon: "\u25A1", command: "arandr || nvidia-settings" },
        { name: "Input", icon: "\u2328", command: "rocket-settings --input" },
        { name: "DNS", icon: "\u25CB", command: "resolvectl status" },
        { name: "Firewall", icon: "\u25C9", command: "sudo ufw status" }
    ]

    property var installItems: [
        { name: "Package", icon: "\u271A", command: "paru -S --needed" },
        { name: "Browser", icon: "\u25CB", command: "paru -S --needed firefox chromium brave" },
        { name: "Editor", icon: "\u25B4", command: "paru -S --needed neovim vscode" },
        { name: "Terminal", icon: "\u25B7", command: "paru -S --needed kitty alacritty" },
        { name: "Gaming", icon: "\u25CF", command: "paru -S --needed steam lutris" },
        { name: "Development", icon: "\u25CB", command: "paru -S --needed base-devel git" },
        { name: "AI Tools", icon: "\u25C9", command: "paru -S --needed ollama" },
        { name: "Fonts", icon: "\u25B4", command: "paru -S --needed ttf-firacode-nerd" }
    ]

    property var removeItems: [
        { name: "Package", icon: "\u2718", command: "paru -Rns" },
        { name: "Orphans", icon: "\u2718", command: "paru -Rns $(pacman -Qdtq)" },
        { name: "Cache", icon: "\u2718", command: "paccache -r" },
        { name: "AUR Cache", icon: "\u2718", command: "paru -Sc" }
    ]

    property var updateItems: [
        { name: "Full System", icon: "\u21BB", command: "paru -Syu" },
        { name: "AUR Only", icon: "\u21BB", command: "paru -Sua" },
        { name: "Mirror List", icon: "\u21BB", command: "sudo reflector --latest 20 --protocol https --save /etc/pacman.d/mirrorlist" },
        { name: "Keyring", icon: "\u21BB", command: "sudo pacman -S archlinux-keyring" },
        { name: "Clean Cache", icon: "\u21BB", command: "paccache -r" }
    ]

    property var systemItems: [
        { name: "Lock", icon: "\u21E9", command: "loginctl lock-session" },
        { name: "Logout", icon: "\u21E9", command: "loginctl terminate-user $USER" },
        { name: "Suspend", icon: "\u21E9", command: "systemctl suspend" },
        { name: "Hibernate", icon: "\u21E9", command: "systemctl hibernate" },
        { name: "Reboot", icon: "\u21BB", command: "systemctl reboot" },
        { name: "Shutdown", icon: "\u23FB", command: "shutdown now" }
    ]

    onVisibleChanged: {
        if (visible) {
            currentView = "categories"
            currentCategory = ""
            searchText = ""
            filterApps()
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
        if (currentView === "categories") {
            if (selectedIndex < categories.length) {
                currentCategory = categories[selectedIndex].name
                if (currentCategory === "Apps") {
                    currentView = "apps"
                } else {
                    currentView = "items"
                }
                searchText = ""
                selectedIndex = 0
            }
        } else if (currentView === "items") {
            var items = getItemList()
            if (selectedIndex < items.length) {
                root.openTerminal(items[selectedIndex].command)
                root.visible = false
            }
        } else if (currentView === "apps") {
            if (filteredApps.length > 0 && selectedIndex < filteredApps.length) {
                root.launchApp(filteredApps[selectedIndex].desktopFile)
                root.visible = false
            }
        }
    }

    function getItemList() {
        switch(currentCategory) {
            case "Learn": return learnItems
            case "Trigger": return triggerItems
            case "Style": return styleItems
            case "Setup": return setupItems
            case "Install": return installItems
            case "Remove": return removeItems
            case "Update": return updateItems
            case "System": return systemItems
            default: return []
        }
    }

    function goBack() {
        if (currentView === "apps" || currentView === "items") {
            currentView = "categories"
            currentCategory = ""
            searchText = ""
            selectedIndex = 0
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

            // Header with back button and search
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

                    // Back button
                    Text {
                        text: root.currentView !== "categories" ? "\u25C0" : "\u25CB"
                        font.pixelSize: 14
                        color: backArea.containsMouse ? Common.Theme.accent : Common.Theme.text
                        opacity: root.currentView !== "categories" ? 1.0 : 0.3

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: root.currentView !== "categories" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.goBack()
                        }
                    }

                    // Search input
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
                            if (root.currentView === "apps") {
                                root.filterApps()
                            }
                        }

                        Keys.onDownPressed: {
                            var maxItems = root.currentView === "categories" ? root.categories.length :
                                          root.currentView === "items" ? root.getItemList().length :
                                          root.filteredApps.length
                            if (root.selectedIndex < maxItems - 1)
                                root.selectedIndex++
                        }
                        Keys.onUpPressed: {
                            if (root.selectedIndex > 0)
                                root.selectedIndex--
                        }
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onEscapePressed: {
                            if (root.currentView !== "categories") {
                                root.goBack()
                            } else {
                                root.visible = false
                            }
                        }
                        Keys.onLeftPressed: root.goBack()

                        Text {
                            visible: searchInput.text === "" && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (root.currentView === "categories") return "Rocket Desktop..."
                                if (root.currentView === "apps") return "Search applications..."
                                return "Search " + root.currentCategory + "..."
                            }
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            color: Common.Theme.text
                            opacity: 0.3
                        }
                    }

                    // View indicator
                    Text {
                        text: {
                            if (root.currentView === "categories") return ""
                            if (root.currentView === "apps") return root.filteredApps.length + " apps"
                            return root.currentCategory
                        }
                        font.family: Common.Theme.fontFamily
                        font.pixelSize: 11
                        color: Common.Theme.accent
                        opacity: 0.7
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Common.Theme.border
            }

            // Content area
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: {
                    if (root.currentView === "categories") return categoriesComponent
                    if (root.currentView === "apps") return appsComponent
                    return itemsComponent
                }
            }
        }
    }

    Component {
        id: categoriesComponent

        GridView {
            id: categoriesGrid
            cellWidth: (width - Common.Theme.gap) / 3
            cellHeight: 80
            model: root.categories
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
                width: categoriesGrid.cellWidth
                height: categoriesGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: catMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.1) : "transparent"

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
                                text: modelData.icon
                                font.pixelSize: 20
                                color: Common.Theme.accent
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.name
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSizeSmall
                            font.bold: true
                            color: Common.Theme.text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.desc
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: 10
                            color: Common.Theme.text
                            opacity: 0.5
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        id: catMouse
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
    }

    Component {
        id: itemsComponent

        ListView {
            id: itemsList
            spacing: 4
            model: root.getItemList()
            currentIndex: root.selectedIndex
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightHeight: height

            highlight: Rectangle {
                radius: 8
                color: Common.Theme.withAlpha(Common.Theme.accent, 0.12)
                border.color: Common.Theme.withAlpha(Common.Theme.accent, 0.3)
                border.width: 1

                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            delegate: Rectangle {
                width: itemsList.width
                height: 44
                radius: 8
                color: itemMouse.containsMouse ? Common.Theme.withAlpha(Common.Theme.accent, 0.1) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

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
                            text: modelData.name
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: Common.Theme.fontSize
                            font.bold: true
                            color: Common.Theme.text
                        }

                        Text {
                            text: modelData.command
                            font.family: Common.Theme.fontFamily
                            font.pixelSize: 10
                            color: Common.Theme.text
                            opacity: 0.5
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Text {
                        text: "\u25B6"
                        font.pixelSize: 12
                        color: Common.Theme.accent
                        opacity: 0.5
                    }
                }

                MouseArea {
                    id: itemMouse
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

    Component {
        id: appsComponent

        GridView {
            id: appsGrid
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
    }
}
