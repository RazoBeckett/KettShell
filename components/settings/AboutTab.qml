import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  spacing: 4

  SettingsRow {
    title: "kettshell"
    subtitle: "A Quickshell setup"
    Layout.fillWidth: true
  }

  SettingsRow {
    title: "Preferences"
    subtitle: "kettshell.json"
    Layout.fillWidth: true
  }

  SettingsRow {
    title: "Theme"
    subtitle: "Typography.qml and Colors.qml"
    Layout.fillWidth: true
  }
}
