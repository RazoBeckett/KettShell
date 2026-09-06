import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property bool editingDir: false
  property real editProgress: editingDir ? 1 : 0
  Behavior on editProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function commitDir(): void {
    let t = dirField.text.trim()
    if (t !== "") Settings.wallpaper.directory = t
    else dirField.text = Settings.wallpaper.directory
    editingDir = false
  }

  function cancelDir(): void {
    dirField.text = Settings.wallpaper.directory
    editingDir = false
  }

  function startEdit(): void {
    dirField.text = Settings.wallpaper.directory
    dirField.cursorPosition = dirField.text.length
    editingDir = true
    dirField.forceActiveFocus()
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Library"
        color: Colors.foreground
        font: Config.font
        Layout.fillWidth: true
      }

      Text {
        text: Wallpapers.all.length + " images"
        color: Colors.white
        font: Config.font
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        id: dirBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        color: root.editingDir || fieldMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingDir ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: dirField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          clip: true
          enabled: root.editingDir
          selectByMouse: true
          text: Settings.wallpaper.directory
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Config.font.family
          font.pixelSize: Config.font.pixelSize
          font.weight: Config.font.weight
          onAccepted: root.commitDir()
          Keys.onEscapePressed: event => {
            root.cancelDir()
            event.accepted = true
          }
        }

        MouseArea {
          id: fieldMa
          anchors.fill: parent
          enabled: !root.editingDir
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEdit()
        }
      }

      Item {
        id: buttonsWrap
        Layout.preferredWidth: 80 * root.editProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingDir || root.editProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.editProgress) * 28

          Rectangle {
            width: 32
            height: 32
            color: cancelMa.containsMouse ? Colors.red : Colors.transparent
            border.color: cancelMa.containsMouse ? Colors.red : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "close"
              color: cancelMa.containsMouse ? Colors.black : Colors.white
              font.family: Config.materialSymbols.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelDir()
            }
          }

          Rectangle {
            width: 32
            height: 32
            color: saveMa.containsMouse ? Colors.green : Colors.transparent
            border.color: saveMa.containsMouse ? Colors.green : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "check"
              color: saveMa.containsMouse ? Colors.black : Colors.white
              font.family: Config.materialSymbols.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: saveMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.commitDir()
            }
          }
        }
      }
    }
  }

  SettingsRow {
    title: "Current"
    subtitle: Wallpapers.current ? Wallpapers.fileName(Wallpapers.current) : "-"
    Layout.fillWidth: true
  }

  SettingsRow {
    title: "Wipe angle"
    subtitle: Settings.wallpaper.wipeDeg + " degrees"
    Layout.fillWidth: true

    Slider {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter
      fraction: Settings.wallpaper.wipeDeg / 360
      onMoved: f => Settings.wallpaper.wipeDeg = Math.round(f * 360)
    }
  }
}
