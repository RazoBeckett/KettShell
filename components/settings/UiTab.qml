import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  spacing: 4

  SettingsRow {
    title: "Genie animation"
    subtitle: "Distort popups as they open and close"
    Layout.fillWidth: true

    Rectangle {
      anchors.fill: parent
      color: Colors.transparent

      Rectangle {
        id: track
        width: 46
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        color: Settings.ui.genie ? Colors.blue : Colors.surface
        border.color: Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
          width: 16
          height: 16
          anchors.verticalCenter: parent.verticalCenter
          x: Settings.ui.genie ? track.width - width - 4 : 4
          color: Settings.ui.genie ? Colors.black : Colors.foreground
          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Settings.ui.genie = !Settings.ui.genie
        }
      }
    }
  }
}
