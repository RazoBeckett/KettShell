import "../.."
import QtQuick

Text {
  id: root

  property bool useMono: false
  property real size: Typography.sans.pixelSize
  property int weight: Font.Normal

  color: Colors.foreground
  font.family: root.useMono ? Typography.mono.family : Typography.sans.family
  font.pixelSize: root.size
  font.weight: root.weight
}
