import ".."
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Windows 10 network flyout — minimal, flat, fixed height
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
  visible: NetworkMenuState.visible
  focusable: NetworkMenuState.visible

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
  property var pendingNetwork: null
  property string password: ""
  property var expandedNetwork: null
  property bool showPassword: false

  readonly property var wifiCenter: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values.find(n => n.connected) : null
  property var cachedCenter: null
  readonly property var connectingNetwork: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values.find(n => n.stateChanging) : null
  readonly property var effectiveCenter: wifiCenter ?? (connectingNetwork && cachedCenter ? cachedCenter : connectingNetwork)
  readonly property bool hasCenter: effectiveCenter !== null
  // Keep previous center visible while switching, hide it from the available list.
  // Use name-based filtering because NetworkManager may recreate objects on rescan.
  readonly property var wifiAvailable: {
    if (!wifiDevice || !wifiDevice.networks) return []
    let all = [...wifiDevice.networks.values].filter(n => !n.connected).sort((a, b) => b.signalStrength - a.signalStrength)
    if (effectiveCenter && !wifiCenter && cachedCenter) {
      let cn = (cachedCenter.name || "").trim()
      let connName = connectingNetwork ? (connectingNetwork.name || "").trim() : ""
      // hide cached from list, keep the actual connecting target in the list
      all = all.filter(n => (n.name || "").trim() !== cn || (n.name || "").trim() === connName)
      // if both Aqua bands share a base SSID, ensure only the targeted one shows as connecting
      // deduplicate by exact name — keep only first occurrence
      let seen = new Set()
      let deduped = []
      for (let n of all) { let k = (n.name || "").trim(); if (!seen.has(k)) { seen.add(k); deduped.push(n) } }
      all = deduped
    }
    return all
  }
  readonly property bool wifiOn: Networking.wifiEnabled

  onWifiCenterChanged: if (wifiCenter) cachedCenter = wifiCenter
  onVisibleChanged: {
    if (visible) BluetoothMenuState.visible = false
    if (visible && wifiOn && wifiDevice) wifiDevice.scannerEnabled = true
    if (!visible) {
      expandedNetwork = null
      pendingNetwork = null
      password = ""
      showPassword = false
    }
  }

  Timer {
    interval: 4000
    running: root.visible && root.wifiOn && root.wifiDevice !== null
    repeat: true
    onTriggered: if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
  }

  Shortcut {
    sequence: "Escape"
    onActivated: NetworkMenuState.visible = false
  }

  function signalIcon(network) {
    let s = network ? network.signalStrength : 0
    let tier = s >= 0.75 ? 4 : s >= 0.50 ? 3 : s >= 0.25 ? 2 : 1
    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }

  function needsSecret(network) {
    if (!network) return false
    if (network.known) return false
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
  }

  function securityLabel(network) {
    if (!network) return "—"
    switch (network.security) {
      case WifiSecurityType.Open: return "Open"
      case WifiSecurityType.Owe: return "OWE"
      case WifiSecurityType.Wep: return "WEP"
      case WifiSecurityType.WpaPsk: return "WPA-PSK"
      case WifiSecurityType.Wpa2Psk: return "WPA2-PSK"
      case WifiSecurityType.WpaEap: return "WPA-EAP"
      case WifiSecurityType.Wpa2Eap: return "WPA2-EAP"
      case WifiSecurityType.Sae: return "WPA3-SAE"
      case WifiSecurityType.Wpa3Eap: return "WPA3-EAP"
      default: return "Secured"
    }
  }

  function statusText(network) {
    if (!network) return ""
    if (network.stateChanging) return "Connecting..."
    if (network.connected) {
      if (network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) return "Connected, open"
      return "Connected, secured"
    }
    if (network.known) return "Secured"
    if (network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) return "Open"
    return "Secured"
  }

  function connectTo(network) {
    if (!network) return
    if (network.connected) {
      network.disconnect()
      expandedNetwork = null
      return
    }
    if (needsSecret(network)) {
      pendingNetwork = network
      expandedNetwork = network
      password = ""
      return
    }
    network.connect()
    expandedNetwork = null
  }

  function confirmConnect() {
    if (pendingNetwork && password.length > 0) {
      pendingNetwork.connectWithPsk(password)
      expandedNetwork = null
      pendingNetwork = null
      password = ""
    }
  }

  // outside click to close — behind bg so it does not block bg input
  MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: NetworkMenuState.visible = false
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

      // header with Wi-Fi toggle top right
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 8

        Text {
          text: "Wi-Fi"
          color: Colors.foreground
          font.pixelSize: 14
          font.family: Config.font.family
          font.weight: Font.Normal
        }
        Item { Layout.fillWidth: true }

        // toggle switch — win10 style
        Item {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 24

          Rectangle {
            id: track
            anchors.fill: parent
            radius: 0
            color: root.wifiOn ? Colors.blue : Colors.card
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
            x: root.wifiOn ? parent.width - width - 3 : 3
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          }
          MouseArea {
            id: toggleMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
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

        // Wi-Fi off placeholder
        ColumnLayout {
          visible: !root.wifiOn
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
              text: String.fromCodePoint(0xF05AA)
              color: Colors.white
              font.family: Config.iconFont.family
              font.pixelSize: 22
            }
            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text { text: "Wi-Fi is turned off"; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family }
              Text { text: "Turn on to see available networks"; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
            }
          }
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: Colors.blue
            Text { anchors.centerIn: parent; text: "Turn Wi-Fi back on"; color: Colors.black; font.pixelSize: 13; font.family: Config.font.family }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onEntered: parent.color = Qt.lighter(Colors.blue, 1.08)
              onExited: parent.color = Colors.blue
              onClicked: Networking.wifiEnabled = true
            }
          }
        }

        // networks scroll
        Flickable {
          id: flick
          visible: root.wifiOn
          anchors.fill: parent
          contentHeight: contentCol.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: contentCol
            width: flick.width
            spacing: 0

            // connected section — keeps showing cached network while switching so it never goes blank
            ColumnLayout {
              visible: root.hasCenter
              Layout.fillWidth: true
              spacing: 0

              Text {
                visible: root.wifiAvailable.length > 0
                text: "Current connection"
                color: Colors.white
                font.pixelSize: 11
                font.family: Config.font.family
                Layout.leftMargin: 16
                Layout.topMargin: 8
                Layout.bottomMargin: 4
              }

              // connected row — header is clickable, expanded part is separate
              Rectangle {
                id: connectedRow
                Layout.fillWidth: true
                Layout.preferredHeight: mainCol.implicitHeight
                color: connHover.hovered ? Colors.surface : (root.expandedNetwork === root.effectiveCenter ? Colors.card : Colors.transparent)
                opacity: root.wifiCenter ? 1.0 : 0.72
                Behavior on color { ColorAnimation { duration: 90 } }
                clip: true
                HoverHandler { id: connHover }

                ColumnLayout {
                  id: mainCol
                  anchors.fill: parent
                  spacing: 0

                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    MouseArea {
                      id: connectedHeaderMa
                      anchors.fill: parent
                      z: 0
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (root.expandedNetwork === root.effectiveCenter) root.expandedNetwork = null
                        else root.expandedNetwork = root.effectiveCenter
                      }
                    }
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      z: 1
                      Text { text: root.signalIcon(root.effectiveCenter); color: Colors.foreground; font.family: Config.iconFont.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: root.effectiveCenter ? (root.effectiveCenter.name || "Hidden Network") : ""; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: root.wifiCenter ? root.statusText(root.effectiveCenter) : "Connected, secured"; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                      }
                      Item { Layout.fillWidth: true }
                      Rectangle {
                        width: 28
                        height: 28
                        radius: 0
                        color: wifiDiscHover.containsMouse ? Colors.red : Colors.card
                        border.color: wifiDiscHover.containsMouse ? Colors.red : Colors.border
                        border.width: 1
                        opacity: (connHover.hovered || root.expandedNetwork === root.effectiveCenter) ? 1 : 0
                        enabled: connHover.hovered || root.expandedNetwork === root.effectiveCenter
                        Behavior on opacity { NumberAnimation { duration: 90 } }
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Text { anchors.centerIn: parent; text: String.fromCodePoint(0xF0338); color: wifiDiscHover.containsMouse ? Colors.black : Colors.foreground; font.family: Config.iconFont.family; font.pixelSize: 14 }
                        MouseArea { id: wifiDiscHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: root.wifiCenter !== null && (connHover.hovered || root.expandedNetwork === root.effectiveCenter); onClicked: root.connectTo(root.effectiveCenter) }
                      }
                    }
                  }
                  ColumnLayout {
                    id: expandedInfo
                    visible: root.expandedNetwork === root.effectiveCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    Layout.rightMargin: 12
                    Layout.topMargin: 6
                    Layout.bottomMargin: 10
                    spacing: 4
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Text { text: "Interface"; color: Colors.white; font.pixelSize: 11; font.family: Config.font.family; Layout.preferredWidth: 72 }
                      Text { text: root.wifiDevice ? root.wifiDevice.name : "—"; color: Colors.foreground; font.pixelSize: 11; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Text { text: "MAC"; color: Colors.white; font.pixelSize: 11; font.family: Config.font.family; Layout.preferredWidth: 72 }
                      Text { text: root.wifiDevice ? root.wifiDevice.address : "—"; color: Colors.foreground; font.pixelSize: 11; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Text { text: "Signal"; color: Colors.white; font.pixelSize: 11; font.family: Config.font.family; Layout.preferredWidth: 72 }
                      Text { text: root.effectiveCenter ? Math.round(root.effectiveCenter.signalStrength * 100) + "%" : "—"; color: Colors.foreground; font.pixelSize: 11; font.family: Config.font.family; Layout.fillWidth: true }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Text { text: "Security"; color: Colors.white; font.pixelSize: 11; font.family: Config.font.family; Layout.preferredWidth: 72 }
                      Text { text: root.effectiveCenter ? securityLabel(root.effectiveCenter) : "—"; color: Colors.foreground; font.pixelSize: 11; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                  }
                }
              }

              Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Colors.border; visible: root.wifiAvailable.length > 0 }
            }

            // available rows
            Repeater {
              model: root.wifiOn ? root.wifiAvailable.slice(0, 20) : []

              delegate: Rectangle {
                id: netRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: !modelData ? 62 : root.expandedNetwork === modelData ? (root.needsSecret(modelData) ? 136 : 100) : 62
                color: headerMa.containsMouse ? Colors.surface : (root.expandedNetwork === modelData ? Colors.card : Colors.transparent)
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

                  // header — only this part toggles expand
                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      Text { text: root.signalIcon(netRow.modelData); color: Colors.foreground; font.family: Config.iconFont.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: netRow.modelData.name || "Hidden Network"; color: Colors.foreground; font.pixelSize: 13; font.family: Config.font.family; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: netRow.modelData === root.connectingNetwork ? "Connecting..." : root.statusText(netRow.modelData); color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                      }
                      Text { visible: netRow.modelData && netRow.modelData.security !== WifiSecurityType.Open && netRow.modelData.security !== WifiSecurityType.Owe; text: String.fromCodePoint(0xF033E); color: Colors.white; font.family: Config.iconFont.family; font.pixelSize: 12 }
                    }
                    MouseArea {
                      id: headerMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      z: 0
                      onClicked: {
                        if (root.expandedNetwork === netRow.modelData) {
                          root.expandedNetwork = null
                          if (root.pendingNetwork === netRow.modelData) { root.pendingNetwork = null; root.password = "" }
                        } else {
                          root.expandedNetwork = netRow.modelData
                          if (root.needsSecret(netRow.modelData)) { root.pendingNetwork = netRow.modelData; root.password = "" }
                          else root.pendingNetwork = null
                        }
                      }
                    }
                  }

                  // expanded detail — sits above header hit area
                  ColumnLayout {
                    visible: root.expandedNetwork === netRow.modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 10
                    spacing: 8
                    z: 1

                    // password field
                    Rectangle {
                      visible: netRow.modelData ? root.needsSecret(netRow.modelData) : false
                      Layout.fillWidth: true
                      Layout.preferredHeight: 30
                      color: Colors.surface
                      border.color: passInput.activeFocus ? Colors.blue : Colors.border
                      border.width: passInput.activeFocus ? 2 : 1

                      RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 6

                        TextInput {
                          id: passInput
                          Layout.fillWidth: true
                          text: root.pendingNetwork === netRow.modelData ? root.password : ""
                          color: Colors.foreground
                          font.pixelSize: 13
                          font.family: Config.font.family
                          echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                          passwordCharacter: "•"
                          selectByMouse: true
                          focus: netRow.modelData ? (root.expandedNetwork === netRow.modelData && root.needsSecret(netRow.modelData)) : false
                          onTextChanged: if (root.pendingNetwork === netRow.modelData) root.password = text
                          onAccepted: root.confirmConnect()
                          // placeholder
                          Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter network security key"
                            color: Colors.white
                            opacity: 0.6
                            font.pixelSize: 12
                            font.family: Config.font.family
                            visible: passInput.text.length === 0 && !passInput.activeFocus
                          }
                        }
                        Text {
                          id: eyeIcon
                          text: root.showPassword ? String.fromCodePoint(0xF06D1) : String.fromCodePoint(0xF06D0)
                          color: eyeMa.containsMouse ? Colors.foreground : Colors.white
                          font.family: Config.iconFont.family
                          font.pixelSize: 16
                          MouseArea {
                            id: eyeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showPassword = !root.showPassword
                          }
                        }
                      }
                      MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.IBeamCursor
                        onClicked: passInput.forceActiveFocus()
                      }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8
                      Rectangle { width: 16; height: 16; color: Colors.transparent; border.color: Colors.white; border.width: 1 }
                      Text { text: "Connect automatically"; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                      Item { Layout.fillWidth: true }
                      Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 28
                        color: connMa.containsMouse ? Qt.lighter(Colors.blue, 1.08) : Colors.blue
                        visible: netRow.modelData ? !netRow.modelData.stateChanging : true
                        Text { anchors.centerIn: parent; text: "Connect"; color: Colors.black; font.pixelSize: 12; font.family: Config.font.family }
                        MouseArea { id: connMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.needsSecret(netRow.modelData)) root.confirmConnect(); else root.connectTo(netRow.modelData) } }
                      }
                      Text { visible: netRow.modelData ? netRow.modelData.stateChanging : false; text: "Connecting..."; color: Colors.white; font.pixelSize: 12; font.family: Config.font.family }
                    }
                  }
                }
              }
            }

            Text {
              visible: root.wifiAvailable.length === 0 && !root.hasCenter
              Layout.alignment: Qt.AlignHCenter
              Layout.topMargin: 24
              text: "No Wi-Fi networks found"
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
