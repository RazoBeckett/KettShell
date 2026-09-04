import ".."
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "brightness"
  contentWidth: 360
  contentHeight: 108

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
  readonly property var presets: [1, 25, 50, 75, 100]
  readonly property int activePresetIndex: {
    if (!ready) return -1
    for (let i = 0; i < presets.length; i++) if (presets[i] === level) return i
    return -1
  }

  function setBrightnessFraction(f) {
    if (!root.ready) return
    let pct = Math.round(Math.max(0, Math.min(1, f)) * 100)
    pct = Math.max(1, Math.min(100, pct))
    Quickshell.execDetached(["brightnessctl", "set", pct + "%"])
  }

  function setBrightnessPct(pct) {
    if (!root.ready) return
    let clamped = Math.max(1, Math.min(100, Math.round(pct)))
    Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
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
    height: 108
    color: Colors.background
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 12
      anchors.bottomMargin: 10
      spacing: 12

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
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
              let step = (wheel.modifiers & Qt.AltModifier) ? 0.01 : 0.05
              if (wheel.angleDelta.y > 0) root.setBrightnessFraction(root.fraction + step)
              else if (wheel.angleDelta.y < 0) root.setBrightnessFraction(root.fraction - step)
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

      Item {
        id: presetContainer
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        Rectangle {
          id: presetHighlight
          visible: root.activePresetIndex >= 0
          width: (parent.width - 24) / 5
          height: 28
          x: root.activePresetIndex * (width + 6)
          color: Colors.card
          border.color: Colors.blue
          border.width: 1
          Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }

        RowLayout {
          anchors.fill: parent
          spacing: 6

          Repeater {
            model: root.presets
            delegate: Rectangle {
              required property var modelData
              required property int index
              readonly property bool isActive: root.ready && root.level === modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: 0
              color: (chipMa.containsMouse && !isActive) ? Colors.surface : Colors.transparent
              border.color: isActive ? Colors.transparent : Colors.border
              border.width: 1

            Text {
              anchors.centerIn: parent
              text: modelData + "%"
              color: isActive ? Colors.blue : (chipMa.containsMouse ? Colors.foreground : Colors.white)
              font.pixelSize: 12
              font.family: Config.font.family
            }

            MouseArea {
              id: chipMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.ready
              onClicked: root.setBrightnessPct(modelData)
            }
          }
        }
        }
      }
    }
  }
}
