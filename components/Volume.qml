import ".."
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null

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
        font.family: Config.materialSymbols.family
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

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("volume", root)
  }

  onClicked: root.togglePopout()

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustVolume(5)
    else if (wheel.angleDelta.y < 0) root.adjustVolume(-5)
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
