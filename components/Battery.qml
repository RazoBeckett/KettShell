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
    if (!ready) return "battery_android_question"
    if (charging) return "battery_android_bolt"
    if (critical) return "battery_android_alert"
    if (level >= 95) return "battery_android_full"
    if (level >= 85) return "battery_android_6"
    if (level >= 70) return "battery_android_5"
    if (level >= 55) return "battery_android_4"
    if (level >= 40) return "battery_android_3"
    if (level >= 25) return "battery_android_2"
    if (level >= 10) return "battery_android_1"
    return "battery_android_0"
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
      font.family: Config.materialSymbols.family
      font.pixelSize: Config.iconSize
    }

    Text {
      text: root.ready ? root.level + "%" : "-"
      color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
      font: Config.font
    }
  }
}
