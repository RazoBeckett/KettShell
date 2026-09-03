import ".."
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "brightness"
  contentWidth: 360
  contentHeight: 64

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
  readonly property real fraction: ready ? level / 100 : 0

  function setBrightnessFraction(f) {
    if (!root.ready) return
    let pct = Math.round(Math.max(0, Math.min(1, f)) * 100)
    Quickshell.execDetached(["brightnessctl", "set", pct + "%"])
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

  Rectangle {
    id: bg
    width: 360
    height: 64
    color: Colors.background
    border.color: Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      spacing: 12

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Config.materialSymbols.family
        font.pixelSize: 18
        Layout.preferredWidth: 22
      }

      Item {
        id: sliderRoot
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        readonly property int trackHeight: 4
        readonly property int thumbSize: 16

        Rectangle {
          id: trackBg
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: sliderRoot.trackHeight
          radius: 0
          color: Colors.card
        }

        Rectangle {
          id: trackFill
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          width: Math.round(parent.width * root.fraction)
          height: sliderRoot.trackHeight
          radius: 0
          color: Colors.blue
          opacity: root.ready ? 1 : 0.4
          Behavior on width { NumberAnimation { duration: 40; easing.type: Easing.Linear } }
        }

        Rectangle {
          id: thumb
          width: sliderRoot.thumbSize
          height: sliderRoot.thumbSize
          radius: width / 2
          color: thumbMa.containsMouse || thumbMa.pressed ? Colors.blue : Colors.foreground
          border.color: thumbMa.pressed ? Colors.foreground : Colors.transparent
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter
          x: Math.max(0, Math.min(parent.width - width, Math.round(trackFill.width - width / 2)))
          opacity: root.ready ? 1 : 0.4
          Behavior on color { ColorAnimation { duration: 90 } }
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Colors.black
            border.width: 1
            opacity: 0.15
            z: -1
          }
        }

        MouseArea {
          id: thumbMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          preventStealing: true
          enabled: root.ready
          function updateFromMouse(mouse) {
            let f = mouse.x / sliderRoot.width
            root.setBrightnessFraction(f)
          }
          onPressed: mouse => updateFromMouse(mouse)
          onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse) }
          onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.setBrightnessFraction(root.fraction + 0.05)
            else if (wheel.angleDelta.y < 0) root.setBrightnessFraction(root.fraction - 0.05)
          }
        }
      }

      Text {
        text: root.ready ? root.level + "%" : "-"
        color: Colors.white
        font.pixelSize: 12
        font.family: Config.font.family
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
