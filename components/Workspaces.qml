import ".."
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 0

  readonly property var sortedWorkspaces: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1
  property int _prevFocusedId: -1
  property int _pendingPopId: -1

  function _tryPop() {
    if (_pendingPopId === -1) return
    for (let i = 0; i < wsRepeater.count; i++) {
      let d = wsRepeater.itemAt(i)
      if (d && d.ws && d.ws.id === _pendingPopId) {
        if (d.pop) d.pop.restart()
        _pendingPopId = -1
        return
      }
    }
    // delegate not yet created (empty workspace just appeared) - retry next frame
    Qt.callLater(_tryPop)
  }

  onFocusedIdChanged: {
    if (_prevFocusedId === -1) { _prevFocusedId = focusedId; return }
    if (focusedId === -1) return
    // pop only the newly focused workspace, not the previous one - avoids Repeater reuse pop
    // empty workspaces (8/9/6) are created on-demand, so delegate may not exist yet - defer via _tryPop
    _pendingPopId = focusedId
    Qt.callLater(_tryPop)
    _prevFocusedId = focusedId
  }

  Component.onCompleted: _prevFocusedId = focusedId

  Repeater {
    id: wsRepeater
    model: root.sortedWorkspaces

    Item {
      id: wsButton
      required property var modelData
      property var ws: modelData
      property bool isActive: Hyprland.focusedWorkspace?.id === ws.id
      property bool isHovered: ma.containsMouse

      implicitWidth: label.implicitWidth + 18
      implicitHeight: Config.barHeight
      property alias pop: popAnim

      SequentialAnimation {
        id: popAnim
        NumberAnimation { target: label; property: "scale"; from: 1; to: 1.14; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { target: label; property: "scale"; to: 1; duration: 130; easing.type: Easing.OutCubic }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.ws.id
        color: wsButton.isActive ? Colors.waybarActive : Colors.foreground
        font: Config.font
        transformOrigin: Item.Center
        scale: 1
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: Colors.foreground
        visible: wsButton.isHovered && !wsButton.isActive
        opacity: wsButton.isHovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.waybarHover
        opacity: wsButton.isHovered ? 1 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${wsButton.ws.id} })`])
      }
    }
  }
}
