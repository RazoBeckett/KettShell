import "components"
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  NetworkHub {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Config.barHeight
      color: Colors.transparent

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 0

        // Left: workspaces + window title placeholder
        Workspaces {}

        Item { Layout.fillWidth: true }

        // Right: waybar-style flat modules, spacing 4 like waybar
        RowLayout {
          spacing: Config.spacing

          Brightness {}
          Volume {}
          Network {}
          Battery {}
          Clock {}
        }
      }
    }
  }
}
