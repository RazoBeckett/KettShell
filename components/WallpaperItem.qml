import ".."
import QtQuick

Item {
  id: root

  required property string modelData
  required property bool isCurrent

  property string fileName: {
    let p = modelData
    let i = p.lastIndexOf("/")
    return i >= 0 ? p.slice(i + 1) : p
  }

  /*
   * The thumbnail itself is exactly 300px wide.
   *
   * There is no extra horizontal "chrome" around it.
   * The Row in WallpaperPicker controls the gap.
   */
  implicitWidth: thumb.width
  implicitHeight:
    thumb.height +
    label.implicitHeight +
    8

  width: implicitWidth
  height: implicitHeight

  opacity: 1

  /*
   * Only a very subtle difference between the current
   * wallpaper and the other items.
   *
   * Do not use PathView for positioning or animation.
   */
  scale: root.isCurrent ? 1.0 : 0.96

  Behavior on scale {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: 160
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: thumb

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    width: 300
    height: 300 / 16 * 9

    radius: 10

    color: Colors.surface

    border.color:
      root.isCurrent
        ? Colors.border
        : "transparent"

    border.width:
      root.isCurrent ? 1.2 : 0

    clip: true

    Text {
      anchors.centerIn: parent

      text: "image"

      color: Colors.white
      opacity: 0.25

      font.family: Config.materialSymbols.family
      font.pixelSize: 28

      visible:
        thumbImage.status !== Image.Ready
    }

    Image {
      id: thumbImage

      anchors.fill: parent

      source:
        root.modelData &&
        root.modelData.length > 1
          ? "file://" + root.modelData
          : ""

      fillMode: Image.PreserveAspectCrop

      asynchronous: true
      cache: true
      smooth: true
      mipmap: true

      onStatusChanged: {
        if (status === Image.Error) {
          console.log(
            "WallpaperItem failed:",
            root.modelData,
            "->",
            source
          )
        }
      }
    }
  }

  Text {
    id: label

    anchors.top: thumb.bottom
    anchors.topMargin: 4

    anchors.horizontalCenter: parent.horizontalCenter

    width: thumb.width - 8

    horizontalAlignment: Text.AlignHCenter

    elide: Text.ElideMiddle
    maximumLineCount: 1

    text: root.fileName

    color:
      root.isCurrent
        ? Colors.foreground
        : Colors.white

    font.family: Config.font.family
    font.pixelSize: 10
    font.weight: Config.font.weight

    opacity:
      root.isCurrent
        ? 1
        : 0.8
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  signal clicked()
}
