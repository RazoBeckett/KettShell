import ".."
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "bluetooth"
  contentWidth: 360
  contentHeight: 460

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

  onOpenChanged: {
    if (open && bluetoothOn && adapter && !adapter.discovering) adapter.discovering = true
    if (!open) expandedDevice = null
  }

  Timer {
    interval: 4000
    running: root.open && root.bluetoothOn && root.adapter !== null
    repeat: true
    onTriggered: if (root.adapter && !root.adapter.discovering) root.adapter.discovering = true
  }


  function deviceIcon(device) {
    if (!device) return "bluetooth"
    let icon = (device.icon || "").toLowerCase()
    if (icon.includes("headset") || icon.includes("headphone")) return "headset_mic"
    if (icon.includes("speaker")) return "speaker"
    if (icon.includes("audio")) return "speaker"
    if (icon.includes("keyboard")) return "keyboard"
    if (icon.includes("mouse")) return "mouse"
    return "bluetooth"
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
              text: "bluetooth_searching"
              color: Colors.white
              font.family: Config.materialSymbols.family
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
              text: "bluetooth_disabled"
              color: Colors.white
              font.family: Config.materialSymbols.family
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
                  Layout.preferredHeight: root.expandedDevice === modelData ? 84 : 62
                  color: connHover.hovered ? Colors.surface : (root.expandedDevice === modelData ? Colors.card : Colors.transparent)
                  clip: true
                  Behavior on color { ColorAnimation { duration: 90 } }
                  HoverHandler { id: connHover }

                  ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 62
                      MouseArea {
                        id: connHeaderMa
                        anchors.fill: parent
                        z: 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (root.expandedDevice === connRow.modelData) root.expandedDevice = null
                          else root.expandedDevice = connRow.modelData
                        }
                      }
                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12
                        z: 1
                        Text { text: root.deviceIcon(connRow.modelData); color: Colors.foreground; font.family: Config.materialSymbols.family; font.pixelSize: 20 }
                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 1
                          Text { text: connRow.modelData.name || connRow.modelData.deviceName || connRow.modelData.address; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                          Text { text: root.statusText(connRow.modelData); color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                          visible: connHover.hovered || root.expandedDevice === connRow.modelData
                          spacing: 6
                          z: 1
                          Rectangle {
                            width: 28
                            height: 28
                            radius: 0
                            color: discHover.containsMouse ? Colors.red : Colors.card
                            border.color: discHover.containsMouse ? Colors.red : Colors.border
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 90 } }
                            Text { anchors.centerIn: parent; text: "link_off"; color: discHover.containsMouse ? Colors.black : Colors.foreground; font.family: Config.materialSymbols.family; font.pixelSize: 14 }
                            MouseArea { id: discHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.handleDeviceClick(connRow.modelData) }
                          }
                          Rectangle {
                            width: 28
                            height: 28
                            radius: 0
                            color: forgetHover.containsMouse ? Colors.yellow : Colors.card
                            border.color: forgetHover.containsMouse ? Colors.yellow : Colors.border
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 90 } }
                            Text { anchors.centerIn: parent; text: "delete"; color: forgetHover.containsMouse ? Colors.black : Colors.foreground; font.family: Config.materialSymbols.family; font.pixelSize: 13 }
                            MouseArea { id: forgetHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { connRow.modelData.forget(); root.expandedDevice = null } }
                          }
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
                Layout.preferredHeight: root.expandedDevice === modelData ? 84 : 62
                color: availHover.hovered ? Colors.surface : (root.expandedDevice === modelData ? Colors.card : Colors.transparent)
                clip: true
                Behavior on color { ColorAnimation { duration: 90 } }
                HoverHandler { id: availHover }

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
                    MouseArea {
                      id: availHeaderMa
                      anchors.fill: parent
                      z: 0
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (root.expandedDevice === availRow.modelData) root.expandedDevice = null
                        else root.expandedDevice = availRow.modelData
                      }
                    }
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      z: 1
                      Text { text: root.deviceIcon(availRow.modelData); color: Colors.foreground; font.family: Config.materialSymbols.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: availRow.modelData.name || availRow.modelData.deviceName || availRow.modelData.address; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: availRow.modelData === null ? "" : root.statusText(availRow.modelData); color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                      }
                      Item { Layout.fillWidth: true; visible: availHover.hovered }
                      RowLayout {
                        visible: availHover.hovered
                        spacing: 6
                        z: 1
                        Rectangle {
                          width: 28
                          height: 28
                          radius: 0
                          color: availConnHover.containsMouse ? Qt.lighter(Colors.blue, 1.22) : Colors.blue
                          border.color: availConnHover.containsMouse ? Colors.foreground : Colors.border
                          border.width: 1
                          Behavior on color { ColorAnimation { duration: 90 } }
                          Text { anchors.centerIn: parent; text: availRow.modelData && availRow.modelData.paired ? "link" : "link_off"; color: Colors.black; font.family: Config.materialSymbols.family; font.pixelSize: 14 }
                          MouseArea { id: availConnHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.handleDeviceClick(availRow.modelData) }
                        }
                        Rectangle {
                          visible: availRow.modelData ? availRow.modelData.paired : false
                          width: 28
                          height: 28
                          radius: 0
                          color: availForgetHover.containsMouse ? Colors.yellow : Colors.card
                          border.color: availForgetHover.containsMouse ? Colors.yellow : Colors.border
                          border.width: 1
                          Behavior on color { ColorAnimation { duration: 90 } }
                          Text { anchors.centerIn: parent; text: "delete"; color: availForgetHover.containsMouse ? Colors.black : Colors.foreground; font.family: Config.materialSymbols.family; font.pixelSize: 13 }
                          MouseArea { id: availForgetHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { availRow.modelData.forget(); root.expandedDevice = null } }
                        }
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
                    Item { Layout.fillWidth: true }
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
