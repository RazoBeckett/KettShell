import ".."
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      color: "black"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Image {
        id: bgImage
        anchors.fill: parent
        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
        fillMode: Image.PreserveAspectCrop
        // decode only to screen size, not full 4K+
        sourceSize.width: win.screen ? win.screen.width : 1920
        sourceSize.height: win.screen ? win.screen.height : 1080
        asynchronous: true
        cache: true
        smooth: true
        mipmap: false
        autoTransform: false

        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
        }
      }

      // fallback when no wallpaper
      Rectangle {
        anchors.fill: parent
        color: Colors.background
        visible: !Wallpapers.current
        z: -1
      }
    }
  }
}
