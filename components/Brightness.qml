import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.NoButton
  hoverEnabled: true

  property string device: "intel_backlight"
  readonly property string dir: `/sys/class/backlight/${device}`
  readonly property bool ready: brightness.loaded && maxBrightness.loaded
  readonly property real raw: brightness.loaded ? parseFloat(brightness.text()) : 0
  readonly property real max: maxBrightness.loaded ? parseFloat(maxBrightness.text()) : 1
  readonly property int level: ready ? Math.round((raw / max) * 100) : 0
  readonly property int moonIndex: Math.min(14, Math.max(0, Math.round((root.level / 100) * 14)))
  readonly property string icon: String.fromCodePoint(0xe38d + root.moonIndex)

  child: Item {
    implicitWidth: row.implicitWidth + Config.moduleHPadding * 2
    implicitHeight: Config.barHeight

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Config.iconFont.family
        font.pixelSize: Config.iconSize
      }

      Text {
        text: root.ready ? root.level + "%" : "-"
        color: Colors.foreground
        font: Config.font
      }
    }
  }

  function adjustBrightness(delta) {
    if (!root.ready) return
    var sign = delta >= 0 ? "+" : "-"
    Quickshell.execDetached(["brightnessctl", "set", `${Math.abs(delta)}%${sign}`])
  }

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustBrightness(1)
    else if (wheel.angleDelta.y < 0) root.adjustBrightness(-1)
  }

  FileView {
    id: brightness
    path: `${root.dir}/brightness`
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: maxBrightness
    path: `${root.dir}/max_brightness`
  }
}
