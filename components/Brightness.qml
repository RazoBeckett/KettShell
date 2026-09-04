import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null

  property string device: "intel_backlight"
  readonly property string dir: `/sys/class/backlight/${device}`
  readonly property bool ready: brightness.loaded && maxBrightness.loaded
  readonly property real raw: brightness.loaded ? parseFloat(brightness.text()) : 0
  readonly property real max: maxBrightness.loaded ? parseFloat(maxBrightness.text()) : 1
  readonly property int level: ready ? Math.round((raw / max) * 100) : 0
  readonly property string icon: {
    if (!ready) return "brightness_4"
    if (level <= 14) return "brightness_1"
    if (level <= 28) return "brightness_2"
    if (level <= 42) return "brightness_3"
    if (level <= 57) return "brightness_4"
    if (level <= 71) return "brightness_5"
    if (level <= 85) return "brightness_6"
    return "brightness_7"
  }

  child: PressableItem {
    implicitWidth: row.implicitWidth + Config.moduleHPadding * 2
    implicitHeight: Config.barHeight
    pressed: root.pressed

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Config.materialSymbols.family
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

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("brightness", root)
  }

  onClicked: root.togglePopout()

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustBrightness(5)
    else if (wheel.angleDelta.y < 0) root.adjustBrightness(-5)
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
