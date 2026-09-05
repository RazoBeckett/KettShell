import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
  id: root

  property bool open: false

  function toggle(): void {
    open ? close() : show()
  }

  function show(): void {
    open = true
  }

  function close(): void {
    open = false
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "wallpaper-picker-toggle"
    description: "Toggle wallpaper picker"

    onPressed: root.toggle()
  }

  IpcHandler {
    target: "wallpaperPicker"

    function toggle(): void {
      root.toggle()
    }

    function open(): void {
      root.show()
    }

    function close(): void {
      root.close()
    }

    function isOpen(): string {
      return root.open ? "1" : "0"
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win

      required property var modelData

      screen: modelData

      visible: root.open || animProgress > 0

      color: "transparent"

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      WlrLayershell.keyboardFocus:
        (root.open || win.animProgress > 0)
          ? WlrKeyboardFocus.Exclusive
          : WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore

      property real animProgress: 0
      property bool shouldShow: root.open

      // 3-up, bigger for readability — fits 1080p+ and clamps on smaller screens
      readonly property int pickerItemW: 400
      readonly property int pickerGap: 12
      readonly property int pickerVisibleCount: 3

      readonly property int pickerRowW:
        pickerVisibleCount * pickerItemW +
        (pickerVisibleCount - 1) * pickerGap

      property int currentIndex: -1
      property int lastDir: 0
      property string debouncedText: ""
      readonly property var filteredModel: Wallpapers.query(debouncedText) || []

      readonly property var windowModel: {
        if (!filteredModel || filteredModel.length === 0)
          return []
        if (filteredModel.length <= pickerVisibleCount)
          return filteredModel
        let n = filteredModel.length
        let ci = currentIndex
        if (ci < 0) ci = 0
        if (ci >= n) ci = n - 1
        return [
          filteredModel[(ci - 1 + n) % n],
          filteredModel[ci],
          filteredModel[(ci + 1) % n]
        ]
      }

      // Directional preload: when moving right, warm 4 right / 2 left, and vice versa
      readonly property var leftPreloadModel: {
        if (!filteredModel || filteredModel.length <= 6) return []
        let n = filteredModel.length
        let ci = currentIndex
        if (ci < 0) return []
        if (lastDir === 1) {
          return [
            filteredModel[(ci - 3 + n) % n],
            filteredModel[(ci - 2 + n) % n]
          ]
        } else if (lastDir === -1) {
          return [
            filteredModel[(ci - 5 + n) % n],
            filteredModel[(ci - 4 + n) % n],
            filteredModel[(ci - 3 + n) % n],
            filteredModel[(ci - 2 + n) % n]
          ]
        }
        return [
          filteredModel[(ci - 4 + n) % n],
          filteredModel[(ci - 3 + n) % n],
          filteredModel[(ci - 2 + n) % n]
        ]
      }

      readonly property var rightPreloadModel: {
        if (!filteredModel || filteredModel.length <= 6) return []
        let n = filteredModel.length
        let ci = currentIndex
        if (ci < 0) return []
        if (lastDir === 1) {
          return [
            filteredModel[(ci + 2) % n],
            filteredModel[(ci + 3) % n],
            filteredModel[(ci + 4) % n],
            filteredModel[(ci + 5) % n]
          ]
        } else if (lastDir === -1) {
          return [
            filteredModel[(ci + 2) % n],
            filteredModel[(ci + 3) % n]
          ]
        }
        return [
          filteredModel[(ci + 2) % n],
          filteredModel[(ci + 3) % n],
          filteredModel[(ci + 4) % n]
        ]
      }

      property var seenCache: []
      readonly property int seenCacheCap: 15

      function cachePreviews(list) {
        if (!list || list.length === 0) return
        let changed = false
        for (let i = 0; i < list.length; i++) {
          let p = list[i]
          let idx = seenCache.indexOf(p)
          if (idx !== -1) {
            seenCache.splice(idx, 1)
            seenCache.push(p)
            changed = true
          } else {
            seenCache.push(p)
            changed = true
          }
        }
        let trimmed = false
        while (seenCache.length > seenCacheCap) {
          seenCache.shift()
          trimmed = true
        }
        if (changed || trimmed) seenCache = seenCache.slice()
      }

      onWindowModelChanged: cachePreviews(windowModel)
      onLeftPreloadModelChanged: cachePreviews(leftPreloadModel)
      onRightPreloadModelChanged: cachePreviews(rightPreloadModel)

      onFilteredModelChanged: {
        Qt.callLater(() => {
          let m = filteredModel
          if (!m || m.length === 0) {
            currentIndex = -1
            return
          }
          let cur = Wallpapers.current
          let idx = m.indexOf(cur)
          currentIndex = idx >= 0 ? idx : 0
        })
      }

      onShouldShowChanged: {
        animProgress = shouldShow ? 1 : 0
      }

      // Scale in and out are mirrored — same curve reversed for exit/Enter.
      Behavior on animProgress {
        NumberAnimation {
          duration: 280
          easing.type: Easing.InOutCubic
        }
      }

      Rectangle {
        id: dim
        anchors.fill: parent
        color: "#000000"
        opacity: win.animProgress * 0.32
        visible: opacity > 0.01
        // no Behavior — dim is pure derivative of animProgress (single progress)
        TapHandler {
          acceptedButtons: Qt.LeftButton
          onTapped: root.close()
        }
      }

      function commitCurrent(): void {
        if (win.currentIndex < 0 || win.currentIndex >= win.filteredModel.length)
          return
        Wallpapers.setWallpaper(win.filteredModel[win.currentIndex])
        root.close()
      }

      Column {
        id: contentCol

        anchors.centerIn: parent

        /*
         * Keep the whole picker centered and compact.
         * Opacity/scale are derived from animProgress — single progress
         * drives the whole exit so the reverse mirrors the entrance without
         * the chase stutter (see Quickshell Motion guide).
         */
        width: Math.min(
          win.pickerRowW,
          parent.width - 32
        )

        spacing: 8

        opacity: win.animProgress
        scale: 0.96 + win.animProgress * 0.04

        visible: win.animProgress > 0.01

        /*
         * Search
         */
        Rectangle {
          id: searchWrap

          width: parent.width
          height: 44

          radius: 0

          color: "transparent"

          TextInput {
            id: searchField

            anchors.fill: parent

            anchors.leftMargin: 12
            anchors.rightMargin: 12

            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter

            color: Colors.foreground

            selectionColor: Colors.blue
            selectedTextColor: Colors.background

            font.family: Config.font.family
            font.pixelSize: 14
            font.weight: Config.font.weight

            property string placeholderText:
              "Search by filename"

            Text {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              horizontalAlignment: Text.AlignHCenter

              text: searchField.placeholderText

              color: Colors.white

              opacity:
                searchField.text.length === 0
                  ? (
                      searchField.activeFocus
                        ? 0.28
                        : 0.45
                    )
                  : 0

              font.family: searchField.font.family
              font.pixelSize: searchField.font.pixelSize
              font.weight: searchField.font.weight

              visible: opacity > 0

              Behavior on opacity {
                NumberAnimation {
                  duration: 110
                }
              }
            }

            Timer {
              id: searchDebounce
              interval: 100
              onTriggered: win.debouncedText = searchField.text
            }
            onTextChanged: { if (searchDebounce) searchDebounce.restart() }

            Keys.onPressed: event => {
              if (
                (event.modifiers & Qt.ControlModifier) &&
                event.key === Qt.Key_H
              ) {
                win.selectPrevious()
                event.accepted = true

              } else if (
                (event.modifiers & Qt.ControlModifier) &&
                event.key === Qt.Key_L
              ) {
                win.selectNext()
                event.accepted = true

              } else if (event.key === Qt.Key_Left) {
                win.selectPrevious()
                event.accepted = true

              } else if (event.key === Qt.Key_Right) {
                win.selectNext()
                event.accepted = true

              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true

              } else if (
                event.key === Qt.Key_Return ||
                event.key === Qt.Key_Enter
              ) {
                if (win.currentIndex >= 0 && win.currentIndex < win.filteredModel.length) {
                  Wallpapers.setWallpaper(win.filteredModel[win.currentIndex])
                }
                root.close()
                event.accepted = true
              }
            }
          }
        }

        /*
         * Wallpaper previews.
         *
         * No PathView.
         *
         * The Row controls the spacing exactly:
         *
         * [300][4][300][4][300]
         */
        Item {
          id: carouselHost

          width: parent.width

          height: 280

          clip: false

          Text {
            anchors.centerIn: parent

            text:
              Wallpapers.all.length === 0
                ? "No wallpapers in " + Config.wallDir
                : (
                    (!win.filteredModel || win.filteredModel.length === 0)
                      ? "No match"
                      : ""
                  )

            color: Colors.white

            opacity: 0.6

            font.family: Config.font.family
            font.pixelSize: 13

            horizontalAlignment: Text.AlignHCenter

            visible: text !== ""
          }

          Row {
            id: wallpaperRow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            spacing: win.pickerGap

            visible: win.filteredModel ? win.filteredModel.length > 0 : false

            Repeater {
              model: win.windowModel

              delegate: WallpaperItem {
                width: win.pickerItemW

                isCurrent: modelData === win.filteredModel[win.currentIndex]

                onClicked: {
                  let g = win.filteredModel.indexOf(modelData)
                  if (g >= 0) {
                    let n = win.filteredModel.length
                    let cur = win.currentIndex
                    if (n > 0 && cur >= 0) {
                      let dist = (g - cur + n) % n
                      if (dist !== 0) win.lastDir = dist <= n / 2 ? 1 : -1
                    }
                    win.currentIndex = g
                  }
                }
              }
            }
          }
        }

        // Preload 3 left + 3 right neighbours in background (Image async, not LazyLoader inside Variants)
        // Keep every preview that was ever in window/neighbours until picker closes, then free
        Item {
          id: preloadCache
          visible: true
          opacity: 0.001
          width: 1
          height: 1
          // model empty when closed frees the Images
          Repeater {
            model: root.open ? win.seenCache : []
            delegate: Item {
              id: cacheDel
              required property string modelData
              Image {
                source: "file://" + cacheDel.modelData
                sourceSize.width: 400
                sourceSize.height: 225
                asynchronous: true
                cache: true
                autoTransform: false
              }
            }
          }
        }
      }

      function selectPrevious(): void {
        if (!filteredModel || filteredModel.length === 0)
          return
        lastDir = -1
        if (
          currentIndex <= 0 ||
          currentIndex >= filteredModel.length
        ) {
          currentIndex = filteredModel.length - 1
        } else {
          currentIndex--
        }
      }

      function selectNext(): void {
        if (!filteredModel || filteredModel.length === 0)
          return
        lastDir = 1
        if (
          currentIndex < 0 ||
          currentIndex >= filteredModel.length - 1
        ) {
          currentIndex = 0
        } else {
          currentIndex++
        }
      }

      onVisibleChanged: {
        if (!root.open) {
          seenCache = []
          return
        }

        searchField.text = ""
        debouncedText = ""
        if (searchDebounce) searchDebounce.stop()

        let start = Wallpapers.current
        let all = Wallpapers.all
        let idx = all.indexOf(start)

        if (idx >= 0) {
          currentIndex = idx
        } else if (all.length > 0) {
          currentIndex = 0
        } else {
          currentIndex = -1
        }

        Qt.callLater(() => {
          searchField.forceActiveFocus()
        })
      }

      /*
       * Global keyboard handling while the picker is open.
       *
       * This does not sit above the thumbnails, so it cannot
       * intercept mouse clicks.
       */
      Shortcut {
        sequence: "Escape"
        onActivated: root.close()
      }

      Shortcut {
        sequence: "Ctrl+H"
        onActivated: win.selectPrevious()
      }

      Shortcut {
        sequence: "Ctrl+L"
        onActivated: win.selectNext()
      }

      HyprlandFocusGrab {
        active: root.open || win.animProgress > 0

        windows: [win]

        onCleared: root.close()
      }
    }
  }
}
