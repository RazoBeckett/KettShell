import ".."
import QtQuick
import QtQuick.Layouts

PressableItem {
  id: root

  property string icon: ""
  property string label: ""
  property color iconColor: Colors.yellow
  property color labelColor: Colors.foreground
  property int maxLabelWidth: 220
  property bool showLabel: true

  implicitWidth: row.implicitWidth + 20
  implicitHeight: Config.pillHeight
  pressed: pressHandler.pressed

  TapHandler {
    id: pressHandler
    acceptedButtons: Qt.LeftButton | Qt.RightButton
  }

  Rectangle {
    anchors.fill: parent
    radius: Config.pillRadius
    color: Colors.card
    border.color: Colors.border
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: root.iconColor
        font.family: Config.materialSymbols.family
        font.pixelSize: Config.iconSize
        visible: root.icon !== ""
      }

      Text {
        text: root.label
        color: root.labelColor
        font: Config.font
        elide: Text.ElideRight
        Layout.maximumWidth: root.maxLabelWidth
        visible: root.showLabel && root.label !== ""
      }
    }
  }
}
