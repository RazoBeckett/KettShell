pragma Singleton
import ".."
import QtQuick

QtObject {
  readonly property real rootSize: Settings.ui.fontScale
  readonly property real sizeXS: rootSize * 0.85
  readonly property real sizeSM: rootSize
  readonly property real sizeMD: rootSize * 1.15
  readonly property real sizeLG: rootSize * 1.4

  readonly property font sans: Qt.font({
    family: Settings.ui.fontFamily,
    pixelSize: sizeSM,
    weight: Font.Normal
  })
  readonly property font mono: Qt.font({
    family: Settings.ui.monoFamily,
    pixelSize: sizeSM,
    weight: Font.Normal
  })
  readonly property font icons: Qt.font({
    family: "Phosphor",
    pixelSize: 16,
    weight: Font.Normal
  })
}
