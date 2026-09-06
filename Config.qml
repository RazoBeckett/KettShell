pragma Singleton
import QtQuick

QtObject {
  readonly property font font: Qt.font({
    family: "SF Pro Text",
    pixelSize: 13,
    weight: Font.Bold
  })

  readonly property font materialSymbols: Qt.font({
    family: "Material Symbols Rounded",
    pixelSize: 16,
    weight: Font.Normal
  })


  readonly property font iconFont: Qt.font({
    family: "JetBrainsMono Nerd Font Propo",
  })
}
