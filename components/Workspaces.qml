import ".."
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 0

  readonly property var sortedWorkspaces: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)

  Repeater {
    model: root.sortedWorkspaces

    Item {
      id: wsButton
      required property var modelData
      property var ws: modelData
      property bool isActive: Hyprland.focusedWorkspace?.id === ws.id
      property bool isHovered: ma.containsMouse

      implicitWidth: label.implicitWidth + 18
      implicitHeight: Config.barHeight

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.ws.id
        color: wsButton.isActive ? Colors.waybarActive : Colors.foreground
        font: Config.font
        // waybar active has transition 0.3s cubic
        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: [0.55, -0.68, 0.48, 1.682] } }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: Colors.foreground
        visible: wsButton.isHovered && !wsButton.isActive
        opacity: wsButton.isHovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.waybarHover
        opacity: wsButton.isHovered ? 1 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${wsButton.ws.id} })`])
      }
    }
  }
}
