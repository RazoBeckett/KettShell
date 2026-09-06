import "../.."
import QtQuick
import QtQuick.Layouts

/*
 * One settings row: title plus subtitle on the left, caller-supplied
 * control in a fixed-width box on the right.
 */
Rectangle {
  id: root

  property string title: ""
  property string subtitle: ""

  default property alias control: controlBox.data

  color: Colors.transparent
  implicitHeight: 60

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 2
    anchors.rightMargin: 2
    spacing: 12

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: root.title
        color: Colors.foreground
        font: Config.font
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: root.subtitle
        color: Colors.white
        font: Config.font
        elide: Text.ElideRight
        visible: root.subtitle !== ""
        Layout.fillWidth: true
      }
    }

    RowLayout {
      id: controlBox
      Layout.preferredWidth: 240
      Layout.fillHeight: true
      layoutDirection: Qt.RightToLeft
      spacing: 8
    }
  }
}
