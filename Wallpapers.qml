pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string expandedWallDir: {
    let p = Config.wallDir

    if (!p || p.length === 0)
      p = "~/Pictures/Wallpapers/MyWallpapers/"

    let home = Quickshell.env("HOME") || ""

    p = p.replace(/^~/, home)
    p = p.replace(/\$HOME/g, home)
    p = p.replace(/\$\{HOME\}/g, home)

    if (!p.endsWith("/"))
      p += "/"

    return p
  }

  readonly property string statePath:
    (Quickshell.env("HOME") || "") +
    "/.cache/quickshell/wallpaper/path.txt"

  readonly property string stateDir:
    (Quickshell.env("HOME") || "") +
    "/.cache/quickshell/wallpaper"

  property list<string> all: []
  property string current: ""

  function fileName(path: string): string {
    let i = path.lastIndexOf("/")

    return i >= 0
      ? path.slice(i + 1)
      : path
  }

  // Fuzzy score: higher is better, 0 = no match. Exact substring gets 100 bonus, sequential chars get gap/consecutive/boundary bonuses.
  function fuzzyScore(pattern: string, text: string): real {
    if (!pattern || pattern.length === 0) return 1
    let p = pattern.toLowerCase()
    let t = text.toLowerCase()
    let pLen = p.length
    let tLen = t.length
    if (pLen > tLen) return 0
    let idx = t.indexOf(p)
    if (idx !== -1) {
      return 100 - idx
    }
    let score = 0
    let prev = -1
    let consecutive = 0
    for (let i = 0; i < pLen; i++) {
      let ch = p[i]
      let found = t.indexOf(ch, prev + 1)
      if (found === -1) return 0
      if (prev !== -1 && found === prev + 1) {
        consecutive++
        score += 8 + consecutive * 2
      } else {
        consecutive = 0
        let gap = found - prev - 1
        score -= gap * 1.5
        if (found === 0 || t[found - 1] === "_" || t[found - 1] === "-" || t[found - 1] === " " || t[found - 1] === "." || t[found - 1] === "/") {
          score += 6
        }
      }
      if (i === 0 && found === 0) score += 10
      prev = found
    }
    return score > 0 ? score : 0.5
  }

  function query(filter: string): list<string> {
    if (!filter || filter.trim() === "")
      return all
    let q = filter.trim()
    let scored = []
    for (let i = 0; i < all.length; i++) {
      let p = all[i]
      let name = fileName(p)
      let s = fuzzyScore(q, name)
      if (s > 0) scored.push([p, s])
    }
    scored.sort((a, b) => b[1] - a[1])
    let out = []
    for (let i = 0; i < scored.length; i++) out.push(scored[i][0])
    return out
  }

  function setWallpaper(path: string): void {
    if (!path)
      return

    current = path

    saveProc.command = [
      "bash",
      "-c",
      "mkdir -p \"" +
        stateDir.replace(/"/g, "\\\"") +
        "\" && printf '%s' \"" +
        path.replace(/"/g, "\\\"") +
        "\" > \"" +
        statePath.replace(/"/g, "\\\"") +
        "\""
    ]

    saveProc.running = true
  }

  function refresh(): void {
    listProc.running = true
  }

  /*
   * Load the current wallpaper from the state file.
   */
  FileView {
    id: stateFile

    path: root.statePath

    watchChanges: true
    printErrors: false

    onFileChanged: reload()

    onLoaded: {
      let t = text().trim()

      if (t.length > 0) {
        root.current = t
      } else if (root.all.length > 0) {
        root.current = root.all[0]
      }
    }

    onLoadFailed: {
      if (root.all.length > 0)
        root.current = root.all[0]
    }
  }

  /*
   * Fallback when the state file has not loaded yet.
   */
  onAllChanged: {
    if (
      !root.current &&
      root.all.length > 0
    ) {
      root.current = root.all[0]
    }
  }

  /*
   * Find wallpapers.
   */
  Process {
    id: listProc

    command: [
      "bash",
      "-c",
      "dir=\"" +
        root.expandedWallDir.replace(/"/g, "\\\"") +
        "\"; " +
        "[ -d \"$dir\" ] || exit 0; " +
        "find \"$dir\" -type f " +
        "\\( " +
        "-iname \"*.jpg\" -o " +
        "-iname \"*.jpeg\" -o " +
        "-iname \"*.png\" -o " +
        "-iname \"*.webp\" -o " +
        "-iname \"*.bmp\" -o " +
        "-iname \"*.gif\" " +
        "\\) 2>/dev/null | sort"
    ]

    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        let t = (text || "").trim()

        if (t === "") {
          root.all = []
          return
        }

        let lines = t
          .split("\n")
          .filter(
            s => s.trim().length > 0
          )

        root.all = lines
      }
    }
  }

  /*
   * Save current wallpaper path.
   */
  Process {
    id: saveProc

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  /*
   * Re-list when Config.wallDir changes.
   */
  onExpandedWallDirChanged: {
    Qt.callLater(() => {
      listProc.running = true
    })
  }

  /*
   * IPC
   */
  IpcHandler {
    target: "wallpaper"

    function list(): string {
      return root.all.join("\n")
    }

    function get(): string {
      return root.current
    }

    function set(path: string): void {
      root.setWallpaper(path)
    }

    function refresh(): void {
      root.refresh()
    }
  }
}
