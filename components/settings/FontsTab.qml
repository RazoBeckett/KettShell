import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property bool editingFont: false
  property real editProgress: editingFont ? 1 : 0
  Behavior on editProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function commitFont(): void {
    let t = fontField.text.trim()
    if (t !== "") Settings.ui.fontFamily = t
    else fontField.text = Settings.ui.fontFamily
    editingFont = false
  }

  function cancelFont(): void {
    fontField.text = Settings.ui.fontFamily
    editingFont = false
  }

  function startEdit(): void {
    fontField.text = Settings.ui.fontFamily
    fontField.cursorPosition = fontField.text.length
    editingFont = true
    fontField.forceActiveFocus()
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Interface font"
        color: Colors.foreground
        font: Typography.font
        Layout.fillWidth: true
      }

      Text {
        text: Settings.ui.fontFamily
        color: Colors.white
        font: Typography.font
        elide: Text.ElideRight
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        id: fontBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingFont || fieldMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingFont ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: fontField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          clip: true
          enabled: root.editingFont
          selectByMouse: true
          text: Settings.ui.fontFamily
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.font.family
          font.pixelSize: Typography.font.pixelSize
          font.weight: Typography.font.weight
          onAccepted: root.commitFont()
          Keys.onEscapePressed: event => {
            root.cancelFont()
            event.accepted = true
          }
        }

        MouseArea {
          id: fieldMa
          anchors.fill: parent
          enabled: !root.editingFont
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
        visible: root.editingFont || root.editProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.editProgress) * 28

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: cancelMa.containsMouse ? Colors.red : Colors.transparent
            border.color: cancelMa.containsMouse ? Colors.red : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "x"
              color: cancelMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelFont()
            }
          }

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: saveMa.containsMouse ? Colors.green : Colors.transparent
            border.color: saveMa.containsMouse ? Colors.green : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "check"
              color: saveMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: saveMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.commitFont()
            }
          }
        }
      }
    }

    Text {
      text: "Type a family installed on your system. Applies everywhere at once."
      color: Colors.white
      font: Typography.font
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 64
      Layout.topMargin: 6
      radius: Settings.rounding.md
      color: Colors.surface
      border.color: Colors.border
      border.width: 1
      clip: true

      Text {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: Text.AlignVCenter
        text: "Ag " + Settings.ui.fontFamily
        color: Colors.foreground
        font.family: Settings.ui.fontFamily
        font.pixelSize: 22
        font.weight: Typography.font.weight
        elide: Text.ElideRight
      }
    }
  }
}
