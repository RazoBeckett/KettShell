import ".."
import Quickshell.Networking
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor
  acceptedButtons: Qt.LeftButton | Qt.RightButton

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
  readonly property real signal: active ? active.signalStrength : 0
  readonly property bool wifiOn: Networking.wifiEnabled
  readonly property bool disconnected: wifiOn && !active
  readonly property string icon: {
    if (!wifiOn) return String.fromCodePoint(0xF05AA)
    if (!active) return String.fromCodePoint(0xF092D)
    let tier = signal >= 0.75 ? 4 : signal >= 0.50 ? 3 : signal >= 0.25 ? 2 : 1
    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }
  readonly property string label: {
    if (!wifiOn) return "OFF"
    if (active) return active.name
    return "Disconnected"
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
        color: root.disconnected ? Colors.waybarDisconnected : Colors.foreground
        font.family: Config.iconFont.family
        font.pixelSize: Config.iconSize
      }

      Text {
        text: root.label
        color: root.disconnected ? Colors.waybarDisconnected : Colors.foreground
        font: Config.font
        elide: Text.ElideRight
        Layout.maximumWidth: 140
      }
    }
  }

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) {
      BluetoothMenuState.visible = !BluetoothMenuState.visible
      if (BluetoothMenuState.visible) NetworkMenuState.visible = false
    } else if (mouse.button === Qt.LeftButton) {
      NetworkMenuState.visible = !NetworkMenuState.visible
      if (NetworkMenuState.visible) BluetoothMenuState.visible = false
    }
  }
}
