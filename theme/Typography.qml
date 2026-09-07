pragma Singleton
import ".."
import QtQuick

QtObject {
  readonly property font font: Qt.font({
    family: Settings.ui.fontFamily,
    pixelSize: 13,
    weight: Font.Bold
  })

  readonly property font icons: Qt.font({
    family: "Phosphor",
    pixelSize: 16,
    weight: Font.Normal
  })
}
