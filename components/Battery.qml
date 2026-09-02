import ".."
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  implicitWidth: row.implicitWidth + Config.moduleHPadding * 2
  implicitHeight: Config.barHeight

  property var battery: UPower.displayDevice
  readonly property bool charging: battery ? battery.state === UPowerDeviceState.Charging : false
  readonly property bool ready: battery != null
  readonly property int level: ready ? Math.round(battery.percentage * 100) : 0
  readonly property bool critical: !charging && level <= 15
  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xF0083)
    if (charging) return String.fromCodePoint(0xF0084)
    if (level >= 100) return String.fromCodePoint(0xF0079)
    if (level < 10) return String.fromCodePoint(0xF0083)
    return String.fromCodePoint(0xF007A + (Math.floor(level / 10) - 1))
  }

  // waybar: critical blinks via animation, charging is green, else #eed5d9
  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: Config.moduleHMargin
    anchors.rightMargin: Config.moduleHMargin
    color: root.critical ? Colors.waybarCriticalBg : Colors.transparent
    visible: root.critical
    opacity: blink.running ? 1 : 0
  }

  SequentialAnimation {
    id: blink
    running: root.critical
    loops: Animation.Infinite
    NumberAnimation { target: root; property: "opacity"; from: 1; to: 0.6; duration: 250 }
    NumberAnimation { target: root; property: "opacity"; from: 0.6; to: 1; duration: 250 }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: root.icon
      color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
      font.family: Config.iconFont.family
      font.pixelSize: Config.iconSize
    }

    Text {
      text: root.ready ? root.level + "%" : "-"
      color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
      font: Config.font
    }
  }
}
