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

  property var shell: null
  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
  readonly property real signal: active ? active.signalStrength : 0
  readonly property bool wifiOn: Networking.wifiEnabled
  readonly property bool disconnected: wifiOn && !active
  readonly property string icon: {
    if (!wifiOn) return "signal_wifi_off"
    if (!active) return "signal_wifi_0_bar"
    let tier = signal >= 0.75 ? 4 : signal >= 0.50 ? 3 : signal >= 0.25 ? 2 : 1
    if (tier === 4) return "network_wifi"
    if (tier === 3) return "network_wifi_3_bar"
    if (tier === 2) return "network_wifi_2_bar"
    return "network_wifi_1_bar"
  }
  readonly property string label: {
    if (!wifiOn) return "OFF"
    if (active) return active.name
    return "Disconnected"
  }

  child: PressableItem {
    implicitWidth: row.implicitWidth + 26
    implicitHeight: 30
    pressed: root.pressed

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: root.disconnected ? Colors.waybarDisconnected : Colors.foreground
        font.family: Typography.materialSymbols.family
        font.pixelSize: 14
      }

      Text {
        text: root.label
        color: root.disconnected ? Colors.waybarDisconnected : Colors.foreground
        font: Typography.font
        elide: Text.ElideRight
        Layout.maximumWidth: 140
      }
    }
  }

  function togglePopout(kind) {
    if (root.shell && typeof root.shell.requestPopout === "function" && typeof root.shell.releasePopout === "function") {
      let active = typeof root.shell.isPopoutActive === "function" ? root.shell.isPopoutActive(kind, root) : false
      if (active) root.shell.releasePopout(kind, root)
      else root.shell.requestPopout(kind, root)
      return
    }

    if (kind === "bluetooth") {
      BluetoothMenuState.visible = !BluetoothMenuState.visible
      if (BluetoothMenuState.visible) NetworkMenuState.visible = false
    } else if (kind === "wifi") {
      NetworkMenuState.visible = !NetworkMenuState.visible
      if (NetworkMenuState.visible) BluetoothMenuState.visible = false
    }
  }

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) root.togglePopout("bluetooth")
    else if (mouse.button === Qt.LeftButton) root.togglePopout("wifi")
  }
}
