import ".."
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  implicitWidth: row.implicitWidth + Config.moduleHPadding * 2
  implicitHeight: Config.barHeight

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Text {
      text: Qt.formatDateTime(clock.date, "hh:mm")
      color: Colors.foreground
      font: Config.font
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
