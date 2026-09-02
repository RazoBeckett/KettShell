import ".."
import Quickshell
import Quickshell.Hyprland
import QtQuick

PopupWindow {
  id: root

  required property Item anchorItem
  required property var barWindow
  property var shell: null
  property string popoutKind: ""
  property int margin: Config.margin
  property int contentWidth: 360
  property int contentHeight: 460

  default property alias contentItem: contentHolder.data

  visible: open || contentHolder.opacity > 0
  color: Colors.transparent
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  property bool open: false

  function close() {
    if (root.shell && typeof root.shell.releasePopout === "function") root.shell.releasePopout(root.popoutKind, root.anchorItem)
    else root.open = false
  }

  Shortcut {
    sequence: "Escape"
    onActivated: root.close()
  }

  HyprlandFocusGrab {
    active: root.open
    windows: root.barWindow ? [root, root.barWindow] : [root]
    onCleared: root.close()
  }

  anchor {
    id: popupAnchor
    window: root.barWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      if (!root.anchorItem || !root.barWindow || !root.barWindow.contentItem) return

      let popupWidth = root.implicitWidth
      let point = root.barWindow.contentItem.mapFromItem(
        root.anchorItem,
        root.anchorItem.width - popupWidth,
        root.anchorItem.height + root.margin
      )
      let maxX = root.barWindow.width - popupWidth - root.margin

      popupAnchor.rect.x = Math.round(Math.max(root.margin, Math.min(point.x, maxX)))
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    id: contentHolder
    width: root.implicitWidth
    height: root.implicitHeight
    y: root.open ? 0 : -8
    opacity: root.open ? 1 : 0
    clip: true

    Behavior on y {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
  }
}
