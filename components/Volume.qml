import ".."
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.NoButton
  hoverEnabled: true

  property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0
  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xF0581)
    if (muted) return String.fromCodePoint(0xF0E08)
    if (vol === 0) return String.fromCodePoint(0xF0E08)
    if (vol < 34) return String.fromCodePoint(0xF057F)
    if (vol < 67) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }

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
        text: {
          if (!root.ready) return "-"
          if (root.muted) return "00%"
          return root.vol + "%"
        }
        color: Colors.foreground
        font: Config.font
      }
    }
  }

  function adjustVolume(delta) {
    if (!root.ready) return
    var next = Math.min(1.0, Math.max(0.0, root.sink.audio.volume + delta / 100))
    root.sink.audio.volume = next
  }

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustVolume(1)
    else if (wheel.angleDelta.y < 0) root.adjustVolume(-1)
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
