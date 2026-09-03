import ".."
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "volume"
  contentWidth: 360
  contentHeight: 64

  property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0
  readonly property string icon: {
    if (!ready) return "volume_off"
    if (muted || vol === 0) return "volume_off"
    if (vol < 34) return "volume_down"
    return "volume_up"
  }
  readonly property real fraction: ready ? (muted ? 0 : vol / 100) : 0

  function setVolumeFraction(f) {
    if (!root.ready) return
    let clamped = Math.max(0, Math.min(1, f))
    root.sink.audio.volume = clamped
    if (root.muted && clamped > 0) root.sink.audio.muted = false
  }

  function toggleMute() {
    if (!root.ready) return
    root.sink.audio.muted = !root.muted
  }

  PwObjectTracker {
    objects: [root.sink]
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

      Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        Text {
          id: iconText
          anchors.centerIn: parent
          text: root.icon
          color: iconMa.containsMouse ? Colors.blue : (root.muted ? Colors.white : Colors.foreground)
          font.family: Config.materialSymbols.family
          font.pixelSize: 18
        }
        MouseArea {
          id: iconMa
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: root.toggleMute()
        }
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
          color: root.muted ? Colors.white : Colors.blue
          opacity: root.ready ? 1 : 0.4
          Behavior on width { NumberAnimation { duration: 40; easing.type: Easing.Linear } }
        }

        Rectangle {
          id: thumb
          width: sliderRoot.thumbSize
          height: sliderRoot.thumbSize
          radius: sliderRoot.thumbSize / 2
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
            root.setVolumeFraction(f)
          }
          onPressed: mouse => updateFromMouse(mouse)
          onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse) }
          onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.setVolumeFraction(root.fraction + 0.05)
            else if (wheel.angleDelta.y < 0) root.setVolumeFraction(root.fraction - 0.05)
          }
        }
      }

      Text {
        text: {
          if (!root.ready) return "-"
          if (root.muted) return "0%"
          return root.vol + "%"
        }
        color: Colors.white
        font.pixelSize: 12
        font.family: Config.font.family
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
