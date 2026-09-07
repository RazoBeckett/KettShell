pragma Singleton
import QtQuick

QtObject {
  readonly property font font: Qt.font({
    family: "SF Pro Text",
    pixelSize: 13,
    weight: Font.Bold
  })

  readonly property font icons: Qt.font({
    family: "Phosphor",
    pixelSize: 16,
    weight: Font.Normal
  })
}
