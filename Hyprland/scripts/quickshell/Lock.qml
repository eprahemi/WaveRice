import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../"

ShellRoot {
    id: root
    MatugenColors { id: _theme }

    readonly property color base:     _theme.base
    readonly property color crust:    _theme.crust
    readonly property color mantle:   _theme.mantle
    readonly property color text:     _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay2: _theme.overlay2
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color mauve:    _theme.mauve
    readonly property color red:      _theme.red
    readonly property color peach:    _theme.peach
    readonly property color blue:     _theme.blue
    readonly property color green:    _theme.green

    // ── Session Settings ──────────────────────────────────────────────────────
    QtObject {
        id: lockSettings

        property bool hidePassword:   false
        property int  revealDuration: 300
    }

    // ── Shared UI State ───────────────────────────────────────────────────────
    QtObject {
        id: lockUI
        property bool   failed:         false
        property bool   authenticating: false
        property string statusText:     "Fuckened"

    }

    Timer {
        id: pamActionTimer
        interval: 50
        onTriggered: pam.start()
    }

    PamContext {
        id: pam
        Component.onCompleted: pamActionTimer.start()
        onCompleted: (result) => {
            lockUI.authenticating = false
            if (result === PamResult.Success) {
                rootLock.locked = false
                Qt.quit()
            } else {
                lockUI.failed = true
                lockUI.statusText = "Fuckcess Denied"
            
                pamActionTimer.start()
            }
        }
    }

    Process { id: suspendProcess; command: ["systemctl", "suspend"]  }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    Process { id: reloadProcess; command: ["systemctl", "reboot"]   }
    Process { id: playPauseProcess; command: ["bash", "-c", "/home/eprahemi/.config/hypr/scripts/quickshell/music_control.sh toggle"] }
    Process { id: nextProcess; command: ["bash", "-c", "/home/eprahemi/.config/hypr/scripts/quickshell/music_control.sh next"] }
    Process { id: prevProcess; command: ["bash", "-c", "/home/eprahemi/.config/hypr/scripts/quickshell/music_control.sh prev"] }
    Process { id: muteProcess; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }

    property bool isMuted: false
    property real volumePercent: 1.0
    property real pwVolume: 0.5
    Process {
        id: muteCheck
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | head -1 | awk '{print $2, $3}'"]
        stdout: StdioCollector { onStreamFinished: { let parts = this.text.trim().split(/\s+/); let v = parseFloat(parts[0]); if (!isNaN(v)) root.volumePercent = v; root.isMuted = (parts[1] || "").indexOf("MUTED") >= 0 } }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: muteCheck.running = true }

    // ═════════════════════════════════════════════════════════════════════════
    WlSessionLock {
        id: rootLock
        locked: true

        WlSessionLockSurface {
            id: surface

            Item {
                id: screenRoot

                anchors.fill: parent

                Scaler {
                    id: scaler
                    currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width
                }
                readonly property real sc: scaler.baseScale

                // ── Data properties ───────────────────────────────────────────
                property string staticWallpaperPath: "file:///usr/share/wallpapers/lock.png"
                property string batPct:     "100"
                property string batStatus:   "AC"
                property string currentUser: "User"
                property string faceIconPath: ""
                property string kbLayout:    "US"
                property string weatherIcon: ""
                property string weatherTemp: "--°C"
                property string hostname:    ""
                property string uptimeStr:   ""
                property bool   networkOnline: true

                property bool   capsLockOn:    false
                property real   exitState:      0.0

                // ── Mouse tracking ──────────────────────────────────────────
                property real mouseX: parent.width / 2
                property real mouseY: parent.height / 2

                // ── Luxury color cycle (Gold → Rose → Mauve → Violet → Blue → Teal) ──
                property real luxuryPhase: 0.0
                NumberAnimation on luxuryPhase {
                    from: 0; to: 1; duration: 12000; loops: Animation.Infinite; running: true
                }

                function luxuryColor(phaseOffset, alpha) {
                    var t = ((luxuryPhase + phaseOffset) % 1.0 + 1.0) % 1.0
                    var n = 6
                    var colors = [
                        [1.00, 0.78, 0.18],
                        [0.96, 0.52, 0.60],
                        [0.87, 0.63, 0.87],
                        [0.55, 0.30, 0.90],
                        [0.25, 0.55, 0.98],
                        [0.15, 0.80, 0.72],
                    ]
                    var raw = t * n
                    var i0 = Math.floor(raw) % n
                    var i1 = (i0 + 1) % n
                    var f = raw - Math.floor(raw)
                    f = f * f * (3.0 - 2.0 * f)
                    var c0 = colors[i0], c1 = colors[i1]
                    return Qt.rgba(
                        c0[0] + (c1[0] - c0[0]) * f,
                        c0[1] + (c1[1] - c0[1]) * f,
                        c0[2] + (c1[2] - c0[2]) * f,
                        alpha !== undefined ? alpha : 1.0
                    )
                }

                // ── Per-character clock wiggle — original relaxing speed, continuous ────
                property real wiggleT: 0.0
                NumberAnimation on wiggleT {
                    from: 0; to: 1000; duration: 5000000; loops: Animation.Infinite; running: true
                }

                property real wiggleH1X: 0; property real wiggleH1Y: 0; property real wiggleH1Angle: 0; property real wiggleH1Sq: 1.0
                property real wiggleH2X: 0; property real wiggleH2Y: 0; property real wiggleH2Angle: 0; property real wiggleH2Sq: 1.0
                property real wiggleM1X: 0; property real wiggleM1Y: 0; property real wiggleM1Angle: 0; property real wiggleM1Sq: 1.0
                property real wiggleM2X: 0; property real wiggleM2Y: 0; property real wiggleM2Angle: 0; property real wiggleM2Sq: 1.0

                Timer {
                    interval: 16; running: true; repeat: true
                    onTriggered: {
                        let t = screenRoot.wiggleT
                        let s = screenRoot.sc
                        screenRoot.wiggleH1X = Math.sin(t * Math.PI * 2.1 + 0.0) * 1.8 * s
                        screenRoot.wiggleH1Y = Math.cos(t * Math.PI * 1.7 + 0.3) * 1.2 * s
                        screenRoot.wiggleH1Angle = Math.sin(t * Math.PI * 1.1 + 0.5) * 0.4
                        screenRoot.wiggleH1Sq = 1.0 + Math.sin(t * Math.PI * 2.7 + 0.0) * 0.012

                        screenRoot.wiggleH2X = Math.sin(t * Math.PI * 2.1 + 0.8) * 1.8 * s
                        screenRoot.wiggleH2Y = Math.cos(t * Math.PI * 1.7 + 1.1) * 1.2 * s
                        screenRoot.wiggleH2Angle = Math.sin(t * Math.PI * 1.1 + 1.3) * 0.4
                        screenRoot.wiggleH2Sq = 1.0 + Math.sin(t * Math.PI * 2.7 + 0.7) * 0.012

                        screenRoot.wiggleM1X = Math.sin(t * Math.PI * 2.1 + 2.0) * 1.8 * s
                        screenRoot.wiggleM1Y = Math.cos(t * Math.PI * 1.7 + 2.3) * 1.2 * s
                        screenRoot.wiggleM1Angle = Math.sin(t * Math.PI * 1.1 + 2.5) * 0.4
                        screenRoot.wiggleM1Sq = 1.0 + Math.sin(t * Math.PI * 2.7 + 1.4) * 0.012

                        screenRoot.wiggleM2X = Math.sin(t * Math.PI * 2.1 + 2.8) * 1.8 * s
                        screenRoot.wiggleM2Y = Math.cos(t * Math.PI * 1.7 + 3.1) * 1.2 * s
                        screenRoot.wiggleM2Angle = Math.sin(t * Math.PI * 1.1 + 3.7) * 0.4
                        screenRoot.wiggleM2Sq = 1.0 + Math.sin(t * Math.PI * 2.7 + 2.1) * 0.012
                    }
                }

                // ── UI states ─────────────────────────────────────────────────
                property real introState:     0.0
                property bool powerMenuOpen:  false
                property bool inputActive:    false

                property bool isPlayingIntro: true
                property bool isDesktop:      false

                // ── Global orbit angle — original 140s speed, continuous no snap ──
                property real globalOrbitAngle: 0
                NumberAnimation on globalOrbitAngle {
                    from: 0; to: 10000; duration: 700000000; loops: Animation.Infinite; running: true
                }

                Component.onCompleted: introSequence.start()

                // Auto-hide input if idle
                Timer {
                    id: idleTimer
                    interval: 15000
                    running: screenRoot.inputActive && inputField.text.length === 0
                    repeat: false
                    onTriggered: screenRoot.inputActive = false
                }

                // ── DATA POLLERS ──────────────────────────────────────────────

                Process {
                    id: chassisDetector; running: true
                    command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1>/dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                    stdout: StdioCollector { onStreamFinished: screenRoot.isDesktop = (this.text.trim() === "desktop") }
                }

                Process {
                    id: userPoller
                    command: ["bash", "-c",
                        "USER_VAR=$(whoami); ICON_PATH=''; " +
                        "if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); " +
                        "elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; " +
                        "echo -n \"$USER_VAR|$ICON_PATH\""]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let parts = this.text.trim().split("|")
                            if (parts.length > 0 && parts[0] !== "")
                                screenRoot.currentUser = parts[0]
                            if (parts.length > 1 && parts[1].trim() !== "") {
                                let p = parts[1].trim()
                                screenRoot.faceIconPath = p.startsWith("file://") ? p : "file://" + p
                            }
                        }
                    }
                    Component.onCompleted: running = true
                }

                Process {
                    id: kbPoller
                    command: ["bash", "-c",
                        "hyprctl devices -j | jq -r '.keyboards[] | select(.main==true) | .active_keymap'" +
                        " | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let l = this.text.trim()
                            if (l !== "" && l !== "null") screenRoot.kbLayout = l
                        }
                    }
                }
                Timer { interval: 150; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbPoller.running = true }

                Process {
                    id: batPoller
                    running: !screenRoot.isDesktop
                    command: ["bash", "-c",
                        "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100';" +
                        "cat /sys/class/power_supply/BAT*/status  2>/dev/null | head -n1 || echo 'AC'"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n")
                            if (lines.length >= 2) {
                                screenRoot.batPct    = lines[0] || "100"
                                screenRoot.batStatus = lines[1] || "Unknown"
                            }
                        }
                    }
                }
                Timer { interval: 5000; running: !screenRoot.isDesktop; repeat: true; triggeredOnStart: true; onTriggered: batPoller.running = true }

                Process {
                    id: weatherPoller
                    property string scriptPath: Qt.resolvedUrl("calendar/weather.sh").toString().replace(/^file:\/\//, "")
                    command: ["bash", "-c", '"' + scriptPath + '" --current-icon; "' + scriptPath + '" --current-temp']
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n")
                            if (lines.length >= 2) {
                                screenRoot.weatherIcon = lines[0] || ""
                                screenRoot.weatherTemp = lines[1] || "--°C"
                            }
                        }
                    }
                }
                Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

                // Hostname
    Process {
        id: volumeSet
        command: ["bash", "-c", "SINK_ID=$(pactl list sink-inputs 2>/dev/null | grep -B20 'pw-play' | grep 'Sink Input #' | head -1 | grep -o '[0-9][0-9]*') && pactl set-sink-input-volume \"$SINK_ID\" \"100%\""]
    }

                // Uptime (compact format)
                Process {
                    id: uptimePoller
                    command: ["bash", "-c",
                        "uptime -p | sed 's/up //' | sed 's/ hours\\?/h/g' | sed 's/ minutes\\?/m/g'" +
                        " | sed 's/ days\\?/d/g' | cut -c1-20"]
                    stdout: StdioCollector { onStreamFinished: screenRoot.uptimeStr = this.text.trim() }
                }
                Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: uptimePoller.running = true }

                // Network connectivity
                Process {
                    id: networkPoller
                    command: ["bash", "-c", "ip route get 1.1.1.1 >/dev/null 2>&1 && echo 'online' || echo 'offline'"]
                    stdout: StdioCollector { onStreamFinished: screenRoot.networkOnline = (this.text.trim() === "online") }
                }
                Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: networkPoller.running = true }

                // Caps Lock state
                Process {
                    id: capsPoller
                    command: ["bash", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -1 || echo 0"]
                    stdout: StdioCollector { onStreamFinished: screenRoot.capsLockOn = parseInt(this.text.trim()) > 0 }
                }
                Timer { interval: 500; running: true; repeat: true; onTriggered: capsPoller.running = true }

                // ═════════════════════════════════════════════════════════════
                // 1. BACKGROUND — 3D parallax wallpaper + blur + vignette + orbs
                // ═════════════════════════════════════════════════════════════
                Rectangle { anchors.fill: parent; color: root.base }

                // 3D Parallax Wallpaper — scaled 14% for depth movement
                Item {
                    anchors.fill: parent
                    clip: true

                    Image {
                        id: bgWallpaper
                        x: parent.width/2 - width/2 + ((screenRoot.mouseX / parent.width) - 0.5) * (-60 * screenRoot.sc)
                        y: parent.height/2 - height/2 + ((screenRoot.mouseY / parent.height) - 0.5) * (-40 * screenRoot.sc)
                        width: parent.width * 1.14
                        height: parent.height * 1.14
                        source: screenRoot.staticWallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; visible: false; cache: false

                        // Subtle scale shift for 3D depth illusion
                        transform: Scale {
                            xScale: 1.0 + ((screenRoot.mouseX / parent.width) - 0.5) * 0.015
                            yScale: 1.0 + ((screenRoot.mouseY / parent.height) - 0.5) * 0.015
                        }

                        Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                    MultiEffect {
                        source: bgWallpaper; anchors.fill: bgWallpaper
                        blurEnabled: true; blurMax: 50 * screenRoot.sc; blur: 1.0
                    }
                }

                // Top-to-bottom gradient: deep at edges, clear center
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.65) }
                        GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.12) }
                        GradientStop { position: 0.70; color: Qt.rgba(0, 0, 0, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.70) }
                    }
                }

                // Horizontal vignette (sides darkened)
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var lg  = ctx.createLinearGradient(0, 0, width, 0)
                        lg.addColorStop(0.0,  Qt.rgba(0,0,0,0.50).toString())
                        lg.addColorStop(0.18, Qt.rgba(0,0,0,0.0).toString())
                        lg.addColorStop(0.82, Qt.rgba(0,0,0,0.0).toString())
                        lg.addColorStop(1.0,  Qt.rgba(0,0,0,0.50).toString())
                        ctx.fillStyle = lg
                        ctx.fillRect(0, 0, width, height)
                    }
                }

                // Mouse-following ambient light
                Canvas {
                    anchors.fill: parent
                    opacity: screenRoot.introState * 0.35

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var mx = screenRoot.mouseX, my = screenRoot.mouseY
                        var grad = ctx.createRadialGradient(mx, my, 0, mx, my, 350 * screenRoot.sc)
                        var lc = screenRoot.luxuryColor(0.00, 0.08)
                        var r = Math.floor(lc.r * 255), g = Math.floor(lc.g * 255), b = Math.floor(lc.b * 255)
                        grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",1)")
                        grad.addColorStop(0.4, "rgba(" + r + "," + g + "," + b + ",0.3)")
                        grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0)")
                        ctx.fillStyle = grad
                        ctx.fillRect(0, 0, width, height)
                    }

                    Connections {
                        target: screenRoot
                        function onMouseXChanged() { requestPaint() }
                        function onMouseYChanged() { requestPaint() }
                    }
                    Connections {
                        target: screenRoot
                        function onIntroStateChanged() { requestPaint() }
                    }
                }

                // Subtle mouse trail — fading particles
                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState * 0.4

                    Repeater {
                        model: ListModel {
                            ListElement { delay: 0;   size: 5;  opacity: 0.15 }
                            ListElement { delay: 80;  size: 4;  opacity: 0.10 }
                            ListElement { delay: 160; size: 3;  opacity: 0.07 }
                            ListElement { delay: 240; size: 2.5; opacity: 0.05 }
                            ListElement { delay: 320; size: 2;  opacity: 0.03 }
                        }

                        Rectangle {
                            property real targetX: screenRoot.mouseX
                            property real targetY: screenRoot.mouseY
                            property real smoothX: targetX
                            property real smoothY: targetY
                            property real trailSq: 1.0
                            NumberAnimation on trailSq {
                                from: 1.0; to: 1.5; duration: 300 + model.delay * 2; loops: Animation.Infinite; running: true
                                easing.type: Easing.InOutSine
                            }

                            width: model.size * screenRoot.sc
                            height: width; radius: width / 2
                            color: screenRoot.luxuryColor(model.delay * 0.001, model.opacity)

                            x: smoothX - width / 2
                            y: smoothY - height / 2

                            transform: Scale { xScale: trailSq; yScale: 2.0 - trailSq; origin.x: width/2; origin.y: height/2 }

                            NumberAnimation on smoothX {
                                to: targetX; duration: 200 + model.delay; easing.type: Easing.OutCubic
                            }
                            NumberAnimation on smoothY {
                                to: targetY; duration: 200 + model.delay; easing.type: Easing.OutCubic
                            }

                            Connections {
                                target: screenRoot
                                function onMouseXChanged() { parent.smoothX = screenRoot.mouseX }
                                function onMouseYChanged() { parent.smoothY = screenRoot.mouseY }
                            }
                        }
                    }
                }

                // 5 ambient orbs with LIQUID BLOBBY TRAJECTORIES
                Item {
                    anchors.fill: parent

                    Rectangle {
                        id: orb1
                        width: parent.width * 0.75; height: width * (1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.1) * 0.06); radius: width/2
                        x: parent.width/2 - width/2 + Math.cos(screenRoot.globalOrbitAngle * 2.0) * (190*screenRoot.sc)
                        y: parent.height/2 - height/2 + Math.sin(screenRoot.globalOrbitAngle * 2.0) * (140*screenRoot.sc)
                        opacity: screenRoot.inputActive ? 0.030 : 0.065; color: root.mauve
                        Behavior on opacity { NumberAnimation { duration: 800 } }
                        transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.3) * 0.04; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 1.3) * 0.04; origin.x: width/2; origin.y: height/2 }
                    }
                    Rectangle {
                        id: orb2
                        width: parent.width * 0.85; height: width * (1.0 + Math.sin(screenRoot.globalOrbitAngle * 0.9 + 1.0) * 0.05); radius: width/2
                        x: parent.width/2 - width/2 + Math.sin(screenRoot.globalOrbitAngle * 1.5) * (-200*screenRoot.sc)
                        y: parent.height/2 - height/2 + Math.cos(screenRoot.globalOrbitAngle * 1.5) * (-140*screenRoot.sc)
                        opacity: screenRoot.inputActive ? 0.020 : 0.050; color: root.blue
                        Behavior on opacity { NumberAnimation { duration: 800 } }
                        transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.1 + 0.5) * 0.035; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 1.1 + 0.5) * 0.035; origin.x: width/2; origin.y: height/2 }
                    }
                    Rectangle {
                        id: orb3
                        width: parent.width * 0.50; height: width * (1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.5 + 2.0) * 0.07); radius: width/2
                        x: parent.width/2 - width/2 + Math.cos(screenRoot.globalOrbitAngle*3.2 + 1.5) * (280*screenRoot.sc)
                        y: parent.height/2 - height/2 + Math.sin(screenRoot.globalOrbitAngle*2.8 + 0.8) * (200*screenRoot.sc)
                        opacity: screenRoot.inputActive ? 0.012 : 0.030; color: root.peach
                        Behavior on opacity { NumberAnimation { duration: 800 } }
                        transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.7 + 1.0) * 0.05; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 1.7 + 1.0) * 0.05; origin.x: width/2; origin.y: height/2 }
                    }
                    Rectangle {
                        id: orb4
                        width: parent.width * 0.60; height: width * (1.0 + Math.sin(screenRoot.globalOrbitAngle * 0.7 + 3.0) * 0.06); radius: width/2
                        x: parent.width/2 - width/2 + Math.sin(screenRoot.globalOrbitAngle*1.1 + 2.8) * (350*screenRoot.sc)
                        y: parent.height/2 - height/2 + Math.cos(screenRoot.globalOrbitAngle*0.9 + 1.2) * (250*screenRoot.sc)
                        opacity: screenRoot.inputActive ? 0.008 : 0.022; color: root.green
                        Behavior on opacity { NumberAnimation { duration: 800 } }
                        transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 0.8 + 1.5) * 0.04; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 0.8 + 1.5) * 0.04; origin.x: width/2; origin.y: height/2 }
                    }
                    Rectangle {
                        id: orb5
                        width: parent.width * 0.40; height: width * (1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.2 + 4.0) * 0.08); radius: width/2
                        x: parent.width/2 - width/2 + Math.cos(screenRoot.globalOrbitAngle*4.0 + 3.7) * (420*screenRoot.sc)
                        y: parent.height/2 - height/2 + Math.sin(screenRoot.globalOrbitAngle*3.5 + 2.4) * (300*screenRoot.sc)
                        opacity: screenRoot.inputActive ? 0.010 : 0.025; color: root.mauve
                        Behavior on opacity { NumberAnimation { duration: 800 } }
                        transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.4 + 2.0) * 0.055; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 1.4 + 2.0) * 0.055; origin.x: width/2; origin.y: height/2 }
                    }
                }

                // Concentric decorative rings — LIQUID MORPHING ELLIPSES
                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState
                    scale: 1.1 - (0.1 * screenRoot.introState)

                    // Continuous liquid morph on the ring group
                    property real ringLiquidPhase: 0.0
                    NumberAnimation on ringLiquidPhase {
                        from: 0; to: 1000; duration: 6000000; loops: Animation.Infinite; running: true
                    }
                    property real ringLiquidScaleX: 1.0
                    property real ringLiquidScaleY: 1.0
                    Timer {
                        interval: 16; running: true; repeat: true
                        onTriggered: {
                            let t = parent.ringLiquidPhase
                            parent.ringLiquidScaleX = 1.0 + Math.sin(t * Math.PI * 0.8) * 0.008
                            parent.ringLiquidScaleY = 1.0 - Math.sin(t * Math.PI * 0.8) * 0.008
                        }
                    }
                    transform: [
                        Scale { xScale: parent.ringLiquidScaleX; yScale: parent.ringLiquidScaleY; origin.x: parent.width/2; origin.y: parent.height/2 }
                    ]

                    // Subtle breathing scale on the ring group
                    SequentialAnimation {
                        running: screenRoot.inputActive
                        loops: Animation.Infinite
                        NumberAnimation { target: parent; property: "scale"; to: 1.02 - (0.1 * screenRoot.introState); duration: 2000; easing.type: Easing.InOutSine }
                        NumberAnimation { target: parent; property: "scale"; to: 1.1 - (0.1 * screenRoot.introState); duration: 2000; easing.type: Easing.InOutSine }
                    }

                    Repeater {
                        model: 4
                        Rectangle {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -40 * screenRoot.sc
                            property real baseW: (400 * screenRoot.sc) + (index * (220 * screenRoot.sc))
                            width:  baseW + Math.sin(screenRoot.wiggleT * Math.PI * 1.4 + index * 1.2) * 4 * screenRoot.sc
                            height: baseW - Math.sin(screenRoot.wiggleT * Math.PI * 1.4 + index * 1.2) * 4 * screenRoot.sc
                            radius: width/2; color: "transparent"
                            border.color: lockUI.failed ? root.red : root.text
                            border.width: Math.max(1, 1 * screenRoot.sc) + Math.sin(screenRoot.wiggleT * Math.PI * 0.9 + index * 0.8) * 0.3 * screenRoot.sc
                            opacity: lockUI.failed
                                ? (0.10 - index * 0.02)
                                : (screenRoot.inputActive ? (0.02 - index * 0.005) : (0.04 - index * 0.01))
                            Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.OutExpo } }
                            Behavior on opacity      { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

                            // Gentle rotation on inner rings when typing
                            transform: Rotation {
                                angle: screenRoot.inputActive
                                    ? (screenRoot.globalOrbitAngle * 0.5 * (index % 2 === 0 ? 1 : -1) * 0.05)
                                    : 0
                                origin.x: parent.width / 2
                                origin.y: parent.height / 2
                            }
                        }
                    }
                }

                // Floating Lissajous particles
                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState * 0.65

                    Repeater {
                        model: ListModel {
                            ListElement { sX: 3.1; sY: 2.7; pX: 0.0;  pY: 0.5;  oW: 620; oH: 360; dW: 3; ci: 0 }
                            ListElement { sX: 2.0; sY: 3.4; pX: 1.2;  pY: 2.1;  oW: 760; oH: 440; dW: 2; ci: 1 }
                            ListElement { sX: 4.2; sY: 1.9; pX: 2.5;  pY: 0.9;  oW: 510; oH: 290; dW: 2; ci: 2 }
                            ListElement { sX: 1.5; sY: 4.1; pX: 3.8;  pY: 1.7;  oW: 840; oH: 490; dW: 3; ci: 0 }
                            ListElement { sX: 3.7; sY: 2.2; pX: 0.7;  pY: 3.3;  oW: 660; oH: 380; dW: 2; ci: 1 }
                            ListElement { sX: 2.8; sY: 3.9; pX: 4.2;  pY: 0.2;  oW: 700; oH: 410; dW: 2; ci: 3 }
                            ListElement { sX: 1.9; sY: 2.5; pX: 1.6;  pY: 4.5;  oW: 550; oH: 320; dW: 3; ci: 0 }
                            ListElement { sX: 4.5; sY: 1.6; pX: 3.1;  pY: 2.7;  oW: 800; oH: 460; dW: 2; ci: 2 }
                            ListElement { sX: 2.3; sY: 3.0; pX: 0.4;  pY: 1.1;  oW: 630; oH: 370; dW: 2; ci: 1 }
                            ListElement { sX: 3.6; sY: 4.4; pX: 2.9;  pY: 3.8;  oW: 490; oH: 270; dW: 3; ci: 3 }
                            ListElement { sX: 1.4; sY: 2.1; pX: 5.1;  pY: 0.6;  oW: 870; oH: 510; dW: 2; ci: 0 }
                            ListElement { sX: 4.0; sY: 3.3; pX: 1.9;  pY: 4.2;  oW: 590; oH: 340; dW: 2; ci: 2 }
                        }

                        Item {
                            x: parent.width/2  + Math.cos(screenRoot.globalOrbitAngle * model.sX + model.pX) * (model.oW/2 * screenRoot.sc) - model.dW * screenRoot.sc / 2
                            y: parent.height/2 + Math.sin(screenRoot.globalOrbitAngle * model.sY + model.pY) * (model.oH/2 * screenRoot.sc) - model.dW * screenRoot.sc / 2
                            property real pSq: 1.0
                            NumberAnimation on pSq {
                                from: 1.0; to: 1.4; duration: 800 + model.sX * 300; loops: Animation.Infinite; running: true
                                easing.type: Easing.InOutSine
                            }
                            Rectangle {
                                width: model.dW * screenRoot.sc; height: width; radius: width/2
                                color: model.ci === 0 ? root.mauve : (model.ci === 1 ? root.blue : (model.ci === 2 ? root.peach : root.green))
                                opacity: 0.42
                                transform: Scale { xScale: parent.pSq; yScale: 2.0 - parent.pSq; origin.x: width/2; origin.y: height/2 }
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 2. CORNER ACCENTS — subtle L-shaped brackets
                // ═════════════════════════════════════════════════════════════
                Item {
                    anchors.left: parent.left; anchors.top: parent.top
                    anchors.leftMargin: 28*screenRoot.sc; anchors.topMargin: 28*screenRoot.sc
                    width: 28*screenRoot.sc; height: 28*screenRoot.sc
                    opacity: screenRoot.introState * 0.45
                    Behavior on opacity { NumberAnimation { duration: 800 } }
                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: parent.width; height: Math.max(1, 1.5*screenRoot.sc); color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                    Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: Math.max(1, 1.5*screenRoot.sc); height: parent.height; color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                }
                Item {
                    anchors.right: parent.right; anchors.top: parent.top
                    anchors.rightMargin: 28*screenRoot.sc; anchors.topMargin: 28*screenRoot.sc
                    width: 28*screenRoot.sc; height: 28*screenRoot.sc
                    opacity: screenRoot.introState * 0.45
                    Behavior on opacity { NumberAnimation { duration: 800 } }
                    Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: parent.width; height: Math.max(1, 1.5*screenRoot.sc); color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                    Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: Math.max(1, 1.5*screenRoot.sc); height: parent.height; color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                }
                Item {
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                    anchors.leftMargin: 28*screenRoot.sc; anchors.bottomMargin: 28*screenRoot.sc
                    width: 28*screenRoot.sc; height: 28*screenRoot.sc
                    opacity: screenRoot.introState * 0.45
                    Behavior on opacity { NumberAnimation { duration: 800 } }
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: parent.width; height: Math.max(1, 1.5*screenRoot.sc); color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: Math.max(1, 1.5*screenRoot.sc); height: parent.height; color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                }
                Item {
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.rightMargin: 28*screenRoot.sc; anchors.bottomMargin: 28*screenRoot.sc
                    width: 28*screenRoot.sc; height: 28*screenRoot.sc
                    opacity: screenRoot.introState * 0.45
                    Behavior on opacity { NumberAnimation { duration: 800 } }
                    Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: parent.width; height: Math.max(1, 1.5*screenRoot.sc); color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                    Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: Math.max(1, 1.5*screenRoot.sc); height: parent.height; color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.55) }
                }

                // ═════════════════════════════════════════════════════════════
                // 3. TOP STATUS BAR — LIQUID FLOATING WAVE
                // ═════════════════════════════════════════════════════════════
                RowLayout {
                    id: topBar
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 28 * screenRoot.sc
                    spacing: 10 * screenRoot.sc
                    opacity: screenRoot.introState
                    transform: [
                        Translate { y: (-22 * screenRoot.sc) * (1.0 - screenRoot.introState) + Math.sin(screenRoot.globalOrbitAngle * 1.2) * 2 * screenRoot.sc },
                        Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 0.9) * 0.005; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 0.9) * 0.005; origin.x: topBar.width/2; origin.y: topBar.height/2 }
                    ]

                    // Hostname pill
                    Rectangle {
                        visible: screenRoot.hostname !== ""
                        Layout.preferredHeight: 36 * screenRoot.sc
                        Layout.preferredWidth:  hostRow.implicitWidth + 28 * screenRoot.sc
                        radius: height / 2
                        color:        Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.38)
                        border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: Math.max(1, 1 * screenRoot.sc)

                        RowLayout {
                            id: hostRow; anchors.centerIn: parent; spacing: 7 * screenRoot.sc
                            Text { text: "󰍹"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14*screenRoot.sc; color: root.mauve }
                            Text { text: screenRoot.hostname; font.family: "JetBrains Mono"; font.pixelSize: 12*screenRoot.sc; font.weight: Font.Bold; font.letterSpacing: 0.5; color: root.subtext0 }
                        }
                    }

                    // Network pill
                    Rectangle {
                        Layout.preferredHeight: 36 * screenRoot.sc
                        Layout.preferredWidth:  netTopRow.implicitWidth + 28 * screenRoot.sc
                        radius: height / 2
                        color:        Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.38)
                        border.color: screenRoot.networkOnline
                            ? Qt.rgba(root.green.r, root.green.g, root.green.b, 0.28)
                            : Qt.rgba(root.red.r,   root.red.g,   root.red.b,   0.28)
                        border.width: Math.max(1, 1 * screenRoot.sc)
                        Behavior on border.color { ColorAnimation { duration: 400 } }

                        RowLayout {
                            id: netTopRow; anchors.centerIn: parent; spacing: 7 * screenRoot.sc
                            Text {
                                text: screenRoot.networkOnline ? "󰤨" : "󰤭"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: 15*screenRoot.sc
                                color: screenRoot.networkOnline ? root.green : root.red
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text {
                                text: screenRoot.networkOnline ? "Online" : "Offline"
                                font.family: "JetBrains Mono"; font.pixelSize: 12*screenRoot.sc; font.weight: Font.Bold
                                color: screenRoot.networkOnline ? root.green : root.red
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }

                    // Uptime pill
                    Rectangle {
                        visible: screenRoot.uptimeStr !== ""
                        Layout.preferredHeight: 36 * screenRoot.sc
                        Layout.preferredWidth:  upRow.implicitWidth + 28 * screenRoot.sc
                        radius: height / 2
                        color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.38)
                        border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: Math.max(1, 1 * screenRoot.sc)

                        RowLayout {
                            id: upRow; anchors.centerIn: parent; spacing: 7 * screenRoot.sc
                            Text { text: "󱑂"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14*screenRoot.sc; color: root.blue }
                            Text { text: screenRoot.uptimeStr; font.family: "JetBrains Mono"; font.pixelSize: 12*screenRoot.sc; font.weight: Font.Bold; color: root.subtext0 }
                        }
                    }

                    // Caps Lock warning pill
                    Rectangle {
                        visible: screenRoot.capsLockOn
                        Layout.preferredHeight: 36 * screenRoot.sc
                        Layout.preferredWidth:  capsRow.implicitWidth + 28 * screenRoot.sc
                        radius: height / 2
                        color:        Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.12)
                        border.color: Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.50)
                        border.width: Math.max(1, 1 * screenRoot.sc)

                        RowLayout {
                            id: capsRow; anchors.centerIn: parent; spacing: 7 * screenRoot.sc
                            Text { text: "󰪛"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14*screenRoot.sc; color: root.peach }
                            Text { text: "CAPS LOCK"; font.family: "JetBrains Mono"; font.pixelSize: 11*screenRoot.sc; font.weight: Font.Black; font.letterSpacing: 1.5; color: root.peach }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 4. MAIN CONTENT — CLOCK + AUTH
                // ═════════════════════════════════════════════════════════════
                MouseArea {
                    anchors.fill: parent
                    enabled: !screenRoot.isPlayingIntro
                    hoverEnabled: true
                    onPositionChanged: (event) => {
                        screenRoot.mouseX = event.x
                        screenRoot.mouseY = event.y
                    }
                    onClicked: {
                        if (screenRoot.powerMenuOpen) screenRoot.powerMenuOpen = false
                        if (!screenRoot.inputActive)  screenRoot.inputActive = true
                        inputField.forceActiveFocus()
                    }
                }

                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState

                    // Clock glow — soft inverted-color blur behind clock
                    Rectangle {
                        id: clockGlow
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive
                            ? (-130 * screenRoot.sc) : (-30 * screenRoot.sc)
                        width: 500 * screenRoot.sc; height: 280 * screenRoot.sc
                        radius: 140 * screenRoot.sc
                        opacity: screenRoot.inputActive ? 0.0 : 0.15
                        color: screenRoot.luxuryColor(0.50, 0.20)
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 120 * screenRoot.sc
                            blur: 1.0
                            shadowEnabled: true
                            shadowColor: screenRoot.luxuryColor(0.50, 0.35)
                            shadowBlur: 1.0
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }
                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }

                        property real glowPhase: 0.0
                        NumberAnimation on glowPhase {
                            from: 0; to: 1000; duration: 8000000; loops: Animation.Infinite; running: true
                        }
                        property real glowSqX: 1.0
                        property real glowSqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let t = parent.glowPhase
                                parent.glowSqX = 1.0 + Math.sin(t * Math.PI * 1.0) * 0.03
                                parent.glowSqY = 1.0 - Math.sin(t * Math.PI * 1.0) * 0.03
                            }
                        }
                        transform: Scale { xScale: glowSqX; yScale: glowSqY; origin.x: clockGlow.width/2; origin.y: clockGlow.height/2 }
                    }

                    // ── CLOCK MODULE ─────────────────────────────────────────
                    ColumnLayout {
                        id: clockModule
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive
                            ? (-130 * screenRoot.sc) : (-30 * screenRoot.sc)
                        spacing: 0
                        opacity: screenRoot.inputActive ? 0.0 : 1.0
                        scale:   screenRoot.inputActive ? 0.88 : 1.0
                        visible: opacity > 0.01

                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 750; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                        Behavior on scale   { NumberAnimation { duration: 600; easing.type: Easing.OutBack  } }

                        // Day-of-week badge pill — LIQUID
                        Rectangle {
                            Layout.alignment:    Qt.AlignHCenter
                            Layout.bottomMargin: 18 * screenRoot.sc
                            implicitWidth:  dayLabel.implicitWidth + 36 * screenRoot.sc
                            implicitHeight: 28 * screenRoot.sc
                            radius: height / 2
                            color:        screenRoot.luxuryColor(0.00, 0.13)
                            border.color: screenRoot.luxuryColor(0.00, 0.45)
                            border.width: Math.max(1, 1 * screenRoot.sc)
                            property real badgeSq: 1.0
                            NumberAnimation on badgeSq {
                                from: 1.0; to: 1.04; duration: 2500; loops: Animation.Infinite; running: true
                                easing.type: Easing.InOutSine
                            }
                            transform: Scale { xScale: badgeSq; yScale: 2.0 - badgeSq; origin.x: width/2; origin.y: height/2 }

                            Text {
                                id: dayLabel
                                anchors.centerIn: parent
                                font.family:    "JetBrains Mono"
                                font.pixelSize: 11 * screenRoot.sc
                                font.weight:    Font.Bold
                                font.letterSpacing: 4.5
                                color: screenRoot.luxuryColor(0.00, 1.0)
                            }
                        }

                        // Individual digit clock — each digit wiggles independently
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            // H1
                            Text {
                                id: clockH1
                                font.family: "Playfair Display, Cormorant Garamond, Georgia, serif"
                                font.pixelSize: 155 * screenRoot.sc
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignVCenter
                                color: screenRoot.luxuryColor(0.00, 1.0)
                                transform: [
                                    Translate { x: screenRoot.wiggleH1X; y: screenRoot.wiggleH1Y },
                                    Rotation { angle: screenRoot.wiggleH1Angle; origin.x: width/2; origin.y: height/2 },
                                    Scale { xScale: screenRoot.wiggleH1Sq; yScale: 2.0 - screenRoot.wiggleH1Sq; origin.x: width/2; origin.y: height/2 }
                                ]
                            }

                            // H2
                            Text {
                                id: clockH2
                                font.family: "Playfair Display, Cormorant Garamond, Georgia, serif"
                                font.pixelSize: 155 * screenRoot.sc
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignVCenter
                                color: screenRoot.luxuryColor(0.04, 1.0)
                                transform: [
                                    Translate { x: screenRoot.wiggleH2X; y: screenRoot.wiggleH2Y },
                                    Rotation { angle: screenRoot.wiggleH2Angle; origin.x: width/2; origin.y: height/2 },
                                    Scale { xScale: screenRoot.wiggleH2Sq; yScale: 2.0 - screenRoot.wiggleH2Sq; origin.x: width/2; origin.y: height/2 }
                                ]
                            }

                            // Blinking colon
                            Text {
                                text: ":"
                                font.family: "Playfair Display, Cormorant Garamond, Georgia, serif"
                                font.pixelSize: 155 * screenRoot.sc
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignVCenter
                                Layout.bottomMargin: 6 * screenRoot.sc
                                color: screenRoot.luxuryColor(0.08, 1.0)
                                SequentialAnimation on opacity {
                                    running: true; loops: Animation.Infinite
                                    NumberAnimation { to: 0.12; duration: 520; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 520; easing.type: Easing.InOutSine }
                                }
                            }

                            // M1
                            Text {
                                id: clockM1
                                font.family: "Playfair Display, Cormorant Garamond, Georgia, serif"
                                font.pixelSize: 155 * screenRoot.sc
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignVCenter
                                color: screenRoot.luxuryColor(0.12, 1.0)
                                transform: [
                                    Translate { x: screenRoot.wiggleM1X; y: screenRoot.wiggleM1Y },
                                    Rotation { angle: screenRoot.wiggleM1Angle; origin.x: width/2; origin.y: height/2 },
                                    Scale { xScale: screenRoot.wiggleM1Sq; yScale: 2.0 - screenRoot.wiggleM1Sq; origin.x: width/2; origin.y: height/2 }
                                ]
                            }

                            // M2
                            Text {
                                id: clockM2
                                font.family: "Playfair Display, Cormorant Garamond, Georgia, serif"
                                font.pixelSize: 155 * screenRoot.sc
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignVCenter
                                color: screenRoot.luxuryColor(0.16, 1.0)
                                transform: [
                                    Translate { x: screenRoot.wiggleM2X; y: screenRoot.wiggleM2Y },
                                    Rotation { angle: screenRoot.wiggleM2Angle; origin.x: width/2; origin.y: height/2 },
                                    Scale { xScale: screenRoot.wiggleM2Sq; yScale: 2.0 - screenRoot.wiggleM2Sq; origin.x: width/2; origin.y: height/2 }
                                ]
                            }

                            // Seconds pill — LIQUID
                            Rectangle {
                                Layout.alignment:    Qt.AlignBottom
                                Layout.bottomMargin: 30 * screenRoot.sc
                                Layout.leftMargin:   14 * screenRoot.sc
                                implicitWidth:  secsText.implicitWidth + 22 * screenRoot.sc
                                implicitHeight: 34 * screenRoot.sc
                                radius: height / 2
                                color:        Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.55)
                                border.color: screenRoot.luxuryColor(0.20, 0.40)
                                border.width: Math.max(1, 1 * screenRoot.sc)
                                property real secsSq: 1.0
                                NumberAnimation on secsSq {
                                    from: 1.0; to: 1.03; duration: 2000; loops: Animation.Infinite; running: true
                                    easing.type: Easing.InOutSine
                                }
                                transform: Scale { xScale: secsSq; yScale: 2.0 - secsSq; origin.x: width/2; origin.y: height/2 }

                                Text {
                                    id: secsText
                                    anchors.centerIn: parent
                                    font.family:    "JetBrains Mono"
                                    font.pixelSize: 15 * screenRoot.sc
                                    font.weight:    Font.Bold
                                    color: screenRoot.luxuryColor(0.20, 0.90)
                                }
                            }
                        }

                        // Decorative divider — LIQUID WAVE ─────●─────
                        Item {
                            Layout.alignment:  Qt.AlignHCenter
                            Layout.topMargin:  6 * screenRoot.sc
                            implicitWidth:  220 * screenRoot.sc
                            implicitHeight: 20 * screenRoot.sc
                            property real divPhase: 0.0
                            NumberAnimation on divPhase {
                                from: 0; to: 360; duration: 4000; loops: Animation.Infinite; running: true
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                                width: 88 * screenRoot.sc; height: Math.max(1, 1 * screenRoot.sc)
                                color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.18)
                                opacity: 0.5 + Math.sin(parent.divPhase * Math.PI / 180) * 0.3
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 6 * screenRoot.sc + Math.sin(parent.divPhase * Math.PI / 180 * 1.5) * 2 * screenRoot.sc
                                height: width; radius: width/2
                                color: screenRoot.luxuryColor(0.28, 0.82)
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
                                width: 88 * screenRoot.sc; height: Math.max(1, 1 * screenRoot.sc)
                                color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.18)
                                opacity: 0.5 + Math.cos(parent.divPhase * Math.PI / 180) * 0.3
                            }
                        }

                        // Date
                        Text {
                            id: dateText
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10 * screenRoot.sc
                            font.family:    "JetBrains Mono"
                            font.pixelSize: 13 * screenRoot.sc
                            font.weight:    Font.Medium
                            font.letterSpacing: 3.5
                            color: screenRoot.luxuryColor(0.35, 0.70)
                        }

                        // Personalised greeting
                        Text {
                            id: greetingText
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 16 * screenRoot.sc
                            font.family:    "JetBrains Mono"
                            font.pixelSize: 16 * screenRoot.sc
                            font.letterSpacing: 1.5
                            color: Qt.rgba(root.subtext0.r, root.subtext0.g, root.subtext0.b, 0.60)
                        }

                        Timer {
                            interval: 1000; running: true; repeat: true; triggeredOnStart: true
                            onTriggered: {
                                let d = new Date()
                                let hh = Qt.formatDateTime(d, "hh")
                                let mm = Qt.formatDateTime(d, "mm")
                                clockH1.text = hh[0]
                                clockH2.text = hh[1]
                                clockM1.text = mm[0]
                                clockM2.text = mm[1]
                                secsText.text     = Qt.formatDateTime(d, "ss")
                                dateText.text     = Qt.formatDateTime(d, "dddd, MMMM dd yyyy").toUpperCase()
                                dayLabel.text     = Qt.formatDateTime(d, "dddd").toUpperCase()
                                let h = d.getHours()
                                greetingText.text = (h < 5  ? "Good Night"      :
                                                    h < 12 ? "Good Morning"    :
                                                    h < 17 ? "Good Afternoon"  :
                                                    "Good Evening")
                                    + ",  " + screenRoot.currentUser
                            }
                        }
                    }

                    // ── AUTH MODULE — LIQUID FLOATING ──────────────────────────
                    RowLayout {
                        id: authModule
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive
                            ? (-30 * screenRoot.sc) : (60 * screenRoot.sc) + Math.sin(screenRoot.wiggleT * Math.PI * 0.5 + 1.5) * 2 * screenRoot.sc - screenRoot.exitState * 100 * screenRoot.sc
                        spacing: 40 * screenRoot.sc
                        opacity: screenRoot.inputActive ? (1.0 - screenRoot.exitState) : 0.0
                        scale:   screenRoot.inputActive ? (1.0 - screenRoot.exitState * 0.5) : 0.90
                        visible: opacity > 0.01

                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 750; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                        Behavior on scale   { NumberAnimation { duration: 600; easing.type: Easing.OutBack  } }

                        // ── AVATAR with SEQUENTIAL POP-IN HALO EFFECTS ─────
                        Item {
                            id: avatarContainer
                            Layout.alignment: Qt.AlignVCenter
                            width: 186 * screenRoot.sc
                            height: width

                            property real failFlash: 0.0

                            // ── Avatar shake on wrong password ──
                            property real failShakeX: 0.0
                            property real failShakeY: 0.0
                            property real failShakeAngle: 0.0
                            transform: [
                                Translate { x: avatarContainer.failShakeX; y: avatarContainer.failShakeY },
                                Rotation { angle: avatarContainer.failShakeAngle; origin.x: avatarContainer.width/2; origin.y: avatarContainer.height/2 }
                            ]

                            // Red flash animation — triggered on wrong password
                            SequentialAnimation {
                                id: avatarFlashAnim
                                NumberAnimation { target: avatarContainer; property: "failFlash"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                                NumberAnimation { target: avatarContainer; property: "failFlash"; to: 0.0; duration: 850; easing.type: Easing.OutCubic }
                            }

                            // Shake animation — modern multi-axis with OutBack bounce
                            SequentialAnimation {
                                id: avatarShakeAnim
                                running: false
                                NumberAnimation { target: avatarContainer; property: "failShakeX"; from: 0; to: -14; duration: 60; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeX"; from: -14; to: 12; duration: 70; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeX"; from: 12; to: -8; duration: 60; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeX"; from: -8; to: 4; duration: 50; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeX"; from: 4; to: 0; duration: 80; easing.type: Easing.OutBack }
                                ParallelAnimation {
                                    NumberAnimation { target: avatarContainer; property: "failShakeY"; from: 0; to: -5; duration: 80; easing.type: Easing.OutQuad }
                                }
                                NumberAnimation { target: avatarContainer; property: "failShakeY"; from: -5; to: 2; duration: 70; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeY"; from: 2; to: -1; duration: 60; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeY"; from: -1; to: 0; duration: 60; easing.type: Easing.OutBack }
                                ParallelAnimation {
                                    NumberAnimation { target: avatarContainer; property: "failShakeAngle"; from: 0; to: -2.5; duration: 80; easing.type: Easing.OutQuad }
                                }
                                NumberAnimation { target: avatarContainer; property: "failShakeAngle"; from: -2.5; to: 1.5; duration: 90; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeAngle"; from: 1.5; to: -0.8; duration: 70; easing.type: Easing.OutQuad }
                                NumberAnimation { target: avatarContainer; property: "failShakeAngle"; from: -0.8; to: 0; duration: 80; easing.type: Easing.OutBack }
                            }
                            Connections {
                                target: lockUI
                                function onFailedChanged() {
                                    if (lockUI.failed) {
                                        avatarFlashAnim.restart()
                                        avatarShakeAnim.restart()
                                    }
                                }
                            }

                            // Halo burst A — Mauve/Red on fail
                            Rectangle {
                                anchors.centerIn: parent
                                width: 0; height: 0; radius: width/2
                                color: "transparent"
                                border.color: avatarContainer.failFlash > 0.01 ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.65 * avatarContainer.failFlash) : screenRoot.luxuryColor(0.00, 0.65)
                                border.width: 3 * screenRoot.sc

                                SequentialAnimation {
                                    loops: Animation.Infinite; running: true
                                    PauseAnimation { duration: 400 }
                                    ParallelAnimation {
                                        NumberAnimation { target: parent; property: "width"; from: parent.width; to: parent.parent.width + 70 * screenRoot.sc; duration: 1800; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "height"; from: parent.height; to: parent.parent.width + 70 * screenRoot.sc; duration: 1800; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "opacity"; from: 0.75; to: 0.0; duration: 1800; easing.type: Easing.OutCubic }
                                    }
                                }
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                            }

                            // Halo burst B — Blue/Red on fail
                            Rectangle {
                                anchors.centerIn: parent
                                width: 0; height: 0; radius: width/2
                                color: "transparent"
                                border.color: avatarContainer.failFlash > 0.01 ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.55 * avatarContainer.failFlash) : screenRoot.luxuryColor(0.25, 0.55)
                                border.width: 2.5 * screenRoot.sc

                                SequentialAnimation {
                                    loops: Animation.Infinite; running: true
                                    PauseAnimation { duration: 1200 }
                                    ParallelAnimation {
                                        NumberAnimation { target: parent; property: "width"; from: parent.width; to: parent.parent.width + 50 * screenRoot.sc; duration: 1500; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "height"; from: parent.height; to: parent.parent.width + 50 * screenRoot.sc; duration: 1500; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "opacity"; from: 0.60; to: 0.0; duration: 1500; easing.type: Easing.OutCubic }
                                    }
                                }
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                            }

                            // Halo burst C — Peach/Red on fail
                            Rectangle {
                                anchors.centerIn: parent
                                width: 0; height: 0; radius: width/2
                                color: "transparent"
                                border.color: avatarContainer.failFlash > 0.01 ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.50 * avatarContainer.failFlash) : screenRoot.luxuryColor(0.40, 0.50)
                                border.width: 2 * screenRoot.sc

                                SequentialAnimation {
                                    loops: Animation.Infinite; running: true
                                    PauseAnimation { duration: 2000 }
                                    ParallelAnimation {
                                        NumberAnimation { target: parent; property: "width"; from: parent.width; to: parent.parent.width + 90 * screenRoot.sc; duration: 2200; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "height"; from: parent.height; to: parent.parent.width + 90 * screenRoot.sc; duration: 2200; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "opacity"; from: 0.50; to: 0.0; duration: 2200; easing.type: Easing.OutCubic }
                                    }
                                }
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                            }

                            // Halo burst D — Violet/Red on fail
                            Rectangle {
                                anchors.centerIn: parent
                                width: 0; height: 0; radius: width/2
                                color: "transparent"
                                border.color: avatarContainer.failFlash > 0.01 ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.45 * avatarContainer.failFlash) : screenRoot.luxuryColor(0.55, 0.45)
                                border.width: 1.5 * screenRoot.sc

                                SequentialAnimation {
                                    loops: Animation.Infinite; running: true
                                    PauseAnimation { duration: 2800 }
                                    ParallelAnimation {
                                        NumberAnimation { target: parent; property: "width"; from: parent.width; to: parent.parent.width + 110 * screenRoot.sc; duration: 2500; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "height"; from: parent.height; to: parent.parent.width + 110 * screenRoot.sc; duration: 2500; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: parent; property: "opacity"; from: 0.40; to: 0.0; duration: 2500; easing.type: Easing.OutCubic }
                                    }
                                }
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                            }

                            // Core subtle glow — always visible, breathing, red on fail
                            Rectangle {
                                id: avatarCoreGlow
                                anchors.centerIn: parent
                                width: parent.width + 10 * screenRoot.sc; height: width; radius: width/2
                                color: "transparent"
                                border.color: avatarContainer.failFlash > 0.01 ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.50 + 0.50 * avatarContainer.failFlash) : screenRoot.luxuryColor(0.10, 0.30)
                                border.width: 1.5 * screenRoot.sc

                                NumberAnimation on scale {
                                    from: 1.0; to: 1.03; duration: 2500; loops: Animation.Infinite; running: true
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation on opacity {
                                    from: 0.25; to: 0.55; duration: 2500; loops: Animation.Infinite; running: true
                                    easing.type: Easing.InOutSine
                                }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }
                            MultiEffect {
                                anchors.fill: avatarCoreGlow; source: avatarCoreGlow
                                blurEnabled: true; blurMax: 10; blur: 0.6
                                opacity: avatarContainer.failFlash > 0.01 ? (0.40 + 0.50 * avatarContainer.failFlash) : (lockUI.failed ? 0.90 : 0.40)
                            }

                            Rectangle {
                                anchors.fill: parent; anchors.margins: 6 * screenRoot.sc
                                radius: width/2
                                color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.50)
                                visible: avatarImg.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: screenRoot.currentUser.length > 0 ? screenRoot.currentUser[0].toUpperCase() : "?"
                                    font.family:    "JetBrains Mono"
                                    font.pixelSize: 58 * screenRoot.sc
                                    font.weight:    Font.Bold
                                    color: root.mauve
                                }
                            }
                            Rectangle {
                                id: avatarMask
                                anchors.fill: parent; anchors.margins: 6 * screenRoot.sc
                                radius: width/2; color: "black"; visible: false; layer.enabled: true
                            }
                            Image {
                                id: avatarImg
                                anchors.fill: parent; anchors.margins: 6 * screenRoot.sc
                                source: screenRoot.faceIconPath !== "" ? screenRoot.faceIconPath : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: false; cache: false; asynchronous: true
                            }
                            MultiEffect {
                                source: avatarImg; anchors.fill: avatarImg
                                maskEnabled: true; maskSource: avatarMask
                                visible: avatarImg.status === Image.Ready
                            }

                            // Red flash overlay on avatar picture — 1s fade on wrong password
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 6 * screenRoot.sc
                                radius: width/2
                                color: Qt.rgba(root.red.r, root.red.g, root.red.b, avatarContainer.failFlash * 0.55)
                                visible: avatarImg.status === Image.Ready && avatarContainer.failFlash > 0.01
                            }

                            // Spinning ring (active during typing)
                            Canvas {
                                id: spinRing
                                anchors.fill: parent
                                property real spinAngle: 0
                                opacity: lockUI.failed ? 0.0 : (screenRoot.inputActive || lockUI.authenticating ? 1.0 : 0.0)
                                Behavior on opacity { NumberAnimation { duration: 400 } }

                                onSpinAngleChanged: requestPaint()

                                Connections {
                                    target: lockUI
                                    function onAuthenticatingChanged() { spinRing.requestPaint() }
                                    function onFailedChanged()         { spinRing.requestPaint() }
                                }

                                NumberAnimation on spinAngle {
                                    from: 0; to: 360; duration: 2200
                                    loops: Animation.Infinite
                                    running: screenRoot.inputActive || lockUI.authenticating
                                    easing.type: Easing.Linear
                                }

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var cx = width/2, cy = height/2, r = width/2 - 3

                                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2*Math.PI)
                                    ctx.strokeStyle = (lockUI.authenticating
                                        ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.15)
                                        : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.12)
                                    ).toString()
                                    ctx.lineWidth = 2; ctx.stroke()

                                    ctx.save()
                                    ctx.translate(cx, cy)
                                    ctx.rotate((spinAngle - 90) * Math.PI / 180)
                                    ctx.translate(-cx, -cy)

                                    var arcLen = lockUI.authenticating ? 4.2 : 2.27
                                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, arcLen)
                                    ctx.strokeStyle = (lockUI.authenticating
                                        ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 1.0)
                                        : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 1.0)
                                    ).toString()
                                    ctx.lineWidth = 2.5; ctx.lineCap = "round"; ctx.stroke()

                                    ctx.beginPath(); ctx.arc(cx, cy, r, arcLen, arcLen + 0.9)
                                    ctx.strokeStyle = (lockUI.authenticating
                                        ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.18)
                                        : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.18)
                                    ).toString()
                                    ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.stroke()
                                    ctx.restore()
                                }
                            }

                            // Static ring (idle)
                            Canvas {
                                anchors.fill: parent
                                opacity: screenRoot.inputActive ? 0.0 : 0.40
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 3, 0, 2*Math.PI)
                                    ctx.strokeStyle = Qt.rgba(root.text.r, root.text.g, root.text.b, 0.26).toString()
                                    ctx.lineWidth = 1.5; ctx.stroke()
                                }
                            }

                            // Error ring
                            Canvas {
                                id: errorRingCanvas; anchors.fill: parent
                                opacity: lockUI.failed ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                Connections {
                                    target: lockUI
                                    function onFailedChanged() { errorRingCanvas.requestPaint() }
                                }
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 3, 0, 2*Math.PI)
                                    ctx.strokeStyle = Qt.rgba(root.red.r, root.red.g, root.red.b, 1.0).toString()
                                    ctx.lineWidth = 2.5; ctx.stroke()
                                }
                            }
                        }

                        // ── USER INFO & PASSWORD ─────────────────────────
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8 * screenRoot.sc

                            Text {
                                text: "FUCKED IN AS"
                                font.family:    "JetBrains Mono"
                                font.pixelSize: 10 * screenRoot.sc
                                font.letterSpacing: 3.5
                                color: Qt.rgba(root.subtext0.r, root.subtext0.g, root.subtext0.b, 0.55)
                                Layout.alignment: Qt.AlignLeft
                            }

                            RowLayout {
                                spacing: 10 * screenRoot.sc
                                Layout.alignment:    Qt.AlignLeft
                                Layout.bottomMargin: 10 * screenRoot.sc

                                Rectangle {
                                    width: 32 * screenRoot.sc; height: width; radius: 9 * screenRoot.sc
                                    color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.15)
                                    Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 17*screenRoot.sc; color: root.mauve }
                                }
                                Text {
                                    text: screenRoot.currentUser
                                    font.family:    "JetBrains Mono"
                                    font.pixelSize: 30 * screenRoot.sc
                                    font.weight:    Font.Bold
                                    font.letterSpacing: 1.5
                                    color: root.mauve
                                }
                            }

                            RowLayout {
                                Layout.alignment:    Qt.AlignLeft
                                Layout.bottomMargin: 6 * screenRoot.sc
                                spacing: 12 * screenRoot.sc

                                Rectangle {
                                    width: 36 * screenRoot.sc; height: width; radius: width/2
                                    color: lockUI.failed         ? Qt.rgba(root.red.r,   root.red.g,   root.red.b,   0.2)
                                         : lockUI.authenticating ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.2)
                                         :                         Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.15)
                                    border.color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.mauve)
                                    border.width: Math.max(1, 1 * screenRoot.sc)
                                    Behavior on color        { ColorAnimation { duration: 300 } }
                                    Behavior on border.color { ColorAnimation { duration: 300 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: lockUI.failed ? "󰌾" : (lockUI.authenticating ? "󰌿" : "󰌾")
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc
                                        color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.mauve)
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }

                                Text {
                                    font.family:    "JetBrains Mono"
                                    font.pixelSize: 14 * screenRoot.sc
                                    font.weight:    Font.Medium
                                    font.letterSpacing: 2.0
                                    text:  lockUI.statusText.toUpperCase()
                                    color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.text)
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }

                            // ── PASSWORD PILL ──────────────────────────────

                            // Typing activity indicator — subtle wave dots above pill
                            Row {
                                id: typingWave
                                spacing: 5 * screenRoot.sc
                                Layout.alignment: Qt.AlignLeft
                                Layout.bottomMargin: 6 * screenRoot.sc
                                opacity: inputField.text.length > 0 && !lockUI.authenticating ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                Repeater {
                                    model: 5
                                    Rectangle {
                                        width: 4 * screenRoot.sc; height: width; radius: width / 2
                                        color: screenRoot.luxuryColor(index * 0.08, 0.7)

                                        SequentialAnimation {
                                            running: inputField.text.length > 0 && !lockUI.authenticating
                                            loops: Animation.Infinite
                                            NumberAnimation { target: parent; property: "opacity"; to: 0.3; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                            NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                        }
                                        SequentialAnimation {
                                            running: inputField.text.length > 0 && !lockUI.authenticating
                                            loops: Animation.Infinite
                                            NumberAnimation { target: parent; property: "scale"; to: 0.6; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                            NumberAnimation { target: parent; property: "scale"; to: 1.2; duration: 400 + index * 100; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: pinPill
                                Layout.alignment: Qt.AlignLeft
                                width: 300 * screenRoot.sc; height: 60 * screenRoot.sc
                                radius: height / 2; clip: true

                                // Liquid continuous squish
                                property real pillSquishX: 1.0
                                property real pillSquishY: 1.0
                                property real pillLiquidPhase: 0.0
                                NumberAnimation on pillLiquidPhase {
                                    from: 0; to: 1000; duration: 4000000; loops: Animation.Infinite; running: true
                                }
                                Timer {
                                    interval: 16; running: true; repeat: true
                                    onTriggered: {
                                        let t = pinPill.pillLiquidPhase
                                        let intensity = screenRoot.inputActive ? 0.025 : 0.012
                                        pinPill.pillSquishX = 1.0 + Math.sin(t * Math.PI * 1.5) * intensity
                                        pinPill.pillSquishY = 1.0 - Math.sin(t * Math.PI * 1.5) * intensity
                                    }
                                }

                                color: lockUI.failed
                                    ? Qt.rgba(root.red.r,     root.red.g,     root.red.b,     0.08)
                                    : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.48)
                                border.width: Math.max(1, 2 * screenRoot.sc) + Math.sin(pinPill.pillLiquidPhase * Math.PI * 2.0) * 0.5 * screenRoot.sc
                                border.color: {
                                    if (lockUI.failed)         return root.red
                                    if (lockUI.authenticating) return root.peach
                                    if (inputField.text.length > 0) return root.mauve
                                    return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                                }

                                Behavior on color        { ColorAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                Behavior on border.color { ColorAnimation { duration: 350; easing.type: Easing.OutExpo } }

                                property real pillStateScale: lockUI.failed ? 1.03 : (lockUI.authenticating ? 0.98 : 1.0)
                                Behavior on pillStateScale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                                transform: [
                                    Translate { id: shakeTranslate; x: 0 },
                                    Scale { xScale: pinPill.pillSquishX * pinPill.pillStateScale; yScale: pinPill.pillSquishY * pinPill.pillStateScale; origin.x: pinPill.width/2; origin.y: pinPill.height/2 }
                                ]

                                // Liquid wave fill — animated gradient inside
                                Canvas {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    opacity: inputField.text.length > 0 ? 0.10 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }

                                    property real wavePhase: 0.0
                                    NumberAnimation on wavePhase {
                                        from: 0; to: 360; duration: 3000; loops: Animation.Infinite; running: inputField.text.length > 0
                                    }
                                    onWavePhaseChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var waveY = height * 0.7
                                        ctx.beginPath()
                                        ctx.moveTo(0, height)
                                        for (var x = 0; x <= width; x += 2) {
                                            var y = waveY + Math.sin((x + wavePhase * 2) * 0.05) * 3 * screenRoot.sc
                                                         + Math.sin((x + wavePhase * 1.3) * 0.08) * 2 * screenRoot.sc
                                            ctx.lineTo(x, y)
                                        }
                                        ctx.lineTo(width, height)
                                        ctx.closePath()
                                        var wc = screenRoot.luxuryColor(0.00, 0.5)
                                        ctx.fillStyle = "rgba(" + Math.floor(wc.r*255) + "," + Math.floor(wc.g*255) + "," + Math.floor(wc.b*255) + ",0.6)"
                                        ctx.fill()
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent; radius: parent.radius
                                    color: "transparent"; border.color: root.mauve; border.width: 7
                                    opacity: (!lockUI.failed && !lockUI.authenticating && inputField.text.length > 0) ? 0.13 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 300 } }
                                }

                                SequentialAnimation {
                                    id: shakeAnim
                                    NumberAnimation { target: shakeTranslate; property: "x"; from: 0;                    to: -10 * screenRoot.sc; duration: 80;  easing.type: Easing.OutQuad   }
                                    NumberAnimation { target: shakeTranslate; property: "x"; from: -10 * screenRoot.sc; to:  10 * screenRoot.sc; duration: 100; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTranslate; property: "x"; from:  10 * screenRoot.sc; to:  -7 * screenRoot.sc; duration: 90; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTranslate; property: "x"; from:  -7 * screenRoot.sc; to:   7 * screenRoot.sc; duration: 90; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTranslate; property: "x"; from:   7 * screenRoot.sc; to:  -4 * screenRoot.sc; duration: 80; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: shakeTranslate; property: "x"; from:  -4 * screenRoot.sc; to:   0;                 duration: 120; easing.type: Easing.OutBack   }
                                }
                                Connections {
                                    target: lockUI
                                    function onFailedChanged() { if (lockUI.failed) shakeAnim.restart() }
                                }

                                TextInput {
                                    id: inputField
                                    anchors.fill: parent
                                    opacity: 0
                                    echoMode: TextInput.Password
                                    enabled: !screenRoot.isPlayingIntro

                                    property string oldText: ""

                                    Component.onCompleted: forceActiveFocus()
                                    onActiveFocusChanged: {
                                        if (!activeFocus && !screenRoot.powerMenuOpen && !screenRoot.isPlayingIntro)
                                            forceActiveFocus()
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            screenRoot.inputActive = false
                                            text = ""; passModel.clear(); event.accepted = true
                                        } else if (!screenRoot.inputActive) {
                                            screenRoot.inputActive = true
                                        }
                                    }

                                    onAccepted: {
                                        if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                            lockUI.authenticating = true
                                            lockUI.statusText = "Fuckthenticating..."
                                            lockUI.failed = false
                                            pam.respond(text)
                                            text = ""; oldText = ""; passModel.clear()
                                        }
                                    }

                                    onTextChanged: {
                                        if (lockUI.authenticating) return
                                        if (text.length > 0 && !screenRoot.inputActive)
                                            screenRoot.inputActive = true
                                        idleTimer.restart()

                                        if (text !== oldText) {
                                            if (text.length > oldText.length) {
                                                for (let i = oldText.length; i < text.length; i++)
                                                    passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword })
                                            } else if (text.length < oldText.length) {
                                                let diff = oldText.length - text.length
                                                for (let i = 0; i < diff; i++) passModel.remove(passModel.count - 1)
                                            } else {
                                                passModel.clear()
                                                for (let i = 0; i < text.length; i++)
                                                    passModel.append({ "charStr": text.charAt(i), "isDot": lockSettings.hidePassword })
                                            }
                                            oldText = text
                                        }

                                        if (text.length > 0) {
                                            lockUI.failed = false
                                            lockUI.statusText = "Fuckenter PIN"
                                        } else {
                                            if (!lockUI.failed) lockUI.statusText = "Fuckailed"
                                        }
                                    }
                                }

                                ListModel { id: passModel }

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin:  20 * screenRoot.sc
                                    anchors.rightMargin: 20 * screenRoot.sc
                                    clip: true
                                    Text {
                                        anchors.centerIn: parent
                                        visible: lockUI.authenticating
                                        text: "Fuckecking..."
                                        font.family:    "JetBrains Mono"
                                        font.pixelSize: 13 * screenRoot.sc
                                        font.letterSpacing: 2
                                        color: Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.70)
                                    }

                                    Row {
                                        id: dotRow
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: width > parent.width
                                            ? parent.width - width
                                            : (parent.width - width) / 2
                                        spacing: 4 * screenRoot.sc
                                        visible: !lockUI.authenticating
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                        Repeater {
                                            model: passModel
                                            delegate: Text {
                                                text: model.isDot ? "•" : model.charStr
                                                font.family:    "JetBrains Mono"
                                                font.pixelSize: model.isDot ? (32*screenRoot.sc) : (24*screenRoot.sc)
                                                font.weight:    Font.Bold
                                                color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.text)
                                                verticalAlignment: Text.AlignVCenter
                                                height: pinPill.height
                                                NumberAnimation on opacity { from: 0; to: 1; duration: 150 }
                                                Timer {
                                                    interval: lockSettings.revealDuration
                                                    running: !model.isDot && !lockSettings.hidePassword
                                                    onTriggered: {
                                                        if (index >= 0 && index < passModel.count)
                                                            passModel.setProperty(index, "isDot", true)
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: Math.max(2, 2 * screenRoot.sc); height: 22 * screenRoot.sc
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: root.mauve
                                            SequentialAnimation on opacity {
                                                running: !lockUI.authenticating
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.0; duration: 540; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: 1.0; duration: 540; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 5. HINT TEXT BAR — LIQUID FLOATING
                // ═════════════════════════════════════════════════════════════
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: (48 + 40 + 22) * screenRoot.sc + Math.sin(screenRoot.globalOrbitAngle * 1.0) * 3 * screenRoot.sc
                    text: screenRoot.inputActive
                        ? "ESC TO CANCEL"
                        : "PRESS ANY KEY"
                    font.family:    "JetBrains Mono"
                    font.pixelSize: 10 * screenRoot.sc
                    font.letterSpacing: 2.5
                    color: Qt.rgba(root.subtext0.r, root.subtext0.g, root.subtext0.b, 0.30)
                    opacity: screenRoot.introState
                    transform: Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 1.3) * 0.01; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 1.3) * 0.01; origin.x: width/2; origin.y: height/2 }
                }

                // ═════════════════════════════════════════════════════════════
                // 6. BOTTOM SYSTEM PILLS — LIQUID FLOATING WAVE
                // ═════════════════════════════════════════════════════════════
                RowLayout {
                    id: bottomBar
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40 * screenRoot.sc
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14 * screenRoot.sc
                    opacity: screenRoot.introState
                    transform: [
                        Translate { y: (20 * screenRoot.sc) * (1.0 - screenRoot.introState) + Math.sin(screenRoot.globalOrbitAngle * 0.9 + 1.0) * 2 * screenRoot.sc },
                        Scale { xScale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 0.7) * 0.004; yScale: 1.0 - Math.sin(screenRoot.globalOrbitAngle * 0.7) * 0.004; origin.x: bottomBar.width/2; origin.y: bottomBar.height/2 }
                    ]

                    // Keyboard layout — LIQUID JELLY
                    Rectangle {
                        property bool isHovered: kbMouse.containsMouse
                        property real jellyPhase: 0.0
                        NumberAnimation on jellyPhase {
                            from: 0; to: 1000; duration: 3000000; loops: Animation.Infinite; running: true
                        }
                        property real jellySqX: 1.0
                        property real jellySqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let intensity = kbMouse.containsMouse ? 0.04 : 0.01
                                let t = parent.jellyPhase
                                parent.jellySqX = 1.0 + Math.sin(t * Math.PI * 1.8) * intensity
                                parent.jellySqY = 1.0 - Math.sin(t * Math.PI * 1.8) * intensity
                            }
                        }
                        Layout.preferredHeight: 46 * screenRoot.sc
                        Layout.preferredWidth:  kbRow.implicitWidth + 34 * screenRoot.sc
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.60) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.38)
                        border.color: isHovered ? root.mauve : Qt.rgba(root.text.r,root.text.g,root.text.b,0.08)
                        border.width: Math.max(1, 1*screenRoot.sc)
                        property real kbHoverScale: kbMouse.containsMouse ? 1.05 : 1.0
                        Behavior on kbHoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        transform: Scale { xScale: jellySqX * kbHoverScale; yScale: jellySqY * kbHoverScale; origin.x: width/2; origin.y: height/2 }
                        RowLayout { id: kbRow; anchors.centerIn: parent; spacing: 8*screenRoot.sc
                            Text { text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: parent.parent.isHovered ? root.mauve : root.overlay2; Behavior on color { ColorAnimation { duration: 200 } } }
                            Text { text: screenRoot.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Black; color: root.text }
                        }
                        MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                    }

                    // Battery (laptop only) — LIQUID JELLY
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse
                        property real jellyPhase: 0.0
                        NumberAnimation on jellyPhase {
                            from: 0; to: 1000; duration: 3000000; loops: Animation.Infinite; running: true
                        }
                        property real jellySqX: 1.0
                        property real jellySqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let intensity = batMouse.containsMouse ? 0.04 : 0.01
                                let t = parent.jellyPhase
                                parent.jellySqX = 1.0 + Math.sin(t * Math.PI * 1.8 + 0.5) * intensity
                                parent.jellySqY = 1.0 - Math.sin(t * Math.PI * 1.8 + 0.5) * intensity
                            }
                        }
                        visible: !screenRoot.isDesktop
                        Layout.preferredHeight: 46 * screenRoot.sc
                        Layout.preferredWidth:  batRow.implicitWidth + 34 * screenRoot.sc
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.60) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.38)
                        border.color: isHovered ? batRow.dynColor : Qt.rgba(root.text.r,root.text.g,root.text.b,0.08)
                        border.width: Math.max(1, 1*screenRoot.sc)
                        property real batHoverScale: batMouse.containsMouse ? 1.05 : 1.0
                        Behavior on batHoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        transform: Scale { xScale: jellySqX * batHoverScale; yScale: jellySqY * batHoverScale; origin.x: width/2; origin.y: height/2 }
                        RowLayout { id: batRow; anchors.centerIn: parent; spacing: 8*screenRoot.sc
                            property color dynColor: {
                                if (screenRoot.batStatus === "Charging") return root.green
                                let pct = parseInt(screenRoot.batPct)
                                return pct >= 60 ? root.green : (pct >= 25 ? root.peach : root.red)
                            }
                            Text {
                                text: screenRoot.batStatus === "Charging" ? "󰂄" : (parseInt(screenRoot.batPct) < 20 ? "󰂃" : "󰁹")
                                font.family: "Iosevka Nerd Font"; font.pixelSize: 20*screenRoot.sc
                                color: parent.dynColor; Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Text {
                                text: screenRoot.batPct + "%"
                                font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Black
                                color: parent.dynColor; Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                        MouseArea { id: batMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                    }

                    // Weather — LIQUID JELLY
                    Rectangle {
                        property bool isHovered: weatherMouse.containsMouse
                        property real jellyPhase: 0.0
                        NumberAnimation on jellyPhase {
                            from: 0; to: 1000; duration: 3000000; loops: Animation.Infinite; running: true
                        }
                        property real jellySqX: 1.0
                        property real jellySqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let intensity = weatherMouse.containsMouse ? 0.04 : 0.01
                                let t = parent.jellyPhase
                                parent.jellySqX = 1.0 + Math.sin(t * Math.PI * 1.8 + 1.0) * intensity
                                parent.jellySqY = 1.0 - Math.sin(t * Math.PI * 1.8 + 1.0) * intensity
                            }
                        }
                        Layout.preferredHeight: 46 * screenRoot.sc
                        Layout.preferredWidth:  weatherRow.implicitWidth + 34 * screenRoot.sc
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.60) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.38)
                        border.color: isHovered ? root.blue : Qt.rgba(root.text.r,root.text.g,root.text.b,0.08)
                        border.width: Math.max(1, 1*screenRoot.sc)
                        property real weatherHoverScale: weatherMouse.containsMouse ? 1.05 : 1.0
                        Behavior on weatherHoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        transform: Scale { xScale: jellySqX * weatherHoverScale; yScale: jellySqY * weatherHoverScale; origin.x: width/2; origin.y: height/2 }
                        RowLayout { id: weatherRow; anchors.centerIn: parent; spacing: 8*screenRoot.sc
                            Text { text: screenRoot.weatherIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 20*screenRoot.sc; color: parent.parent.isHovered ? root.blue : root.text; Behavior on color { ColorAnimation { duration: 200 } } }
                            Text { text: screenRoot.weatherTemp; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Black; color: root.text }
                        }
                        MouseArea { id: weatherMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                    }

                    // Network — LIQUID JELLY
                    Rectangle {
                        property bool isHovered: netBottomMouse.containsMouse
                        property real jellyPhase: 0.0
                        NumberAnimation on jellyPhase {
                            from: 0; to: 1000; duration: 3000000; loops: Animation.Infinite; running: true
                        }
                        property real jellySqX: 1.0
                        property real jellySqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let intensity = netBottomMouse.containsMouse ? 0.04 : 0.01
                                let t = parent.jellyPhase
                                parent.jellySqX = 1.0 + Math.sin(t * Math.PI * 1.8 + 1.5) * intensity
                                parent.jellySqY = 1.0 - Math.sin(t * Math.PI * 1.8 + 1.5) * intensity
                            }
                        }
                        Layout.preferredHeight: 46 * screenRoot.sc
                        Layout.preferredWidth:  netBottomRow.implicitWidth + 34 * screenRoot.sc
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.60) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.38)
                        border.color: isHovered ? (screenRoot.networkOnline ? root.green : root.red) : Qt.rgba(root.text.r,root.text.g,root.text.b,0.08)
                        border.width: Math.max(1, 1*screenRoot.sc)
                        property real netHoverScale: netBottomMouse.containsMouse ? 1.05 : 1.0
                        Behavior on netHoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        transform: Scale { xScale: jellySqX * netHoverScale; yScale: jellySqY * netHoverScale; origin.x: width/2; origin.y: height/2 }
                        RowLayout { id: netBottomRow; anchors.centerIn: parent; spacing: 8*screenRoot.sc
                            Text { text: screenRoot.networkOnline ? "󰤨" : "󰤭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: screenRoot.networkOnline ? root.green : root.red; Behavior on color { ColorAnimation { duration: 300 } } }
                            Text { text: screenRoot.networkOnline ? "Onfuck" : "Offuckline"; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Black; color: screenRoot.networkOnline ? root.green : root.red; Behavior on color { ColorAnimation { duration: 300 } } }
                        }
                        MouseArea { id: netBottomMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                    }

                    // Uptime — LIQUID JELLY
                    Rectangle {
                        property bool isHovered: uptimeMouse.containsMouse
                        property real jellyPhase: 0.0
                        NumberAnimation on jellyPhase {
                            from: 0; to: 1000; duration: 3000000; loops: Animation.Infinite; running: true
                        }
                        property real jellySqX: 1.0
                        property real jellySqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let intensity = uptimeMouse.containsMouse ? 0.04 : 0.01
                                let t = parent.jellyPhase
                                parent.jellySqX = 1.0 + Math.sin(t * Math.PI * 1.8 + 2.0) * intensity
                                parent.jellySqY = 1.0 - Math.sin(t * Math.PI * 1.8 + 2.0) * intensity
                            }
                        }
                        visible: screenRoot.uptimeStr !== ""
                        Layout.preferredHeight: 46 * screenRoot.sc
                        Layout.preferredWidth:  uptimeRow.implicitWidth + 34 * screenRoot.sc
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.60) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.38)
                        border.color: isHovered ? root.blue : Qt.rgba(root.text.r,root.text.g,root.text.b,0.08)
                        border.width: Math.max(1, 1*screenRoot.sc)
                        property real uptimeHoverScale: uptimeMouse.containsMouse ? 1.05 : 1.0
                        Behavior on uptimeHoverScale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        transform: Scale { xScale: jellySqX * uptimeHoverScale; yScale: jellySqY * uptimeHoverScale; origin.x: width/2; origin.y: height/2 }
                        RowLayout { id: uptimeRow; anchors.centerIn: parent; spacing: 8*screenRoot.sc
                            Text { text: "󱑂"; font.family: "Iosevka Nerd Font"; font.pixelSize: 16*screenRoot.sc; color: parent.parent.isHovered ? root.blue : root.overlay2; Behavior on color { ColorAnimation { duration: 200 } } }
                            Text { text: screenRoot.uptimeStr; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Black; color: root.text }
                        }
                        MouseArea { id: uptimeMouse; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 7. MEDIA CONTROLS — bottom-left
                // ═════════════════════════════════════════════════════════════
                Item {
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    anchors.margins: 40 * screenRoot.sc
                    height: 52 * screenRoot.sc
                    width: childrenRect.width
                    opacity: screenRoot.introState

                    RowLayout {
                        spacing: 12 * screenRoot.sc

                        // Previous
                        Rectangle {
                            width: 44 * screenRoot.sc; height: width; radius: height/2
                            color: prevMouse.containsMouse ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.8) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.4)
                            border.color: Qt.rgba(root.text.r,root.text.g,root.text.b,0.15); border.width: Math.max(1, 1*screenRoot.sc)
                            scale: prevMouse.pressed ? 0.88 : (prevMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: prevMouse.containsMouse ? root.text : root.subtext0 }
                            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: prevProcess.running = true }
                        }

                        // Play/Pause
                        Rectangle {
                            width: 44 * screenRoot.sc; height: width; radius: height/2
                            color: playMouse.containsMouse ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.8) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.4)
                            border.color: Qt.rgba(root.text.r,root.text.g,root.text.b,0.15); border.width: Math.max(1, 1*screenRoot.sc)
                            scale: playMouse.pressed ? 0.88 : (playMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Text { anchors.centerIn: parent; text: "󰐎"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: playMouse.containsMouse ? root.text : root.subtext0 }
                            MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: playPauseProcess.running = true }
                        }

                        // Next
                        Rectangle {
                            width: 44 * screenRoot.sc; height: width; radius: height/2
                            color: nextMouse.containsMouse ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.8) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.4)
                            border.color: Qt.rgba(root.text.r,root.text.g,root.text.b,0.15); border.width: Math.max(1, 1*screenRoot.sc)
                            scale: nextMouse.pressed ? 0.88 : (nextMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: nextMouse.containsMouse ? root.text : root.subtext0 }
                            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: nextProcess.running = true }
                        }

                        // Volume slider
                        Item {
                            width: 100 * screenRoot.sc; height: 44 * screenRoot.sc
                            clip: true
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 4 * screenRoot.sc; radius: height/2
                                color: Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6)
                                Rectangle {
                                    height: parent.height; radius: height/2
                                    width: parent.width * root.pwVolume
                                    color: root.isMuted ? root.red : root.mauve
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                            Rectangle {
                                id: volThumb
                                x: (parent.width - width) * root.pwVolume
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14 * screenRoot.sc; height: width; radius: height/2
                                color: volMouse.pressed ? root.peach : (volMouse.containsMouse ? root.text : root.surface2)
                                border.color: root.surface0; border.width: Math.max(1, 2*screenRoot.sc)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                transform: Scale { origin.x: width/2; origin.y: height/2; xScale: volMouse.pressed ? 1.3 : (volMouse.containsMouse ? 1.15 : 1.0) }
                            }
                            MouseArea {
                                id: volMouse; anchors.fill: parent; hoverEnabled: true
                                onPositionChanged: (e) => { if (pressed) { let p = Math.max(0, Math.min(1, e.x / width)); root.pwVolume = p; let vol = Math.round(p * 100); volumeSet.command = ["bash", "-c", "SINK_ID=$(pactl list sink-inputs 2>/dev/null | grep -B20 'pw-play' | grep 'Sink Input #' | head -1 | grep -o '[0-9][0-9]*') && pactl set-sink-input-volume \"$SINK_ID\" \"" + vol + "%\""]; volumeSet.running = true } }
                                onPressed: (e) => { let p = Math.max(0, Math.min(1, e.x / width)); root.pwVolume = p; let vol = Math.round(p * 100); volumeSet.command = ["bash", "-c", "SINK_ID=$(pactl list sink-inputs 2>/dev/null | grep -B20 'pw-play' | grep 'Sink Input #' | head -1 | grep -o '[0-9][0-9]*') && pactl set-sink-input-volume \"$SINK_ID\" \"" + vol + "%\""]; volumeSet.running = true }
                            }
                        }

                        // Separator
                        Rectangle {
                            width: Math.max(1, 1*screenRoot.sc); height: 24*screenRoot.sc; color: Qt.rgba(root.text.r,root.text.g,root.text.b,0.15)
                        }

                        // Mute/Unmute
                        Rectangle {
                            width: 44 * screenRoot.sc; height: width; radius: height/2
                            color: muteMouse.containsMouse ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.8) : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.4)
                            border.color: Qt.rgba(root.text.r,root.text.g,root.text.b,0.15); border.width: Math.max(1, 1*screenRoot.sc)
                            scale: muteMouse.pressed ? 0.88 : (muteMouse.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            Text {
                                anchors.centerIn: parent
                                text: root.isMuted ? "󰝟" : "󰕾"
                                font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc
                                color: root.isMuted ? root.red : (muteMouse.containsMouse ? root.text : root.subtext0)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: muteProcess.running = true }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 8. POWER MENU + POWER BUTTON
                // ═════════════════════════════════════════════════════════════
                Rectangle {
                    id: powerMenu
                    anchors.bottom:       powerBtn.top
                    anchors.right:        parent.right
                    anchors.bottomMargin: 15 * screenRoot.sc
                    anchors.rightMargin:  40 * screenRoot.sc
                    width:  280 * screenRoot.sc
                    height: screenRoot.powerMenuOpen ? (menuLayout.implicitHeight + 20 * screenRoot.sc) : 0
                    radius: 18 * screenRoot.sc; clip: true
                    opacity: screenRoot.powerMenuOpen ? 1 : 0
                    color:        Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.96)
                    border.color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.25)
                    border.width: Math.max(1, 1 * screenRoot.sc)
                    Behavior on height  { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                    Behavior on opacity { NumberAnimation { duration: 250 } }

                    ColumnLayout {
                        id: menuLayout
                        anchors.top: parent.top; anchors.topMargin: 10 * screenRoot.sc
                        anchors.left: parent.left; anchors.right: parent.right
                        spacing: 6 * screenRoot.sc

                        Text { text: "SETTINGS"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 12*screenRoot.sc; font.letterSpacing: 1.5; color: root.mauve; Layout.leftMargin: 18*screenRoot.sc; Layout.topMargin: 4*screenRoot.sc; Layout.bottomMargin: 4*screenRoot.sc }

                        RowLayout {
                            Layout.fillWidth: true; Layout.leftMargin: 18*screenRoot.sc; Layout.rightMargin: 18*screenRoot.sc; Layout.topMargin: 4*screenRoot.sc
                            Text { text: "Hide password"; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Medium; color: root.text; Layout.fillWidth: true }
                            Rectangle {
                                width: 40*screenRoot.sc; height: 22*screenRoot.sc; radius: height/2
                                color: lockSettings.hidePassword ? root.mauve : root.surface2
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Rectangle {
                                    width: height; height: 18*screenRoot.sc; radius: height/2
                                    x: lockSettings.hidePassword ? parent.width - width - 2*screenRoot.sc : 2*screenRoot.sc
                                    y: (parent.height - height) / 2; color: root.base
                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        lockSettings.hidePassword = !lockSettings.hidePassword
                                        if (lockSettings.hidePassword)
                                            for (let i = 0; i < passModel.count; i++) passModel.setProperty(i, "isDot", true)
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.leftMargin: 18*screenRoot.sc; Layout.rightMargin: 18*screenRoot.sc; Layout.topMargin: 8*screenRoot.sc; Layout.bottomMargin: 8*screenRoot.sc; spacing: 8*screenRoot.sc
                            opacity: lockSettings.hidePassword ? 0.3 : 1.0; Behavior on opacity { NumberAnimation { duration: 200 } }
                            RowLayout { Layout.fillWidth: true
                                Text { text: "Reveal delay"; font.family: "JetBrains Mono"; font.pixelSize: 14*screenRoot.sc; font.weight: Font.Medium; color: root.blue; Layout.fillWidth: true }
                                Text { text: lockSettings.revealDuration >= 1000 ? (lockSettings.revealDuration/1000).toFixed(1)+"s" : lockSettings.revealDuration+"ms"; font.family: "JetBrains Mono"; font.pixelSize: 13*screenRoot.sc; font.weight: Font.Bold; color: root.peach }
                            }
                            Item {
                                Layout.fillWidth: true; Layout.preferredHeight: 28*screenRoot.sc
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8*screenRoot.sc; radius: height/2; color: root.surface2
                                    Rectangle { width: ((lockSettings.revealDuration-100)/2900)*parent.width; height: parent.height; radius: height/2; color: root.mauve }
                                }
                                Rectangle {
                                    id: sliderThumb; width: 20*screenRoot.sc; height: width; radius: height/2; color: root.peach
                                    border.color: root.crust; border.width: Math.max(1, 2*screenRoot.sc)
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(((lockSettings.revealDuration-100)/2900)*parent.width - width/2, parent.width - width))
                                    scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                }
                                MultiEffect { source: sliderThumb; anchors.fill: sliderThumb; shadowEnabled: true; shadowBlur: 0.5; shadowColor: "#000000"; shadowOpacity: 0.4; shadowVerticalOffset: 2*screenRoot.sc }
                                MouseArea {
                                    id: sliderMouse; anchors.fill: parent; hoverEnabled: true; enabled: !lockSettings.hidePassword; preventStealing: true
                                    function updateVal(mx) { let p=Math.max(0,Math.min(1,mx/width)); let ms=Math.round(100+p*2900); if(ms%100<10) ms-=(ms%100); else if(ms%100>90) ms+=(100-(ms%100)); lockSettings.revealDuration=ms }
                                    onPositionChanged: (e) => { if (pressed) updateVal(e.x) }
                                    onPressed: (e) => updateVal(e.x)
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Math.max(1,1*screenRoot.sc); color: Qt.rgba(root.mauve.r,root.mauve.g,root.mauve.b,0.2); Layout.leftMargin: 18*screenRoot.sc; Layout.rightMargin: 18*screenRoot.sc; Layout.topMargin: 4*screenRoot.sc; Layout.bottomMargin: 4*screenRoot.sc }

                        Text { text: "SYSTEM"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 12*screenRoot.sc; font.letterSpacing: 1.5; color: root.mauve; Layout.leftMargin: 18*screenRoot.sc; Layout.bottomMargin: 4*screenRoot.sc }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 48*screenRoot.sc; Layout.leftMargin: 10*screenRoot.sc; Layout.rightMargin: 10*screenRoot.sc; radius: 12*screenRoot.sc
                            color: ma1.containsMouse ? Qt.rgba(root.blue.r,root.blue.g,root.blue.b,0.10) : "transparent"
                            scale: ma1.pressed ? 0.95 : (ma1.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 16*screenRoot.sc; anchors.rightMargin: 16*screenRoot.sc; spacing: 0
                                Text { text: "󰜉"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r,root.blue.g,root.blue.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                Item { Layout.fillWidth: true }
                                Text { text: "Reboot"; font.family: "JetBrains Mono"; font.pixelSize: 15*screenRoot.sc; font.weight: Font.Medium; color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r,root.blue.g,root.blue.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                            }
                            MouseArea { id: ma1; anchors.fill: parent; hoverEnabled: true; onClicked: { screenRoot.powerMenuOpen=false; reloadProcess.running=true } }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 48*screenRoot.sc; Layout.leftMargin: 10*screenRoot.sc; Layout.rightMargin: 10*screenRoot.sc; radius: 12*screenRoot.sc
                            color: ma2.containsMouse ? Qt.rgba(root.mauve.r,root.mauve.g,root.mauve.b,0.10) : "transparent"
                            scale: ma2.pressed ? 0.95 : (ma2.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 16*screenRoot.sc; anchors.rightMargin: 16*screenRoot.sc; spacing: 0
                                Text { text: "󰒲"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r,root.mauve.g,root.mauve.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                Item { Layout.fillWidth: true }
                                Text { text: "Suspend"; font.family: "JetBrains Mono"; font.pixelSize: 15*screenRoot.sc; font.weight: Font.Medium; color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r,root.mauve.g,root.mauve.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                            }
                            MouseArea { id: ma2; anchors.fill: parent; hoverEnabled: true; onClicked: { screenRoot.powerMenuOpen=false; suspendProcess.running=true } }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 48*screenRoot.sc; Layout.leftMargin: 10*screenRoot.sc; Layout.rightMargin: 10*screenRoot.sc; Layout.bottomMargin: 8*screenRoot.sc; radius: 12*screenRoot.sc
                            color: ma3.containsMouse ? Qt.rgba(root.red.r,root.red.g,root.red.b,0.10) : "transparent"
                            scale: ma3.pressed ? 0.95 : (ma3.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            RowLayout { anchors.fill: parent; anchors.leftMargin: 16*screenRoot.sc; anchors.rightMargin: 16*screenRoot.sc; spacing: 0
                                Text { text: "󰐥"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18*screenRoot.sc; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r,root.red.g,root.red.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                                Item { Layout.fillWidth: true }
                                Text { text: "Power Off"; font.family: "JetBrains Mono"; font.pixelSize: 15*screenRoot.sc; font.weight: Font.Medium; color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r,root.red.g,root.red.b,0.6); Behavior on color { ColorAnimation { duration: 200 } } }
                            }
                            MouseArea { id: ma3; anchors.fill: parent; hoverEnabled: true; onClicked: { screenRoot.powerMenuOpen=false; poweroffProcess.running=true } }
                        }
                    }
                }

                // Power button — LIQUID JELLY
                Rectangle {
                    id: powerBtn
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    anchors.margins: 40 * screenRoot.sc
                    width: 52 * screenRoot.sc; height: width; radius: height/2
                    color: screenRoot.powerMenuOpen ? root.surface2
                        : (powerBtnMa.containsMouse ? Qt.rgba(root.surface1.r,root.surface1.g,root.surface1.b,0.8)
                                                    : Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.4))
                    border.color: screenRoot.powerMenuOpen ? root.text : Qt.rgba(root.text.r,root.text.g,root.text.b,0.15)
                    border.width: Math.max(1, 1*screenRoot.sc)
                    opacity: screenRoot.introState
                    scale: powerBtnMa.pressed ? 0.88 : (powerBtnMa.containsMouse ? 1.1 : 1.0)
                    Behavior on color        { ColorAnimation  { duration: 250; easing.type: Easing.OutExpo } }
                    Behavior on border.color { ColorAnimation  { duration: 250; easing.type: Easing.OutExpo } }

                    Text {
                        anchors.centerIn: parent; text: "󰐥"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: 22*screenRoot.sc
                        color: screenRoot.powerMenuOpen ? root.red : (powerBtnMa.containsMouse ? root.text : root.subtext0)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    MouseArea {
                        id: powerBtnMa; anchors.fill: parent; hoverEnabled: true; enabled: !screenRoot.isPlayingIntro
                        onClicked: {
                            screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen
                            if (!screenRoot.powerMenuOpen) inputField.forceActiveFocus()
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // 9. INTRO ANIMATION OVERLAY — FLUID LIQUID REVEAL
                // ═════════════════════════════════════════════════════════════
                Item {
                    id: introOverlay
                    anchors.fill: parent; z: 999
                    visible: screenRoot.isPlayingIntro || opacity > 0

                    // Liquid blob background (transparent to show wallpaper)
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        property real blobPhase: 0.0
                        NumberAnimation on blobPhase {
                            from: 0; to: 1000; duration: 2000000; loops: Animation.Infinite; running: true
                        }
                        property real blobSx: 1.0
                        property real blobSy: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let t = parent.blobPhase
                                parent.blobSx = 1.0 + Math.sin(t * Math.PI * 1.1) * 0.03
                                parent.blobSy = 1.0 - Math.sin(t * Math.PI * 1.1) * 0.03
                            }
                        }
                        transform: Scale { xScale: blobSx; yScale: blobSy; origin.x: parent.width/2; origin.y: parent.height/2 }
                    }

                    // Sweeping radial light burst
                    Canvas {
                        id: introSweepCanvas
                        anchors.fill: parent
                        property real sweepAngle: 0
                        opacity: 0.6

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width / 2, cy = height / 2
                            var grad = ctx.createConicalGradient(cx, cy, sweepAngle * Math.PI / 180)
                            grad.addColorStop(0, "rgba(137,101,137,0)")
                            grad.addColorStop(0.15, "rgba(137,101,137,0.12)")
                            grad.addColorStop(0.3, "rgba(137,101,137,0)")
                            grad.addColorStop(1, "rgba(137,101,137,0)")
                            ctx.fillStyle = grad
                            ctx.fillRect(0, 0, width, height)
                        }
                        NumberAnimation on sweepAngle {
                            from: 0; to: 360; duration: 1200; easing.type: Easing.OutCubic
                        }
                    }

                    // Particle burst dots — liquid expanding
                    Repeater {
                        model: 12
                        Item {
                            id: particleDot
                            x: parent.width / 2; y: parent.height / 2
                            property real pSq: 1.0
                            Rectangle {
                                width: 4 * screenRoot.sc; height: width; radius: width / 2
                                color: index % 3 === 0 ? root.mauve : (index % 3 === 1 ? root.blue : root.peach)
                                transform: Scale { xScale: parent.pSq; yScale: 2.0 - parent.pSq; origin.x: width/2; origin.y: height/2 }
                            }
                            NumberAnimation on x {
                                from: parent.width / 2
                                to: parent.width / 2 + Math.cos(index * Math.PI * 2 / 12) * (300 + index * 30) * screenRoot.sc
                                duration: 800; easing.type: Easing.OutExpo
                            }
                            NumberAnimation on y {
                                from: parent.height / 2
                                to: parent.height / 2 + Math.sin(index * Math.PI * 2 / 12) * (300 + index * 30) * screenRoot.sc
                                duration: 800; easing.type: Easing.OutExpo
                            }
                            NumberAnimation on opacity {
                                from: 0.9; to: 0; duration: 800; easing.type: Easing.OutExpo
                            }
                            SequentialAnimation on pSq {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { target: parent; property: "pSq"; from: 1.0; to: 1.3; duration: 200; easing.type: Easing.InOutSine }
                                NumberAnimation { target: parent; property: "pSq"; from: 1.3; to: 1.0; duration: 200; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    // Expanding rings — staggered, cinematic, liquid morph
                    Rectangle { id: ring4; width: 420*screenRoot.sc; height: width; radius: height/2; anchors.centerIn: parent; color: "transparent"; border.color: root.blue; border.width: Math.max(1,0.8*screenRoot.sc); scale: 0.3; opacity: 0.0 }
                    Rectangle { id: ring3; width: 360*screenRoot.sc; height: width; radius: height/2; anchors.centerIn: parent; color: "transparent"; border.color: root.mauve; border.width: Math.max(1,1*screenRoot.sc); scale: 0.5; opacity: 0.0 }
                    Rectangle { id: ring2; width: 300*screenRoot.sc; height: width; radius: height/2; anchors.centerIn: parent; color: "transparent"; border.color: root.text;  border.width: Math.max(1,1*screenRoot.sc); scale: 0.8; opacity: 0.0 }
                    Rectangle { id: ring1; width: 240*screenRoot.sc; height: width; radius: height/2; anchors.centerIn: parent; color: "transparent"; border.color: root.text;  border.width: Math.max(1,2*screenRoot.sc); scale: 0.8; opacity: 0.0 }

                    Item {
                        id: introLockOrb; width: 170*screenRoot.sc; height: width; anchors.centerIn: parent; scale: 0.0; opacity: 0.0
                        // Liquid squish on the orb itself
                        property real orbLiquidPhase: 0.0
                        NumberAnimation on orbLiquidPhase {
                            from: 0; to: 1000; duration: 1500000; loops: Animation.Infinite; running: true
                        }
                        property real orbSqX: 1.0
                        property real orbSqY: 1.0
                        Timer {
                            interval: 16; running: true; repeat: true
                            onTriggered: {
                                let t = parent.orbLiquidPhase
                                parent.orbSqX = 1.0 + Math.sin(t * Math.PI * 1.5) * 0.02
                                parent.orbSqY = 1.0 - Math.sin(t * Math.PI * 1.5) * 0.02
                            }
                        }
                        transform: Scale { xScale: orbSqX; yScale: orbSqY; origin.x: width/2; origin.y: height/2 }
                        Rectangle { anchors.fill: parent; radius: height/2; color: Qt.rgba(root.surface0.r,root.surface0.g,root.surface0.b,0.9); border.color: root.text; border.width: Math.max(1,2*screenRoot.sc) }
                        Text { id: introIconUnlocked; anchors.centerIn: parent; text: "󰌿"; font.family: "Iosevka Nerd Font"; font.pixelSize: 64*screenRoot.sc; color: root.text; opacity: 1.0; scale: 1.0; transformOrigin: Item.Center }
                        Text { id: introIconLocked; anchors.centerIn: parent; text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 64*screenRoot.sc; color: root.text; opacity: 0.0; scale: 1.6; transformOrigin: Item.Center }
                    }

                    SequentialAnimation {
                        id: introSequence

                        // Phase 1: Particle burst + outer ring expand
                        ParallelAnimation {
                            // Orb pops in
                            NumberAnimation { target: introLockOrb; property: "scale";   from: 0.0; to: 1.0; duration: 500; easing.type: Easing.OutBack  }
                            NumberAnimation { target: introLockOrb; property: "opacity"; from: 0.0; to: 1.0; duration: 350; easing.type: Easing.OutExpo  }
                            // Rings expand outward with stagger
                            NumberAnimation { target: ring1; property: "scale";   from: 0.8; to: 1.5; duration: 450; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring1; property: "opacity"; from: 0.8; to: 0.0; duration: 450; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring2; property: "scale";   from: 0.8; to: 1.7; duration: 550; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring2; property: "opacity"; from: 0.6; to: 0.0; duration: 550; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring3; property: "scale";   from: 0.5; to: 1.9; duration: 650; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring3; property: "opacity"; from: 0.4; to: 0.0; duration: 650; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring4; property: "scale";   from: 0.3; to: 2.1; duration: 750; easing.type: Easing.OutExpo }
                            NumberAnimation { target: ring4; property: "opacity"; from: 0.3; to: 0.0; duration: 750; easing.type: Easing.OutExpo }
                        }

                        // Phase 2: Lock icon transition — unlock to lock
                        PauseAnimation { duration: 200 }
                        ParallelAnimation {
                            NumberAnimation { target: introIconUnlocked; property: "scale";   from: 1.0; to: 0.4; duration: 130; easing.type: Easing.InCubic }
                            NumberAnimation { target: introIconUnlocked; property: "opacity"; from: 1.0; to: 0.0; duration: 100  }
                            NumberAnimation { target: introIconLocked; property: "scale";   from: 1.8; to: 1.0; duration: 350; easing.type: Easing.OutBack  }
                            NumberAnimation { target: introIconLocked; property: "opacity"; from: 0.0; to: 1.0; duration: 180 }
                            // Subtle bounce on orb
                            SequentialAnimation {
                                NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 0;                to: 5*screenRoot.sc; duration: 60;  easing.type: Easing.OutQuad }
                                NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: 5*screenRoot.sc;  to: -2*screenRoot.sc; duration: 120; easing.type: Easing.OutQuad }
                                NumberAnimation { target: introLockOrb; property: "anchors.verticalCenterOffset"; from: -2*screenRoot.sc; to: 0;                duration: 150; easing.type: Easing.OutBack }
                            }
                        }

                        // Phase 3: Orb expands, overlay fades, UI reveals
                        PauseAnimation { duration: 100 }
                        ParallelAnimation {
                            NumberAnimation { target: introLockOrb; property: "scale";   to: 2.2; duration: 180; easing.type: Easing.InExpo }
                            NumberAnimation { target: introOverlay; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.InExpo }
                        }

                        // Smooth UI fade-in
                        NumberAnimation { target: screenRoot; property: "introState"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutExpo }

                        PropertyAction { target: screenRoot; property: "isPlayingIntro"; value: false }
                        ScriptAction { script: { inputField.text = ""; inputField.forceActiveFocus() } }
                    }
                }

            } // screenRoot
        } // WlSessionLockSurface
    } // WlSessionLock
} // ShellRoot
