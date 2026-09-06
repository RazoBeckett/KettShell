import "../.."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Dialogs

/*
 * Host window for the settings menu. Fullscreen transparent overlay on the
 * primary screen; outside click and Escape play the close animation.
 * Toggle with `qs ipc call settings toggle` (e.g. bound to Win+I in Hyprland).
 *
 * The folder picker is a native window, which always stacks below this
 * overlay. Picking a directory therefore hides the menu first and reopens
 * it once the dialog closes.
 */
Scope {
  id: root

  property bool open: false

  function toggle(): void {
    if (root.open) menu.playClose()
    else root.open = true
  }

  IpcHandler {
    target: "settings"

    function toggle(): void {
      root.toggle()
    }

    function open(): void {
      root.open = true
    }

    function close(): void {
      if (root.open) menu.playClose()
    }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "settings-toggle"
    description: "Toggle settings menu"
    onPressed: root.toggle()
  }

  PanelWindow {
    id: win
    screen: Quickshell.primaryScreen || null

    visible: root.open || menu.busy
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "kettshell-settings"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: menu.playClose()
    }

    SettingsMenu {
      id: menu
      anchors.centerIn: parent
      open: root.open
      onCloseFinished: root.open = false
    }

    HyprlandFocusGrab {
      active: root.open
      windows: [win]
      onCleared: menu.playClose()
    }
  }
}
