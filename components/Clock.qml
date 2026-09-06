import ".."
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  implicitWidth: row.implicitWidth + 26
  implicitHeight: 30

  property string displayText: Qt.formatDateTime(clock.date, "hh:mm")

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6

    // crossfade host — previous fades out upward, new fades in from below
    Item {
      id: tickHost
      implicitWidth: incoming.implicitWidth
      implicitHeight: incoming.implicitHeight
      clip: true

      property string pendingText: root.displayText
      // triggers tick when minute changes
      onPendingTextChanged: if (outgoing.text !== "" && pendingText !== outgoing.text) tickAnim.restart()

      Text {
        id: outgoing
        anchors.centerIn: parent
        text: root.displayText
        color: Colors.foreground
        font: Config.font
        opacity: 1
        y: 0
      }

      Text {
        id: incoming
        anchors.centerIn: parent
        text: root.displayText
        color: Colors.foreground
        font: Config.font
        opacity: 0
        y: 6
        visible: false
      }

      SequentialAnimation {
        id: tickAnim
        onStarted: {
          incoming.text = tickHost.pendingText
          incoming.visible = true
          incoming.opacity = 0
          incoming.y = 6
          outgoing.y = 0
          outgoing.opacity = 1
        }
        ParallelAnimation {
          NumberAnimation { target: outgoing; property: "opacity"; to: 0; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: outgoing; property: "y"; to: -4; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: incoming; property: "opacity"; to: 1; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: incoming; property: "y"; to: 0; duration: 230; easing.type: Easing.OutCubic }
        }
        onStopped: {
          outgoing.text = tickHost.pendingText
          outgoing.opacity = 1
          outgoing.y = 0
          incoming.visible = false
          incoming.opacity = 0
          incoming.y = 6
        }
      }

      Component.onCompleted: outgoing.text = root.displayText
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
