pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * User preferences persisted to kettshell.json under the shell state path.
 * Adapter initializers are the factory defaults; missing keys fall back to them.
 */
Singleton {
  id: root

  readonly property string statePath: Quickshell.statePath("kettshell.json")

  readonly property alias wallpaper: adapter.wallpaper
  readonly property alias ui: adapter.ui

  // Corner scale, derived from the saved value by φ. Lives outside the
  // adapter so it never leaks into kettshell.json.
  readonly property QtObject rounding: QtObject {
    readonly property real phi: 1.618
    readonly property int lg: adapter.ui.rounding
    readonly property int md: Math.max(0, Math.round(adapter.ui.rounding / phi))
    readonly property int sm: Math.max(0, Math.round(adapter.ui.rounding / (phi * phi)))
    readonly property int xs: Math.max(0, Math.round(adapter.ui.rounding / (phi * phi * phi)))
  }

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false

    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: adapter

      property JsonObject wallpaper: JsonObject {
        property string directory: "~/Pictures/Wallpapers/MyWallpapers/"
        property string current: ""
        property int wipeDeg: 30
      }

      property JsonObject ui: JsonObject {
        property bool genie: true
        property int rounding: 5
      }
    }
  }
}
