---
name: quickshell
description: Quickshell QML for pills, bars, media, and Hyprland workspace indicators. Use when creating or modifying a Quickshell interface or reusable QML component.
---

# Quickshell UI elements

Build the visual component first. Keep data collection outside it so the same pill works for a clock, track title, battery level, or network name. Target Quickshell v0.3.0 unless the project pins another version. Check the project's imports and the [type reference](https://quickshell.org/docs/v0.3.0/types/) before using a Quickshell API.



## Steps

Do these in order. Each step states how you know it is done.

1. **Inspect the host shell.** Find `shell.qml` and `ShellRoot`, Quickshell version, compositor, monitor setup, fonts, palette, and where the four directories live (`components/`, `services/`, `modules/`, `theme/`). Preserve the project's layout. If it is flat, introduce the four directories gradually as you add files.
   Done when you can name the entry file, the version, and whether `Quickshell.screens` has one or many screens.

2. **Define the component's inputs.** Name the properties a caller controls — `icon`, `label`, `iconColor`, `maxLabelWidth`, `active` — before drawing anything. Keep `Process`, `Timer`, and service objects out of the visual file.
   Done when the component has no data fetching inside it and every value it displays comes from a declared property.

3. **Size from content, bound what you do not control.** Use `implicitWidth`/`implicitHeight` and derive `radius: implicitHeight / 2` for pills. Cap system or media text with `Layout.maximumWidth` plus `Text.ElideRight` so a long title never pushes other controls off screen.
   Done when the element sizes itself from its layout and a 200-character label stays bounded.

4. **Place with anchors, arrange with layouts.** Anchor a group in its `PanelWindow`, then use `RowLayout` or `ColumnLayout` for the children inside that group. Write bindings for relationships like `width: other.width - 20` and let the engine keep them true.
   Done when no child of a layout is also anchored, and no imperative code manually updates a bound value.

5. **Wire data.** Prefer a native service when one exists. Otherwise use a small command source whose only output is a `value` string. Keep any poller interval matched to how fast the data changes and handle the empty-string case in the visual. For multi-monitor, declare shared sources in the outer `Scope` outside `Variants`. See Scoping below.
   Done when every live value comes from a native service or a single shared source, and `Variants` contains only windows.

6. **Check tooling and states.** Verify `qmlls.ini` next to `shell.qml`, expect `PanelWindow` to show as unresolved and mid-edit brace errors to go quiet. Run with `qs log`, fix file/line/column errors before adding the next element, and give media/network/hardware an explicit empty state. Add `Behavior` or `states`/`transitions` only on a property whose change is visible, and animate a single `progress` value (see Motion).
   Done when `qs log` is clean, empty states render without looking broken, and no duplicated `Process` or `Timer` runs per monitor.

7. **Test at the edges.** Real display scale, long text, no media player, missing hardware, every connected monitor, connect and disconnect a screen.
   Done when sizing, text bounds, empty states, and per-monitor windows hold across all those cases.

Every element is complete only when content-driven sizing, bounded uncontrolled text, a sensible empty state, and no duplicated source per monitor all hold.

## Reference

### Mental model

- **Binding.** QML is declarative. Declare the relationship, the engine keeps it true. That is the whole unlock — `width: other.width - 20` stays true without update code.
- **Three layers.** Keep them separate in what you generate. Surfaces hold `PanelWindow` and layer shell placement. Services hold system truth, usually as singletons. Components hold the visuals built from the first two.

### Surfaces

`PanelWindow` is a layer shell surface. Set everything explicitly.

- `anchors`: `top` + `left` + `right` is a full width top bar. `top` alone is a floating island or notch.
- `layer`: `background`, `bottom`, `top`, `overlay`. A bar behind windows is a `layer` error. `overlay` sits above even fullscreen.
- `exclusiveZone`: space the compositor reserves so tiled windows do not open underneath.
- `margins` and `implicitHeight` are a pair.

Entry is `~/.config/quickshell/shell.qml` with `ShellRoot`. The shell hot reloads on save. Iterate by writing the file and watching `qs log`.

### Minimal QML you need

Stay inside this slice unless the task requires more: `Item` as invisible base, `Rectangle` and `Text` to draw, custom `property` declarations, `anchors` to place a group in its window, `RowLayout` and `ColumnLayout` to arrange children of that group, and bindings.

Put anchors on the group, not on children that a layout manages. Layout in QML is not CSS. There is no box model and anchors are not flexbox. Read "Item size and positioning" at `doc.qt.io` before laying anything out.

File and import rules: one type per file with a capitalized filename — `MyButton.qml` becomes type `MyButton` in neighbors. Pin import versions. Quickshell types shift between releases.

### Services and scoping

**Singleton.** File starts with `pragma Singleton`, root is `Singleton { }`. One instance, one source of truth, read everywhere.

Prefer native services: `audio`, `power`, Hyprland IPC for `Hyprland.workspaces`. Fall back to `Process` with `StdioCollector` and parse stdout only when no service covers it.

**Scope.** `Variants { model: Quickshell.screens }` creates one `PanelWindow` per screen. Anything inside `Variants` is duplicated — a `Timer` or `Process` there becomes one per monitor. Put shared sources in the outer `Scope` so they exist once. The Bar example shows the correct placement. Never assume a single screen.

### Motion

Use `Behavior on prop { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }` for a single property and `states`/`transitions` for whole layout switches.

Animate one number and derive the rest. Name it `progress` from 0 to 1 and compute position, corner radius, and shape with arithmetic on it. The canonical failure is a clock that slides while its width also animates — position depended on width, every frame restarted toward a moved target, the clock froze then lurched. A single `progress` eliminates the chase. For richer motion, simulate a damped spring and feed its response to the engine.

### Architecture and performance

A shell past about 600 lines fragments without structure. Use four directories: `components/` for reusable primitives, `services/` for singletons, `modules/` for features like bar, launcher, notifications, and `theme/` for every color, radius, and spacing token.

One-way data flow holds it together: config feeds theme, theme feeds interface. A component reads a token and never writes one, so a full restyle happens from one file.

QML builds every object before showing anything. Defer heavy, rarely opened panels with `LazyLoader` — launcher, control center, calendar. That is the difference between instant startup and a one second hang.

### Traps

Check these before chasing other bugs.

1. **Root imports.** `import "root:/..."` is an old feature that breaks the language server and singletons. Use proper module imports.
2. **Fullscreen transparent surface.** A backdrop or overlay covering the whole screen swallows all input unless you give it an empty input region. Symptom is a dead desktop with no errors.
3. **Zero opacity.** The engine skips work at `opacity: 0`. First fade-in then builds from cold and stutters on entrance while exit looks fine. Keep idle items a hair above zero so they stay prepared.
4. **Outdated configs.** The docs note Quickshell has evolved and most cloned configs teach old patterns. Read them for ideas, do not paste them.

### Tooling

- `qmlls.ini` next to `shell.qml` enables the language server. The file is auto-managed and differs per machine — gitignore it. Two quirks are normal: it goes quiet while braces are unclosed mid-edit, and it cannot resolve Quickshell's own types like `PanelWindow`.
- `qs log` and `qs kill` inspect and stop the shell. `qs & disown` runs it detached.

### Pill — reusable icon and label

Values are examples. Match the host theme instead of reusing them.

```qml
// Pill.qml
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: "#8ec07c"
    property int maxLabelWidth: 400

    implicitWidth: row.implicitWidth + 32
    implicitHeight: 32
    radius: implicitHeight / 2
    color: "#1d3631"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Text {
            text: root.icon
            color: root.iconColor
            font.family: "Material Symbols Rounded"
            font.pixelSize: 16
        }

        Text {
            text: root.label
            color: "#f5e2c5"
            font.pixelSize: 16
            elide: Text.ElideRight
            Layout.maximumWidth: root.maxLabelWidth
            visible: root.label !== ""
        }
    }
}
```

`radius: implicitHeight / 2` keeps the pill shape as height changes. `Layout.maximumWidth` with `Text.ElideRight` protects the bar from unbounded labels.

Material Symbols uses ligatures — a readable name like `wifi`, `volume_up`, or `music_note` renders as an icon when the font is installed. Reach for a Nerd Font glyph only when the project already depends on it or the set lacks the symbol.

### Bar — one window per screen without duplicated work

Shared sources live outside `Variants`. Each monitor gets the same visual tree.

```qml
// Bar.qml
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    // Shared sources here, outside Variants.
    // Poller { id: clock; command: "date +%H:%M"; interval: 60000 }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 58
            color: "transparent"
            margins { top: 12; left: 20; right: 20 }

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                // workspace elements
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                // Pill { icon: "schedule"; label: clock.value }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                // volume, battery, network
            }
        }
    }
}
```

`PanelWindow` reserves space by default. Side margins should match compositor gaps only when that alignment is intentional.

### Command source — small, replaceable

The `value` property is the boundary between the command and the UI.

```qml
// Poller.qml
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property string command: ""
    property int interval: 3000
    property string value: ""

    Process {
        id: process
        command: ["sh", "-c", root.command]
        running: true
        stdout: StdioCollector { onStreamFinished: root.value = this.text.trim() }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: process.running = true
    }
}
```

Pass shell syntax through `sh -c` for pipes and redirects. For a fixed command without shell syntax, give every argument directly to `Process.command`.

Choose intervals by how fast the data moves — a minute for a clock without seconds, 30 seconds for battery. High-frequency state belongs on a native service, not a faster timer. Handle empty output in the visual.

### Native data for stateful UI

Polling gets a first element working. Native services give prompt updates without fragile parsing.

- **Clock.** Use `SystemClock`, format its `date`, and set precision to match what you display.
- **Media.** Import `Quickshell.Services.Mpris`, pick the playing player first, then bind to `trackArtist` and `trackTitle`. Provide a paused and a no-player label. Never hard-code a player index.
- **Hyprland workspaces.** Import `Quickshell.Hyprland`, repeat `Hyprland.workspaces`, bind each delegate to `modelData.active`. Decide upfront whether to show all workspaces, only one monitor's, or to exclude specials.

```qml
Repeater {
    model: Hyprland.workspaces
    delegate: Rectangle {
        required property var modelData
        implicitWidth: modelData.active ? 11 : 6
        implicitHeight: 6
        radius: implicitHeight / 2
        color: modelData.active ? "transparent" : "#4a5a58"
        border.width: modelData.active ? 2 : 0
        border.color: "#8ec07c"
        Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
}
```

One `active` binding drives size and appearance. The short width animation makes the change readable without busying the bar.

### Coherence

- Reuse one set of heights, padding, spacing, text sizes, and colors through the theme singleton.
- Use one label font and one icon font. Confirm the icon font is installed before relying on ligatures.
- Keep capsule height and inter-group spacing consistent.
- Give media, network, and hardware an explicit empty state — a blank element looks broken.
- Keep commands and paths portable. `BAT0`, `wpctl`, `nmcli`, and `bluetoothctl` vary by machine.

## Reference links

- [Quickshell introduction](https://quickshell.org/docs/v0.3.0/guide/introduction/)
- [Type reference](https://quickshell.org/docs/v0.3.0/types/)
- [Qt QML documents](https://doc.qt.io/qt-6/qtqml-documents-topic.html)
- [Qt item size and positioning](https://doc.qt.io/qt-6/qtquick-positioning.html)
