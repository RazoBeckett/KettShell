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
      }
    }
  }
}
