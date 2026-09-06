import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property bool editingDir: false

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
      spacing: 8

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        color: root.editingDir ? Colors.surface : Colors.transparent
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
      }

      Rectangle {
        id: editBtn
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        visible: !root.editingDir
        color: editMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "edit"
          color: editMa.containsMouse ? Colors.foreground : Colors.white
          font.family: Config.materialSymbols.family
          font.pixelSize: 16
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
          id: editMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            dirField.text = Settings.wallpaper.directory
            dirField.cursorPosition = dirField.text.length
            root.editingDir = true
            dirField.forceActiveFocus()
          }
        }
      }

      Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        visible: root.editingDir
        color: cancelMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "close"
          color: cancelMa.containsMouse ? Colors.foreground : Colors.white
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
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        visible: root.editingDir
        color: saveMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          anchors.centerIn: parent
          text: "check"
          color: saveMa.containsMouse ? Colors.foreground : Colors.white
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
      anchors.fill: parent
      fraction: Settings.wallpaper.wipeDeg / 360
      onMoved: f => Settings.wallpaper.wipeDeg = Math.round(f * 360)
    }
  }
}


