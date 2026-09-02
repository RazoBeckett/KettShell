pragma Singleton
import QtQuick

QtObject {
  readonly property int margin: 6
  readonly property int height: 30
  readonly property int barMargin: 0
  readonly property int barHeight: 30
  readonly property int barRadius: 0
  readonly property int pillHeight: 30
  readonly property int pillRadius: 0
  readonly property int groupSpacing: 4
  readonly property int moduleHPadding: 13
  readonly property int moduleHMargin: 3
  readonly property int iconSize: 14
  readonly property int spacing: 4

  readonly property font font: Qt.font({
    family: "SF Pro Text",
    pixelSize: 13,
    weight: Font.Bold
  })

  readonly property font iconFont: Qt.font({
    family: "JetBrainsMono Nerd Font Propo",
  })
}
