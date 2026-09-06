import ".."
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null

  property var battery: UPower.displayDevice
  readonly property bool charging: battery ? battery.state === UPowerDeviceState.Charging : false
  readonly property bool ready: battery != null
  readonly property int level: ready ? Math.round(battery.percentage * 100) : 0
  readonly property bool critical: !charging && level <= 15
  readonly property string icon: {
    if (!ready) return "battery_android_question"
    if (charging) return level < 30 ? "battery_android_bolt" : "battery_android_frame_bolt"
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

  SequentialAnimation {
    id: blink
    running: root.critical
    loops: Animation.Infinite
    NumberAnimation { target: blinkTarget; property: "opacity"; from: 1; to: 0.6; duration: 250 }
    NumberAnimation { target: blinkTarget; property: "opacity"; from: 0.6; to: 1; duration: 250 }
  }

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("battery", root)
  }

  onClicked: root.togglePopout()

  child: PressableItem {
    id: blinkTarget
    implicitWidth: row.implicitWidth + 26
    implicitHeight: 30
    pressed: root.pressed
    dimOnPress: !root.critical

    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 3
      anchors.rightMargin: 3
      color: root.critical ? Colors.waybarCriticalBg : Colors.transparent
      visible: root.critical
    }

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
        font.family: Typography.materialSymbols.family
        font.pixelSize: 14
      }

      Text {
        text: root.ready ? root.level + "%" : "-"
        color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
        font: Typography.font
      }
    }
  }
}
