import QtQuick 2.15
import QtQuick.Window 2.15
import "../common" as Common

Item {
    id: root

    property string imagePath: ""
    property string scalingMode: "fill"

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: root.imagePath ? "file://" + root.imagePath : ""
        fillMode: {
            switch (root.scalingMode) {
                case "fit": return Image.PreserveAspectFit;
                case "fill": return Image.PreserveAspectCrop;
                case "stretch": return Image.Stretch;
                case "center": return Image.AlignHCenter | Image.AlignVCenter;
                case "tile": return Image.Tile;
                default: return Image.PreserveAspectCrop;
            }
        }
        visible: root.imagePath !== ""
    }

    Rectangle {
        anchors.fill: parent
        color: Common.Theme.background
        visible: !root.imagePath || root.imagePath === ""
    }
}
