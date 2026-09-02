import ".."
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Bluetooth flyout — mirrors WifiPanel layout and styling
PanelWindow {
  id: root
  anchors {
    top: true
    right: true
  }
  margins.top: Config.height + Config.margin
  margins.right: Config.margin
  implicitWidth: 360
  implicitHeight: 460
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  color: Colors.transparent
  visible: BluetoothMenuState.visible
  focusable: BluetoothMenuState.visible

  property var adapter: Bluetooth.defaultAdapter
  readonly property bool bluetoothOn: adapter ? adapter.enabled : false
  readonly property bool discovering: adapter ? adapter.discovering : false
  property var expandedDevice: null

  readonly property var allDevices: {
    if (!adapter || !adapter.devices) return []
    return [...adapter.devices.values]
  }
  readonly property var connectedDevices: allDevices.filter(d => d.connected)
  readonly property var availableDevices: {
    if (!adapter || !adapter.devices) return []
    let all = [...adapter.devices.values].filter(d => !d.connected)
    all.sort((a, b) => {
      if (a.paired !== b.paired) return b.paired - a.paired
      if (a.bonded !== b.bonded) return b.bonded - a.bonded
      let an = (a.name || a.deviceName || a.address || "").toLowerCase()
      let bn = (b.name || b.deviceName || b.address || "").toLowerCase()
      return an.localeCompare(bn)
    })
    return all
  }

  onVisibleChanged: {
    if (visible) NetworkMenuState.visible = false
    if (visible && bluetoothOn && adapter && !adapter.discovering) adapter.discovering = true
    if (!visible) expandedDevice = null
  }

  Timer {
    interval: 4000
    running: root.visible && root.bluetoothOn && root.adapter !== null
    repeat: true
    onTriggered: if (root.adapter && !root.adapter.discovering) root.adapter.discovering = true
  }

  Shortcut {
    sequence: "Escape"
    onActivated: BluetoothMenuState.visible = false
  }

  function deviceIcon(device) {
    if (!device) return String.fromCodePoint(0xF00AF)
    let icon = (device.icon || "").toLowerCase()
    if (icon.includes("headset") || icon.includes("headphone")) return String.fromCodePoint(0xF02CB)
    if (icon.includes("speaker")) return String.fromCodePoint(0xF04C3)
    if (icon.includes("audio")) return String.fromCodePoint(0xF00B0)
    if (icon.includes("keyboard")) return String.fromCodePoint(0xF030C)
    if (icon.includes("mouse")) return String.fromCodePoint(0xF037D)
    return String.fromCodePoint(0xF00AF)
  }

  function statusText(device) {
    if (!device) return ""
    if (device.pairing || device.state === BluetoothDeviceState.Connecting) return "Connecting..."
    if (device.connected) {
      if (device.batteryAvailable) return "Connected \u00b7 " + Math.round(device.battery * 100) + "%"
      return "Connected"
    }
    if (device.paired) return "Paired"
    return "Not paired"
  }

  function handleDeviceClick(device) {
    if (!device) return
    if (device.connected) {
      device.disconnect()
      expandedDevice = null
      return
    }
    if (!device.paired) {
      device.pair()
      return
    }
    device.connect()
  }

  // outside click to close — behind bg so it does not block bg input
  MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: BluetoothMenuState.visible = false
  }

  Rectangle {
    id: bg
    width: 360
    height: 460
    color: Colors.background
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      // header with Bluetooth toggle top right
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 8

        Text {
          text: "Bluetooth"
          color: Colors.foreground
          font.pixelSize: 14
          font.family: Config.font.family
          font.weight: Font.Normal
        }
        Item { Layout.fillWidth: true }

        Text {
          visible: root.bluetoothOn && root.discovering
          text: "Scanning..."
          color: Colors.white
          font.pixelSize: 11
          font.family: Config.font.family
        }

        // toggle switch — win10 style
        Item {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 24
          enabled: root.adapter !== null
          opacity: root.adapter !== null ? 1.0 : 0.45

          Rectangle {
            id: track
            anchors.fill: parent
            radius: 0
            color: root.bluetoothOn ? Colors.blue : Colors.card
            border.color: toggleMa.containsMouse ? Colors.border : Colors.transparent
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
          }
          Rectangle {
            id: thumb
            width: 18
            height: 18
            radius: 0
            color: Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
            x: root.bluetoothOn ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          }
          MouseArea {
            id: toggleMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Colors.border
      }

      // scrollable list area — fixed height so outer panel never resizes
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        // No adapter placeholder
        ColumnLayout {
          visible: root.adapter === null
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 24
          spacing: 12

          RowLayout {
            spacing: 12
            Layout.fillWidth: true
            Text {
              text: String.fromCodePoint(0xF00BF)
              color: Colors.white
              font.family: Config.iconFont.family
              font.pixelSize: 22
            }
            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text { text: "No Bluetooth adapter found"; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family }
              Text { text: "Bluetooth hardware not detected"; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
            }
          }
        }

        // Bluetooth off placeholder
        ColumnLayout {
          visible: root.adapter !== null && !root.bluetoothOn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 24
          spacing: 12

          RowLayout {
            spacing: 12
            Layout.fillWidth: true
            Text {
              text: String.fromCodePoint(0xF00B2)
              color: Colors.white
              font.family: Config.iconFont.family
              font.pixelSize: 22
            }
            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text { text: "Bluetooth is turned off"; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family }
              Text { text: "Turn on to see available devices"; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
            }
          }
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: Colors.blue
            Text { anchors.centerIn: parent; text: "Turn Bluetooth back on"; color: Colors.black; font.pixelSize: 13; font.family: Config.font.family }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onEntered: parent.color = Qt.lighter(Colors.blue, 1.08)
              onExited: parent.color = Colors.blue
              onClicked: if (root.adapter) root.adapter.enabled = true
            }
          }
        }

        // devices scroll
        Flickable {
          id: flick
          visible: root.adapter !== null && root.bluetoothOn
          anchors.fill: parent
          contentHeight: contentCol.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: contentCol
            width: flick.width
            spacing: 0

            // connected section
            ColumnLayout {
              visible: root.connectedDevices.length > 0
              Layout.fillWidth: true
              spacing: 0

              Text {
                visible: root.availableDevices.length > 0
                text: "Connected devices"
                color: Colors.white
                font.pixelSize: 11
                font.family: Config.font.family
                Layout.leftMargin: 16
                Layout.topMargin: 8
                Layout.bottomMargin: 4
              }

              Repeater {
                model: root.connectedDevices

                delegate: Rectangle {
                  id: connRow
                  required property var modelData
                  required property int index
                  Layout.fillWidth: true
                  Layout.preferredHeight: root.expandedDevice === modelData ? 100 : 62
                  color: connHeaderMa.containsMouse ? Colors.surface : (root.expandedDevice === modelData ? Colors.card : Colors.transparent)
                  clip: true
                  Behavior on color { ColorAnimation { duration: 90 } }

                  ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 62
                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12
                        Text { text: root.deviceIcon(connRow.modelData); color: Colors.foreground; font.family: Config.iconFont.family; font.pixelSize: 20 }
                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1
                          Text { text: connRow.modelData.name || connRow.modelData.deviceName || connRow.modelData.address; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                          Text { text: root.statusText(connRow.modelData); color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                        }
                      }
                      MouseArea {
                        id: connHeaderMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: 0
                        onClicked: {
                          if (root.expandedDevice === connRow.modelData) root.expandedDevice = null
                          else root.expandedDevice = connRow.modelData
                        }
                      }
                    }

                    RowLayout {
                      visible: root.expandedDevice === connRow.modelData
                      Layout.fillWidth: true
                      Layout.leftMargin: 48
                      Layout.rightMargin: 12
                      Layout.bottomMargin: 10
                      spacing: 8
                      z: 1
                      Rectangle {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 28
                        color: discMa.containsMouse ? Colors.surface : Colors.card
                        border.color: Colors.border
                        border.width: 1
                        Text { anchors.centerIn: parent; text: "Disconnect"; color: Colors.foreground; font.pixelSize: 12; font.family: Config.font.family }
                        MouseArea { id: discMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.handleDeviceClick(connRow.modelData) }
                      }
                      Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 28
                        color: forgetConnMa.containsMouse ? Colors.surface : Colors.card
                        border.color: Colors.border
                        border.width: 1
                        Text { anchors.centerIn: parent; text: "Forget"; color: Colors.foreground; font.pixelSize: 12; font.family: Config.font.family }
                        MouseArea { id: forgetConnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { connRow.modelData.forget(); root.expandedDevice = null } }
                      }
                      Item { Layout.fillWidth: true }
                      Text { visible: connRow.modelData ? connRow.modelData.address.length > 0 : false; text: connRow.modelData ? connRow.modelData.address : ""; color: Colors.white; font.pixelSize: 10; font.family: Config.font.family; elide: Text.ElideRight; Layout.maximumWidth: 110 }
                    }
                  }

                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Colors.border
                  }
                }
              }

              Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Colors.border; visible: root.availableDevices.length > 0 }
            }

            // available rows
            Repeater {
              model: root.bluetoothOn ? root.availableDevices.slice(0, 20) : []

              delegate: Rectangle {
                id: availRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: root.expandedDevice === modelData ? 100 : 62
                color: availHeaderMa.containsMouse ? Colors.surface : (root.expandedDevice === modelData ? Colors.card : Colors.transparent)
                clip: true
                Behavior on color { ColorAnimation { duration: 90 } }

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  height: 1
                  color: Colors.border
                }

                ColumnLayout {
                  anchors.fill: parent
                  spacing: 0

                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      Text { text: root.deviceIcon(availRow.modelData); color: Colors.foreground; font.family: Config.iconFont.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: availRow.modelData.name || availRow.modelData.deviceName || availRow.modelData.address; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: availRow.modelData === null ? "" : root.statusText(availRow.modelData); color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                      }
                      Text {
                        visible: availRow.modelData ? availRow.modelData.paired : false
                        text: String.fromCodePoint(0xF033E)
                        color: Colors.white
                        font.family: Config.iconFont.family
                        font.pixelSize: 12
                      }
                    }
                    MouseArea {
                      id: availHeaderMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      z: 0
                      onClicked: {
                        if (root.expandedDevice === availRow.modelData) root.expandedDevice = null
                        else root.expandedDevice = availRow.modelData
                      }
                    }
                  }

                  RowLayout {
                    visible: root.expandedDevice === availRow.modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 10
                    spacing: 8
                    z: 1

                    Text {
                      text: availRow.modelData ? availRow.modelData.address : ""
                      color: Colors.white
                      font.pixelSize: 10
                      font.family: Config.font.family
                      elide: Text.ElideRight
                      Layout.maximumWidth: 120
                      Layout.fillWidth: true
                    }

                    Rectangle {
                      visible: availRow.modelData ? availRow.modelData.paired : false
                      Layout.preferredWidth: 72
                      Layout.preferredHeight: 28
                      color: forgetMa.containsMouse ? Colors.surface : Colors.card
                      border.color: Colors.border
                      border.width: 1
                      Text { anchors.centerIn: parent; text: "Forget"; color: Colors.foreground; font.pixelSize: 12; font.family: Config.font.family }
                      MouseArea { id: forgetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { availRow.modelData.forget(); root.expandedDevice = null } }
                    }

                    Rectangle {
                      Layout.preferredWidth: 72
                      Layout.preferredHeight: 28
                      color: connMa.containsMouse ? Qt.lighter(Colors.blue, 1.08) : Colors.blue
                      visible: availRow.modelData ? !availRow.modelData.pairing && availRow.modelData.state !== BluetoothDeviceState.Connecting : true
                      Text {
                        anchors.centerIn: parent
                        text: availRow.modelData ? (availRow.modelData.paired ? "Connect" : "Pair") : "Connect"
                        color: Colors.black
                        font.pixelSize: 12
                        font.family: Config.font.family
                      }
                      MouseArea {
                        id: connMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleDeviceClick(availRow.modelData)
                      }
                    }
                    Text { visible: availRow.modelData ? (availRow.modelData.pairing || availRow.modelData.state === BluetoothDeviceState.Connecting) : false; text: "Connecting..."; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                  }
                }
              }
            }

            // empty state
            Text {
              visible: root.availableDevices.length === 0 && root.connectedDevices.length === 0
              Layout.alignment: Qt.AlignHCenter
              Layout.topMargin: 24
              text: root.discovering ? "Scanning for devices..." : "No Bluetooth devices found"
              color: Colors.white
              font.pixelSize: 12
              font.family: Config.font.family
            }
          }
        }
      }
    }
  }
}
