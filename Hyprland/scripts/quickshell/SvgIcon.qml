import QtQuick
import QtQuick.Shapes

// =========================================================
// SVG Icon Component — renders vector paths like website icons
// Uses Qt Quick Shapes PathSvg for crisp, scalable rendering.
// SVG paths use a 24x24 coordinate space (Lucide/Feather standard).
// The component auto-scales to iconSize while preserving the
// coordinate space internally.
//
// Usage:
//   SvgIcon {
//       path: "M6 9h12v7... M16 9h2a2..."
//       iconSize: 22
//       iconColor: mocha.text
//       opacity: isActive ? 1.0 : 0.4
//   }
// =========================================================
Item {
    id: root

    property string path: ""
    property real iconSize: 22
    property color iconColor: "#cdd6f4"
    property real strokeW: 2.0

    // Logical size matches requested iconSize; anchors.centerIn
    // uses this logical size, so parent containers center correctly.
    width: iconSize
    height: iconSize

    // Scale: map SVG 24x24 coordinate space → iconSize pixels
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.iconSize / 24
        yScale: root.iconSize / 24
    }

    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on iconColor { ColorAnimation { duration: 200 } }

    // Internal Shape always uses 24x24 (the SVG path coordinate space)
    Shape {
        x: (root.width - 24) / 2
        y: (root.height - 24) / 2
        width: 24
        height: 24
        antialiasing: true
        layer.enabled: true
        layer.samples: 8

        ShapePath {
            strokeColor: root.iconColor
            strokeWidth: root.strokeW
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.path }
        }
    }
}
