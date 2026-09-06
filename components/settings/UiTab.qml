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
      Layout.preferredWidth: 44
      Layout.preferredHeight: 24
      Layout.alignment: Qt.AlignVCenter
      color: Colors.transparent
      border.color: Colors.border
      border.width: 1

      Toggle {
        anchors.fill: parent
        checked: Settings.ui.genie
        onToggled: c => Settings.ui.genie = c
      }
    }
  }
}
