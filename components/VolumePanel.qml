import ".."
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "volume"
  contentWidth: 360
  contentHeight: 460

  property var sink: Pipewire.defaultAudioSink
  property var source: Pipewire.defaultAudioSource
  property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

  readonly property bool sinkReady: sink && sink.ready
  readonly property bool sourceReady: source && source.ready
  readonly property bool outMuted: sinkReady && sink.audio.muted
  readonly property bool inMuted: sourceReady && source.audio.muted
  readonly property int outVol: sinkReady ? Math.round(sink.audio.volume * 100) : 0
  readonly property int inVol: sourceReady ? Math.round(source.audio.volume * 100) : 0
  readonly property string outIcon: {
    if (!sinkReady) return "volume_off"
    if (outMuted || outVol === 0) return "volume_off"
    if (outVol < 34) return "volume_down"
    return "volume_up"
  }
  readonly property string inIcon: {
    if (!sourceReady) return "mic_off"
    if (inMuted || inVol === 0) return "mic_off"
    return "mic"
  }
  readonly property real outFraction: sinkReady ? (outMuted ? 0 : outVol / 100) : 0
  readonly property real inFraction: sourceReady ? (inMuted ? 0 : inVol / 100) : 0

  readonly property var candidateSinks: {
    let list = []
    for (let i = 0; i < nodes.length; i++) {
      let n = nodes[i]
      if (n && n.isSink && !n.isStream) list.push(n)
    }
    return list
  }
  readonly property var candidateSources: {
    let list = []
    for (let i = 0; i < nodes.length; i++) {
      let n = nodes[i]
      if (!n || n.isSink || n.isStream) continue
      if (String(n.name || "") === "quickshell") continue
      if (!n.audio) continue
      list.push(n)
    }
    return list
  }
  readonly property var candidateStreams: {
    let list = []
    for (let i = 0; i < nodes.length; i++) {
      let n = nodes[i]
      if (!n || !n.isStream || !n.isSink) continue
      if (!n.audio) continue
      if (String(n.name || "").indexOf("omarchy_speaker_tuning") === 0) continue
      list.push(n)
    }
    return list
  }
  readonly property var audioSinks: {
    let list = candidateSinks.slice()
    if (sink && list.indexOf(sink) < 0) list.unshift(sink)
    return list
  }
  readonly property var audioSources: {
    let list = candidateSources.slice()
    if (source && list.indexOf(source) < 0) list.unshift(source)
    return list
  }
  readonly property var audioStreams: {
    let list = []
    for (let i = 0; i < candidateStreams.length; i++) {
      if (candidateStreams[i].audio) list.push(candidateStreams[i])
    }
    return list
  }

  function friendlyLabel(text) {
    let label = String(text || "").trim()
    label = label.replace(/^sof-soundwire\s+/i, "")
    label = label.replace(/^Built-in Audio\s+/i, "")
    return label
  }

  function nodeLabel(node) {
    if (!node) return "Unknown"
    let p = node.properties || {}
    let nick = friendlyLabel(node.nickname || p["node.nick"] || "")
    if (nick) return nick
    return friendlyLabel(node.description || p["node.description"] || node.name || "Unknown")
  }

  function streamBaseLabel(node) {
    if (!node) return "Stream"
    let p = node.properties || {}
    let base = p["application.name"] || node.description || p["media.name"] || p["node.name"] || node.name || "Stream"
    return String(base).trim() || "Stream"
  }

  function streamDetail(node) {
    if (!node) return ""
    let p = node.properties || {}
    let base = streamBaseLabel(node)
    let generic = new Set(["audio", "playback", "audiostream", "cubeb", "audiocallbackdriver", "audio-src"])
    let media = String(p["media.name"] || "").trim()
    if (media && media !== base && !generic.has(media.toLowerCase())) return media
    let nodeName = String(p["node.name"] || "").trim()
    if (nodeName && nodeName !== base && nodeName !== media && !generic.has(nodeName.toLowerCase())) return nodeName
    let bin = String(p["application.process.binary"] || p["application.process.name"] || "").trim()
    if (bin && bin.toLowerCase() !== base.toLowerCase()) return bin
    return "#" + String(node.id)
  }

  function streamLabel(node) {
    if (!node) return "Stream"
    let base = streamBaseLabel(node)
    let count = 0
    for (let i = 0; i < root.audioStreams.length; i++) {
      if (streamBaseLabel(root.audioStreams[i]) === base) count++
    }
    if (count > 1) {
      let detail = streamDetail(node)
      if (detail) return base + " \u00B7 " + detail
    }
    return base
  }

  function isHeadphones(node) {
    if (!node) return false
    let p = node.properties || {}
    let blob = String([node.name, node.description, node.nickname, p["device.icon-name"] || ""].join(" ")).toLowerCase()
    return blob.indexOf("headphone") !== -1 || blob.indexOf("headset") !== -1 || blob.indexOf("earbud") !== -1
  }

  function sinkIcon(node) {
    if (isHeadphones(node)) return "headphones"
    let p = node.properties || {}
    let blob = String([node.name, node.description, p["device.icon-name"] || ""].join(" ")).toLowerCase()
    if (blob.indexOf("bluetooth") !== -1) return "bluetooth"
    if (blob.indexOf("hdmi") !== -1) return "tv"
    return "speaker"
  }

  function sourceIcon(node) {
    let p = node ? node.properties || {} : {}
    let blob = String([node ? node.name : "", p["device.icon-name"] || ""].join(" ")).toLowerCase()
    if (blob.indexOf("bluetooth") !== -1) return "bluetooth"
    if (blob.indexOf("webcam") !== -1 || blob.indexOf("camera") !== -1) return "videocam"
    return "mic"
  }

  function setOutputFraction(f) {
    if (!root.sinkReady) return
    let clamped = Math.max(0, Math.min(1, f))
    root.sink.audio.volume = clamped
    if (root.outMuted && clamped > 0) root.sink.audio.muted = false
  }

  function setInputFraction(f) {
    if (!root.sourceReady) return
    let clamped = Math.max(0, Math.min(1, f))
    root.source.audio.volume = clamped
    if (root.inMuted && clamped > 0) root.source.audio.muted = false
  }

  function toggleOutputMute() {
    if (!root.sinkReady) return
    root.sink.audio.muted = !root.outMuted
  }

  function toggleInputMute() {
    if (!root.sourceReady) return
    root.source.audio.muted = !root.inMuted
  }

  function setDefaultSink(node) {
    if (!node) return
    Pipewire.preferredDefaultAudioSink = node
  }

  function setDefaultSource(node) {
    if (!node) return
    Pipewire.preferredDefaultAudioSource = node
  }

  PwObjectTracker { objects: root.candidateSinks }
  PwObjectTracker { objects: root.candidateSources }
  PwObjectTracker { objects: root.audioStreams }

  PwNodePeakMonitor {
    id: outPeakMonitor
    node: root.sink
    enabled: root.open && root.sinkReady
  }

  PwNodePeakMonitor {
    id: inPeakMonitor
    node: root.source
    enabled: root.open && root.sourceReady
  }

  Rectangle {
    id: bg
    width: 360
    height: 460
    color: Colors.background
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 8
        Text {
          text: "Audio"
          color: Colors.foreground
          font.pixelSize: 14
          font.family: Config.font.family
          font.weight: Font.Normal
        }
        Item { Layout.fillWidth: true }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Colors.border
      }

      Flickable {
        id: flick
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentCol
          width: flick.width
          spacing: 0

          // output section
          ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            spacing: 8

            Text {
              text: "OUTPUT"
              color: Colors.white
              font.pixelSize: 11
              font.family: Config.font.family
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 12

              Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Text {
                  anchors.centerIn: parent
                  text: root.outIcon
                  color: outIconMa.containsMouse ? Colors.blue : (root.outMuted ? Colors.white : Colors.foreground)
                  font.family: Config.materialSymbols.family
                  font.pixelSize: 18
                }
                MouseArea {
                  id: outIconMa
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onClicked: root.toggleOutputMute()
                }
              }

              Item {
                id: outSliderRoot
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                readonly property int trackHeight: 4
                readonly property int thumbSize: 16

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: outSliderRoot.trackHeight
                  radius: 0
                  color: Colors.card
                }
                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  width: Math.round(parent.width * root.outFraction)
                  height: outSliderRoot.trackHeight
                  radius: 0
                  color: root.outMuted ? Colors.white : Colors.blue
                  opacity: root.sinkReady ? 1 : 0.4
                  Behavior on width { NumberAnimation { duration: 40; easing.type: Easing.Linear } }
                }
                Rectangle {
                  width: outSliderRoot.thumbSize
                  height: outSliderRoot.thumbSize
                  radius: width / 2
                  color: outSliderMa.containsMouse || outSliderMa.pressed ? Colors.blue : Colors.foreground
                  border.color: outSliderMa.pressed ? Colors.foreground : Colors.transparent
                  border.width: 1
                  anchors.verticalCenter: parent.verticalCenter
                  x: Math.max(0, Math.min(parent.width - width, Math.round(parent.width * root.outFraction - width / 2)))
                  opacity: root.sinkReady ? 1 : 0.4
                  Behavior on color { ColorAnimation { duration: 90 } }
                  Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Colors.black
                    border.width: 1
                    opacity: 0.15
                    z: -1
                  }
                }
                MouseArea {
                  id: outSliderMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  preventStealing: true
                  enabled: root.sinkReady
                  function updateFromMouse(mouse) {
                    let f = mouse.x / outSliderRoot.width
                    root.setOutputFraction(f)
                  }
                  onPressed: mouse => updateFromMouse(mouse)
                  onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse) }
                  onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) root.setOutputFraction(root.outFraction + 0.05)
                    else if (wheel.angleDelta.y < 0) root.setOutputFraction(root.outFraction - 0.05)
                  }
                }
              }

              Text {
                text: root.sinkReady ? (root.outMuted ? "0%" : root.outVol + "%") : "-"
                color: Colors.white
                font.pixelSize: 12
                font.family: Config.font.family
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
              }
            }

            ObsMeter {
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              Layout.leftMargin: 34
              Layout.rightMargin: 36
              peaks: outPeakMonitor.peaks
              muted: root.outMuted || !root.sinkReady
              showTicks: true
              visible: root.sinkReady
            }

            // output device list
            ColumnLayout {
              Layout.fillWidth: true
              Layout.topMargin: 4
              spacing: 2
              visible: root.audioSinks.length > 0

              Repeater {
                model: root.audioSinks
                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  readonly property bool isActive: root.sink && modelData && root.sink.id === modelData.id
                  Layout.fillWidth: true
                  Layout.preferredHeight: 36
                  color: devHover.hovered ? Colors.surface : (isActive ? Colors.card : Colors.transparent)
                  border.color: isActive ? Colors.blue : Colors.transparent
                  border.width: isActive ? 1 : 0
                  Behavior on color { ColorAnimation { duration: 90 } }
                  HoverHandler { id: devHover }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    Text {
                      text: root.sinkIcon(modelData)
                      color: isActive ? Colors.blue : Colors.foreground
                      font.family: Config.materialSymbols.family
                      font.pixelSize: 16
                    }
                    Text {
                      text: root.nodeLabel(modelData)
                      color: isActive ? Colors.foreground : Colors.white
                      font.pixelSize: 12
                      font.family: Config.font.family
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      visible: isActive
                      text: "check"
                      color: Colors.blue
                      font.family: Config.materialSymbols.family
                      font.pixelSize: 14
                    }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.setDefaultSink(modelData)
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 12
            color: Colors.border
          }

          // input section
          ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            spacing: 8
            visible: root.source !== null || root.audioSources.length > 0

            Text {
              text: "INPUT"
              color: Colors.white
              font.pixelSize: 11
              font.family: Config.font.family
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 12
              opacity: root.sourceReady ? 1 : 0.5

              Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Text {
                  anchors.centerIn: parent
                  text: root.inIcon
                  color: inIconMa.containsMouse ? Colors.blue : (root.inMuted ? Colors.white : Colors.foreground)
                  font.family: Config.materialSymbols.family
                  font.pixelSize: 18
                }
                MouseArea {
                  id: inIconMa
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  enabled: root.sourceReady
                  onClicked: root.toggleInputMute()
                }
              }

              Item {
                id: inSliderRoot
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                readonly property int trackHeight: 4
                readonly property int thumbSize: 16

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: inSliderRoot.trackHeight
                  radius: 0
                  color: Colors.card
                }
                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  width: Math.round(parent.width * root.inFraction)
                  height: inSliderRoot.trackHeight
                  radius: 0
                  color: root.inMuted ? Colors.white : Colors.blue
                  opacity: root.sourceReady ? 1 : 0.4
                  Behavior on width { NumberAnimation { duration: 40; easing.type: Easing.Linear } }
                }
                Rectangle {
                  width: inSliderRoot.thumbSize
                  height: inSliderRoot.thumbSize
                  radius: width / 2
                  color: inSliderMa.containsMouse || inSliderMa.pressed ? Colors.blue : Colors.foreground
                  border.color: inSliderMa.pressed ? Colors.foreground : Colors.transparent
                  border.width: 1
                  anchors.verticalCenter: parent.verticalCenter
                  x: Math.max(0, Math.min(parent.width - width, Math.round(parent.width * root.inFraction - width / 2)))
                  opacity: root.sourceReady ? 1 : 0.4
                  Behavior on color { ColorAnimation { duration: 90 } }
                  Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Colors.black
                    border.width: 1
                    opacity: 0.15
                    z: -1
                  }
                }
                MouseArea {
                  id: inSliderMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  preventStealing: true
                  enabled: root.sourceReady
                  function updateFromMouse(mouse) {
                    let f = mouse.x / inSliderRoot.width
                    root.setInputFraction(f)
                  }
                  onPressed: mouse => updateFromMouse(mouse)
                  onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse) }
                  onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) root.setInputFraction(root.inFraction + 0.05)
                    else if (wheel.angleDelta.y < 0) root.setInputFraction(root.inFraction - 0.05)
                  }
                }
              }

              Text {
                text: root.sourceReady ? (root.inMuted ? "0%" : root.inVol + "%") : "-"
                color: Colors.white
                font.pixelSize: 12
                font.family: Config.font.family
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
              }
            }

            ObsMeter {
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              Layout.leftMargin: 34
              Layout.rightMargin: 36
              peaks: inPeakMonitor.peaks
              muted: root.inMuted || !root.sourceReady
              showTicks: true
              visible: root.sourceReady
            }

            Text {
              visible: !root.sourceReady
              text: "No microphone found"
              color: Colors.white
              font.pixelSize: 12
              font.family: Config.font.family
            }

            ColumnLayout {
              Layout.fillWidth: true
              Layout.topMargin: 4
              spacing: 2
              visible: root.audioSources.length > 0

              Repeater {
                model: root.audioSources
                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  readonly property bool isActive: root.source && modelData && root.source.id === modelData.id
                  Layout.fillWidth: true
                  Layout.preferredHeight: 36
                  color: inDevHover.hovered ? Colors.surface : (isActive ? Colors.card : Colors.transparent)
                  border.color: isActive ? Colors.blue : Colors.transparent
                  border.width: isActive ? 1 : 0
                  Behavior on color { ColorAnimation { duration: 90 } }
                  HoverHandler { id: inDevHover }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    Text {
                      text: root.sourceIcon(modelData)
                      color: isActive ? Colors.blue : Colors.foreground
                      font.family: Config.materialSymbols.family
                      font.pixelSize: 16
                    }
                    Text {
                      text: root.nodeLabel(modelData)
                      color: isActive ? Colors.foreground : Colors.white
                      font.pixelSize: 12
                      font.family: Config.font.family
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      visible: isActive
                      text: "check"
                      color: Colors.blue
                      font.family: Config.materialSymbols.family
                      font.pixelSize: 14
                    }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.setDefaultSource(modelData)
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 12
            color: Colors.border
            visible: root.audioStreams.length > 0
          }

          // per-app streams
          ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            Layout.bottomMargin: 16
            spacing: 8
            visible: root.audioStreams.length > 0

            Text {
              text: "APPS"
              color: Colors.white
              font.pixelSize: 11
              font.family: Config.font.family
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Repeater {
                model: root.audioStreams
                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  readonly property bool sMuted: modelData && modelData.audio ? modelData.audio.muted : false
                  readonly property real sVol: modelData && modelData.audio ? modelData.audio.volume : 0
                  readonly property real sFraction: sMuted ? 0 : Math.min(1, sVol / 1.5)
                  Layout.fillWidth: true
                  Layout.preferredHeight: 72
                  color: streamHover.hovered ? Colors.surface : Colors.card
                  border.color: Colors.border
                  border.width: 1
                  Behavior on color { ColorAnimation { duration: 90 } }
                  HoverHandler { id: streamHover }

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 6

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 8

                      Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        Text {
                          anchors.centerIn: parent
                          text: sMuted ? "volume_off" : "volume_up"
                          color: streamIconMa.containsMouse ? Colors.blue : (sMuted ? Colors.white : Colors.foreground)
                          font.family: Config.materialSymbols.family
                          font.pixelSize: 14
                        }
                        MouseArea {
                          id: streamIconMa
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          hoverEnabled: true
                          onClicked: {
                            if (modelData && modelData.audio) modelData.audio.muted = !modelData.audio.muted
                          }
                        }
                      }

                      Text {
                        text: root.streamLabel(modelData)
                        color: Colors.foreground
                        font.pixelSize: 12
                        font.family: Config.font.family
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }

                      Text {
                        text: sMuted ? "0%" : Math.round(sVol * 100) + "%"
                        color: Colors.white
                        font.pixelSize: 11
                        font.family: Config.font.family
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                      }
                    }

                    Item {
                      id: streamSliderRoot
                      Layout.fillWidth: true
                      Layout.preferredHeight: 16
                      readonly property int trackHeight: 3
                      readonly property int thumbSize: 12

                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: streamSliderRoot.trackHeight
                        radius: 0
                        color: Colors.background
                      }
                      Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        width: Math.round(parent.width * sFraction)
                        height: streamSliderRoot.trackHeight
                        radius: 0
                        color: sMuted ? Colors.white : Colors.blue
                        Behavior on width { NumberAnimation { duration: 40; easing.type: Easing.Linear } }
                      }
                      Rectangle {
                        width: streamSliderRoot.thumbSize
                        height: streamSliderRoot.thumbSize
                        radius: width / 2
                        color: streamSliderMa.containsMouse || streamSliderMa.pressed ? Colors.blue : Colors.foreground
                        border.color: streamSliderMa.pressed ? Colors.foreground : Colors.transparent
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, Math.round(parent.width * sFraction - width / 2)))
                        Behavior on color { ColorAnimation { duration: 90 } }
                      }
                      MouseArea {
                        id: streamSliderMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        function updateFromMouse(mouse) {
                          let f = mouse.x / streamSliderRoot.width
                          let clamped = Math.max(0, Math.min(1.5, f * 1.5))
                          if (modelData && modelData.audio) {
                            modelData.audio.volume = clamped
                            if (sMuted && clamped > 0) modelData.audio.muted = false
                          }
                        }
                        onPressed: mouse => updateFromMouse(mouse)
                        onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse) }
                        onWheel: wheel => {
                          if (!modelData || !modelData.audio) return
                          let next = sVol + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)
                          modelData.audio.volume = Math.max(0, Math.min(1.5, next))
                        }
                      }
                    }

                    ObsMeter {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 9
                      peaks: streamPeak.peaks
                      muted: sMuted
                      showTicks: false
                    }
                  }

                  PwNodePeakMonitor {
                    id: streamPeak
                    node: modelData
                    enabled: root.open && modelData && modelData.ready
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
