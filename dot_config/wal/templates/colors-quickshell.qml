pragma Singleton
import Quickshell
import QtQuick

Singleton {
  id: root
  readonly property color bg: "{background}"
  readonly property color surface: "{background}"
  readonly property color fg: "{foreground}"
  readonly property color muted: "{color8}"
  readonly property color accent: "{color4}"
  readonly property color border: "{color1}"
  readonly property color error: "{color1}"
  readonly property color warning: "{color3}"
  readonly property color success: "{color2}"
  readonly property int radiusSm: 4
  readonly property int radiusMd: 12
  readonly property int radiusLg: 999
  readonly property int spXs: 4
  readonly property int spSm: 8
  readonly property int spMd: 12
  readonly property int spLg: 16
  readonly property int spXl: 24
  readonly property string fontFamily: "Lilex"
  readonly property string iconFont: "JetBrainsMono Nerd Font"
  readonly property real fontSize: 12
}