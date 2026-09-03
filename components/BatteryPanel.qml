import ".."
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "battery"
  contentWidth: 360
  contentHeight: 92

  readonly property var battery: UPower.displayDevice
  readonly property bool ready: battery != null && battery.isPresent
  readonly property bool isCharging: ready && battery.state === UPowerDeviceState.Charging
  readonly property bool isDischarging: ready && battery.state === UPowerDeviceState.Discharging
  readonly property bool isFullyCharged: ready && battery.state === UPowerDeviceState.FullyCharged
  readonly property bool isPendingCharge: ready && battery.state === UPowerDeviceState.PendingCharge
  readonly property bool isEmpty: ready && battery.state === UPowerDeviceState.Empty
  readonly property int level: ready ? Math.round(battery.percentage * 100) : 0
  readonly property real fraction: ready ? Math.max(0, Math.min(1, battery.percentage)) : 0
  readonly property double rawTimeToEmpty: ready ? Number(battery.timeToEmpty) : 0
  readonly property double rawTimeToFull: ready ? Number(battery.timeToFull) : 0

  function normalizeSeconds(v) {
    if (!v || isNaN(v) || v <= 0) return 0
    // UPower reports seconds; if value looks like hours fraction (< 200) treat as hours
    if (v < 300) return v * 3600
    return v
  }

  function formatDuration(seconds) {
    let s = normalizeSeconds(seconds)
    if (s <= 0) return ""
    let h = Math.floor(s / 3600)
    let m = Math.floor((s % 3600) / 60)
    if (h > 0 && m > 0) return h + " hour" + (h !== 1 ? "s" : "") + " " + m + " minute" + (m !== 1 ? "s" : "")
    if (h > 0) return h + " hour" + (h !== 1 ? "s" : "")
    if (m > 0) return m + " minute" + (m !== 1 ? "s" : "")
    return "less than a minute"
  }

  readonly property string timeToEmptyLabel: formatDuration(rawTimeToEmpty)
  readonly property string timeToFullLabel: formatDuration(rawTimeToFull)

  readonly property string statusLine1: {
    if (!ready) return "No battery"
    if (isFullyCharged) return "Fully charged"
    if (isPendingCharge) return "Plugged in"
    if (isCharging) {
      if (timeToFullLabel !== "") return timeToFullLabel
      return "Charging"
    }
    if (isDischarging) {
      if (timeToEmptyLabel !== "") return timeToEmptyLabel
      return "On battery"
    }
    if (isEmpty) return "Empty"
    return UPowerDeviceState.toString(battery.state)
  }

  readonly property string statusLine2: {
    if (!ready) return ""
    if (isFullyCharged) return ""
    if (isPendingCharge) return "not charging"
    if (isCharging) {
      if (timeToFullLabel !== "") return "until full"
      return ""
    }
    if (isDischarging) {
      if (timeToEmptyLabel !== "") return "remaining"
      return ""
    }
    return ""
  }

  readonly property string chargingIcon: level < 30 ? "battery_android_bolt" : "battery_android_frame_bolt"

  Rectangle {
    id: bg
    width: 360
    height: 92
    color: Colors.background
    border.color: Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 14
      anchors.bottomMargin: 14
      spacing: 10

      // Battery icon — Win10 style. Pending shows Power icon.
      // Charging shows single Material icon: bolt (<30) or frame_bolt (>=30).
      // Otherwise shows outline with fill.
      Item {
        id: batteryIconRoot
        Layout.preferredWidth: 36
        Layout.preferredHeight: 28
        Layout.alignment: Qt.AlignVCenter

        Text {
          id: powerIcon
          visible: root.isPendingCharge
          anchors.centerIn: parent
          text: "power"
          color: Colors.foreground
          font.family: Config.materialSymbols.family
          font.pixelSize: 28
        }

        Text {
          id: chargingIcon
          visible: root.isCharging
          anchors.centerIn: parent
          text: root.chargingIcon
          color: Colors.foreground
          font.family: Config.materialSymbols.family
          font.pixelSize: 28
        }

        Text {
          id: fullIcon
          visible: root.isFullyCharged
          anchors.centerIn: parent
          text: "battery_android_full"
          color: Colors.foreground
          font.family: Config.materialSymbols.family
          font.pixelSize: 28
        }

        Item {
          visible: !root.isPendingCharge && !root.isCharging && !root.isFullyCharged
          anchors.centerIn: parent
          width: 40
          height: 22

          Rectangle {
            id: outline
            anchors.fill: parent
            anchors.rightMargin: 3
            radius: 2
            color: "transparent"
            border.color: Colors.foreground
            border.width: 1.6

            Rectangle {
              id: fill
              anchors.left: parent.left
              anchors.leftMargin: 2
              anchors.verticalCenter: parent.verticalCenter
              height: parent.height - 4
              width: Math.max(0, Math.round((parent.width - 4) * root.fraction))
              radius: 1
              color: root.level <= 15 && !root.isFullyCharged ? Colors.waybarCriticalBg : Colors.foreground
              visible: root.ready && root.level > 0
            }
          }

          Rectangle {
            id: nub
            width: 3
            height: 10
            radius: 1
            color: Colors.foreground
            anchors.left: outline.right
            anchors.leftMargin: -1
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      // Percentage — large thin number like Win10
      Text {
        id: percentText
        text: root.ready ? root.level + "%" : "--"
        color: Colors.foreground
        font.family: Config.font.family
        font.pixelSize: 32
        font.weight: Font.Light
        font.letterSpacing: -0.5
        Layout.alignment: Qt.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
      }

      // Status text — two lines: duration + suffix (remaining / until full), right-aligned
      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        Text {
          id: line1
          text: root.statusLine1
          color: root.isFullyCharged ? Colors.white : Colors.foreground
          font.family: Config.font.family
          font.pixelSize: 13
          font.weight: Font.Normal
          elide: Text.ElideRight
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          opacity: root.ready ? 0.92 : 0.5
        }

        Text {
          id: line2
          text: root.statusLine2
          color: Colors.white
          font.family: Config.font.family
          font.pixelSize: 13
          font.weight: Font.Normal
          elide: Text.ElideRight
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          visible: text !== ""
          opacity: 0.72
        }
      }
    }
  }
}
