import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    // --- Helper Functions ---
    function showHint(detail, mouseArea) {}
    function hideHint() {}

    function formatBytes(bytes) {
        if (bytes === 0 || isNaN(bytes)) return '0 B';
        var k = 1024;
        var sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS & NAVIGATION
    // -------------------------------------------------------------------------
    Keys.onEscapePressed: {
        closeSequence.start();
        event.accepted = true;
    }
    Keys.onTabPressed: {
        let next = (root.currentTab + 1) % root.tabNames.length;
        if (next === 0) next = 1;
        root.setTab(next);
        event.accepted = true;
    }
    Keys.onBacktabPressed: {
        let prev = (root.currentTab - 1 + root.tabNames.length) % root.tabNames.length;
        if (prev === 0) prev = root.tabNames.length - 1;
        root.setTab(prev);
        event.accepted = true;
    }
    Keys.onLeftPressed: {
        if (root.currentTab === 2) {
            if (root.selectedModuleIndex > 0) {
                root.selectedModuleIndex--;
                modulesList.positionViewAtIndex(root.selectedModuleIndex, ListView.Contain);
            }
        } else if (root.currentTab === 4) {
            let next = (root.selectedContinent - 1 + root.continentData.length) % root.continentData.length;
            if (next !== root.selectedContinent) {
                chipContainer.opacity = 0.0;
                continentFadeTimer.targetIndex = next;
                continentFadeTimer.restart();
            }
        } else {
            let prev = (root.currentTab - 1 + root.tabNames.length) % root.tabNames.length;
            if (prev === 0) prev = root.tabNames.length - 1;
            root.setTab(prev);
        }
        event.accepted = true;
    }
    Keys.onRightPressed: {
        if (root.currentTab === 2) {
            if (root.selectedModuleIndex < modulesDataModel.count - 1) {
                root.selectedModuleIndex++;
                modulesList.positionViewAtIndex(root.selectedModuleIndex, ListView.Contain);
            }
        } else if (root.currentTab === 4) {
            let next = (root.selectedContinent + 1) % root.continentData.length;
            if (next !== root.selectedContinent) {
                chipContainer.opacity = 0.0;
                continentFadeTimer.targetIndex = next;
                continentFadeTimer.restart();
            }
        } else {
            let next = (root.currentTab + 1) % root.tabNames.length;
            if (next === 0) next = 1;
            root.setTab(next);
        }
        event.accepted = true;
    }
    Keys.onUpPressed: {
        let prev = (root.currentTab - 1 + root.tabNames.length) % root.tabNames.length;
        if (prev === 0) prev = root.tabNames.length - 1;
        root.setTab(prev);
        event.accepted = true;
    }
    Keys.onDownPressed: {
        let next = (root.currentTab + 1) % root.tabNames.length;
        if (next === 0) next = 1;
        root.setTab(next);
        event.accepted = true;
    }
    Keys.onReturnPressed: {
        if (currentTab === 2) { 
            let target = modulesDataModel.get(selectedModuleIndex).target;
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", target]);
            event.accepted = true;
        }
    }
    Keys.onEnterPressed: { Keys.onReturnPressed(event); }

    MatugenColors { id: _theme }
    // -------------------------------------------------------------------------
    // COLORS
    // -------------------------------------------------------------------------
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color overlay0: _theme.overlay0
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color green: _theme.green
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color red: _theme.red

    property var continentData: [
        { region: "America", icon: "", color: root.blue, zones: [
            { disp: "Argentina", zone: "America/Argentina/Buenos_Aires" },
            { disp: "Bahamas", zone: "America/Nassau" },
            { disp: "Bermuda", zone: "Atlantic/Bermuda" },
            { disp: "Bolivia", zone: "America/La_Paz" },
            { disp: "Brazil", zone: "America/Sao_Paulo" },
            { disp: "Canada Atlantic", zone: "America/Halifax" },
            { disp: "Canada Central", zone: "America/Winnipeg" },
            { disp: "Canada Eastern", zone: "America/Toronto" },
            { disp: "Canada Mountain", zone: "America/Edmonton" },
            { disp: "Canada Pacific", zone: "America/Vancouver" },
            { disp: "Canada Sask", zone: "America/Regina" },
            { disp: "Chile", zone: "America/Santiago" },
            { disp: "Colombia", zone: "America/Bogota" },
            { disp: "Costa Rica", zone: "America/Costa_Rica" },
            { disp: "Cuba", zone: "America/Havana" },
            { disp: "Dominican Rep", zone: "America/Santo_Domingo" },
            { disp: "Ecuador", zone: "America/Guayaquil" },
            { disp: "Guatemala", zone: "America/Guatemala" },
            { disp: "Haiti", zone: "America/Port-au-Prince" },
            { disp: "Mexico", zone: "America/Mexico_City" },
            { disp: "Panama", zone: "America/Panama" },
            { disp: "Paraguay", zone: "America/Asuncion" },
            { disp: "Peru", zone: "America/Lima" },
            { disp: "Puerto Rico", zone: "America/Puerto_Rico" },
            { disp: "USA Alaska", zone: "America/Anchorage" },
            { disp: "USA Arizona", zone: "America/Phoenix" },
            { disp: "USA Central", zone: "America/Chicago" },
            { disp: "USA Eastern", zone: "America/New_York" },
            { disp: "USA Hawaii", zone: "Pacific/Honolulu" },
            { disp: "USA Mountain", zone: "America/Denver" },
            { disp: "USA Pacific", zone: "America/Los_Angeles" },
            { disp: "Uruguay", zone: "America/Montevideo" },
            { disp: "Venezuela", zone: "America/Caracas" }
        ] },
        { region: "Europe", icon: "", color: root.mauve, zones: [
            { disp: "Albania", zone: "Europe/Tirane" },
            { disp: "Austria", zone: "Europe/Vienna" },
            { disp: "Belarus", zone: "Europe/Minsk" },
            { disp: "Belgium", zone: "Europe/Brussels" },
            { disp: "Bosnia", zone: "Europe/Sarajevo" },
            { disp: "Bulgaria", zone: "Europe/Sofia" },
            { disp: "Croatia", zone: "Europe/Zagreb" },
            { disp: "Czech Rep", zone: "Europe/Prague" },
            { disp: "Denmark", zone: "Europe/Copenhagen" },
            { disp: "Estonia", zone: "Europe/Tallinn" },
            { disp: "Finland", zone: "Europe/Helsinki" },
            { disp: "France", zone: "Europe/Paris" },
            { disp: "Germany", zone: "Europe/Berlin" },
            { disp: "Greece", zone: "Europe/Athens" },
            { disp: "Hungary", zone: "Europe/Budapest" },
            { disp: "Iceland", zone: "Atlantic/Reykjavik" },
            { disp: "Ireland", zone: "Europe/Dublin" },
            { disp: "Italy", zone: "Europe/Rome" },
            { disp: "Latvia", zone: "Europe/Riga" },
            { disp: "Lithuania", zone: "Europe/Vilnius" },
            { disp: "Luxembourg", zone: "Europe/Luxembourg" },
            { disp: "Malta", zone: "Europe/Malta" },
            { disp: "Moldova", zone: "Europe/Chisinau" },
            { disp: "Monaco", zone: "Europe/Monaco" },
            { disp: "Netherlands", zone: "Europe/Amsterdam" },
            { disp: "North Macedonia", zone: "Europe/Skopje" },
            { disp: "Norway", zone: "Europe/Oslo" },
            { disp: "Poland", zone: "Europe/Warsaw" },
            { disp: "Portugal", zone: "Europe/Lisbon" },
            { disp: "Romania", zone: "Europe/Bucharest" },
            { disp: "Russia Moscow", zone: "Europe/Moscow" },
            { disp: "Serbia", zone: "Europe/Belgrade" },
            { disp: "Slovakia", zone: "Europe/Bratislava" },
            { disp: "Slovenia", zone: "Europe/Ljubljana" },
            { disp: "Spain", zone: "Europe/Madrid" },
            { disp: "Sweden", zone: "Europe/Stockholm" },
            { disp: "Switzerland", zone: "Europe/Zurich" },
            { disp: "Turkey", zone: "Europe/Istanbul" },
            { disp: "UK", zone: "Europe/London" },
            { disp: "Ukraine", zone: "Europe/Kiev" }
        ] },
        { region: "Asia", icon: "", color: root.green, zones: [
            { disp: "Afghanistan", zone: "Asia/Kabul" },
            { disp: "Armenia", zone: "Asia/Yerevan" },
            { disp: "Azerbaijan", zone: "Asia/Baku" },
            { disp: "Bahrain", zone: "Asia/Bahrain" },
            { disp: "Bangladesh", zone: "Asia/Dhaka" },
            { disp: "Bhutan", zone: "Asia/Thimphu" },
            { disp: "Cambodia", zone: "Asia/Phnom_Penh" },
            { disp: "China", zone: "Asia/Shanghai" },
            { disp: "Cyprus", zone: "Asia/Nicosia" },
            { disp: "Georgia", zone: "Asia/Tbilisi" },
            { disp: "Hong Kong", zone: "Asia/Hong_Kong" },
            { disp: "India", zone: "Asia/Kolkata" },
            { disp: "Indonesia Central", zone: "Asia/Makassar" },
            { disp: "Indonesia West", zone: "Asia/Jakarta" },
            { disp: "Iran", zone: "Asia/Tehran" },
            { disp: "Iraq", zone: "Asia/Baghdad" },
            { disp: "Israel", zone: "Asia/Tel_Aviv" },
            { disp: "Japan", zone: "Asia/Tokyo" },
            { disp: "Jordan", zone: "Asia/Amman" },
            { disp: "Kazakhstan", zone: "Asia/Almaty" },
            { disp: "Kuwait", zone: "Asia/Kuwait" },
            { disp: "Kyrgyzstan", zone: "Asia/Bishkek" },
            { disp: "Lebanon", zone: "Asia/Beirut" },
            { disp: "Macau", zone: "Asia/Macau" },
            { disp: "Malaysia", zone: "Asia/Kuala_Lumpur" },
            { disp: "Maldives", zone: "Indian/Maldives" },
            { disp: "Mongolia", zone: "Asia/Ulaanbaatar" },
            { disp: "Myanmar", zone: "Asia/Yangon" },
            { disp: "Nepal", zone: "Asia/Kathmandu" },
            { disp: "Oman", zone: "Asia/Muscat" },
            { disp: "Pakistan", zone: "Asia/Karachi" },
            { disp: "Philippines", zone: "Asia/Manila" },
            { disp: "Qatar", zone: "Asia/Qatar" },
            { disp: "Saudi Arabia", zone: "Asia/Riyadh" },
            { disp: "Singapore", zone: "Asia/Singapore" },
            { disp: "South Korea", zone: "Asia/Seoul" },
            { disp: "Sri Lanka", zone: "Asia/Colombo" },
            { disp: "Syria", zone: "Asia/Damascus" },
            { disp: "Taiwan", zone: "Asia/Taipei" },
            { disp: "Thailand", zone: "Asia/Bangkok" },
            { disp: "UAE", zone: "Asia/Dubai" },
            { disp: "Uzbekistan", zone: "Asia/Tashkent" },
            { disp: "Vietnam", zone: "Asia/Ho_Chi_Minh" },
            { disp: "Yemen", zone: "Asia/Riyadh" }
        ] },
        { region: "Africa", icon: "", color: root.yellow, zones: [
            { disp: "Algeria", zone: "Africa/Algiers" },
            { disp: "Angola", zone: "Africa/Luanda" },
            { disp: "Benin", zone: "Africa/Porto-Novo" },
            { disp: "Botswana", zone: "Africa/Gaborone" },
            { disp: "Burkina Faso", zone: "Africa/Ouagadougou" },
            { disp: "Burundi", zone: "Africa/Bujumbura" },
            { disp: "Cameroon", zone: "Africa/Douala" },
            { disp: "Cape Verde", zone: "Atlantic/Cape_Verde" },
            { disp: "CAR", zone: "Africa/Bangui" },
            { disp: "Congo", zone: "Africa/Brazzaville" },
            { disp: "Côte d'Ivoire", zone: "Africa/Abidjan" },
            { disp: "Djibouti", zone: "Africa/Djibouti" },
            { disp: "DR Congo", zone: "Africa/Kinshasa" },
            { disp: "Egypt", zone: "Africa/Cairo" },
            { disp: "Eq Guinea", zone: "Africa/Malabo" },
            { disp: "Eritrea", zone: "Africa/Asmara" },
            { disp: "Eswatini", zone: "Africa/Mbabane" },
            { disp: "Ethiopia", zone: "Africa/Addis_Ababa" },
            { disp: "Gabon", zone: "Africa/Libreville" },
            { disp: "Gambia", zone: "Africa/Banjul" },
            { disp: "Ghana", zone: "Africa/Accra" },
            { disp: "Guinea", zone: "Africa/Conakry" },
            { disp: "Guinea-Bissau", zone: "Africa/Bissau" },
            { disp: "Kenya", zone: "Africa/Nairobi" },
            { disp: "Lesotho", zone: "Africa/Maseru" },
            { disp: "Liberia", zone: "Africa/Monrovia" },
            { disp: "Libya", zone: "Africa/Tripoli" },
            { disp: "Madagascar", zone: "Indian/Antananarivo" },
            { disp: "Malawi", zone: "Africa/Blantyre" },
            { disp: "Mali", zone: "Africa/Bamako" },
            { disp: "Mauritania", zone: "Africa/Nouakchott" },
            { disp: "Mauritius", zone: "Indian/Mauritius" },
            { disp: "Morocco", zone: "Africa/Casablanca" },
            { disp: "Mozambique", zone: "Africa/Maputo" },
            { disp: "Namibia", zone: "Africa/Windhoek" },
            { disp: "Niger", zone: "Africa/Niamey" },
            { disp: "Nigeria", zone: "Africa/Lagos" },
            { disp: "Réunion", zone: "Indian/Reunion" },
            { disp: "Rwanda", zone: "Africa/Kigali" },
            { disp: "São Tomé", zone: "Africa/Sao_Tome" },
            { disp: "Senegal", zone: "Africa/Dakar" },
            { disp: "Seychelles", zone: "Indian/Mahe" },
            { disp: "Sierra Leone", zone: "Africa/Freetown" },
            { disp: "Somalia", zone: "Africa/Mogadishu" },
            { disp: "South Africa", zone: "Africa/Johannesburg" },
            { disp: "South Sudan", zone: "Africa/Juba" },
            { disp: "Sudan", zone: "Africa/Khartoum" },
            { disp: "Tanzania", zone: "Africa/Dar_es_Salaam" },
            { disp: "Togo", zone: "Africa/Lome" },
            { disp: "Tunisia", zone: "Africa/Tunis" },
            { disp: "Uganda", zone: "Africa/Kampala" },
            { disp: "W Sahara", zone: "Africa/El_Aaiun" },
            { disp: "Zambia", zone: "Africa/Lusaka" },
            { disp: "Zimbabwe", zone: "Africa/Harare" }
        ] },
        { region: "Pacific", icon: "", color: root.sapphire, zones: [
            { disp: "American Samoa", zone: "Pacific/Pago_Pago" },
            { disp: "Australia Central", zone: "Australia/Adelaide" },
            { disp: "Australia Eastern", zone: "Australia/Sydney" },
            { disp: "Australia Lord Howe", zone: "Australia/Lord_Howe" },
            { disp: "Australia Western", zone: "Australia/Perth" },
            { disp: "Cook Is", zone: "Pacific/Rarotonga" },
            { disp: "Fiji", zone: "Pacific/Fiji" },
            { disp: "French Polynesia", zone: "Pacific/Tahiti" },
            { disp: "Guam", zone: "Pacific/Guam" },
            { disp: "Hawaii", zone: "Pacific/Honolulu" },
            { disp: "Kiribati", zone: "Pacific/Tarawa" },
            { disp: "Marshall Is", zone: "Pacific/Majuro" },
            { disp: "Micronesia", zone: "Pacific/Chuuk" },
            { disp: "New Caledonia", zone: "Pacific/Noumea" },
            { disp: "New Zealand", zone: "Pacific/Auckland" },
            { disp: "Niue", zone: "Pacific/Niue" },
            { disp: "Papua New Guinea", zone: "Pacific/Port_Moresby" },
            { disp: "Pitcairn Is", zone: "Pacific/Pitcairn" },
            { disp: "Samoa", zone: "Pacific/Apia" },
            { disp: "Solomon Is", zone: "Pacific/Guadalcanal" },
            { disp: "Tonga", zone: "Pacific/Tongatapu" },
            { disp: "Tuvalu", zone: "Pacific/Funafuti" },
            { disp: "Vanuatu", zone: "Pacific/Efate" }
        ] }
    ]

    property int selectedContinent: 0
    property real colorBlend: 0.0
    SequentialAnimation on colorBlend {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine }
    }
    
    property color ambientPurple: Qt.tint(root.mauve, Qt.rgba(root.pink.r, root.pink.g, root.pink.b, colorBlend))
    property color ambientBlue: Qt.tint(root.blue, Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, colorBlend))

    // -------------------------------------------------------------------------
    // GLOBALS
    // -------------------------------------------------------------------------
    property string dotsVersion: "Loading..."
    property string dotsVersionName: ""
    property string updateRemoteVer: ""
    property string updateStatusText: "Click CHECK"
    property string updateStatusIcon: ""
    property color updateStatusColor: root.subtext0
    property bool checkingUpdates: false

    Process {
        id: versionReader
        command: ["bash", "-c", "source ~/.local/state/wiferice-version 2>/dev/null && echo \"${LOCAL_VERSION:-Unknown}|${LOCAL_VERSION_NAME:-}\" || echo 'Unknown|'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text ? this.text.trim() : "";
                if (out !== "") {
                    let parts = out.split("|");
                    if (parts.length > 0) root.dotsVersion = parts[0];
                    if (parts.length > 1) root.dotsVersionName = parts[1];
                }
            }
        }
    }

    Process {
        id: updateChecker
        running: false
        command: ["bash", "-c", "LOCAL_VER=$(source ~/.local/state/wiferice-version 2>/dev/null && echo \"$LOCAL_VERSION\" || echo \"Unknown\"); REMOTE_VER=$(curl -m 5 -sL https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh | grep '^DOTS_VERSION=' | cut -d'\"' -f2); echo \"${LOCAL_VER:-Unknown}|${REMOTE_VER:-ERROR}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text ? this.text.trim() : "";
                root.checkingUpdates = false;
                if (out !== "") {
                    let parts = out.split("|");
                    let local = parts.length > 0 ? parts[0].trim() : "";
                    let remote = parts.length > 1 ? parts[1].trim() : "";
                    if (remote === "" || remote === "ERROR") {
                        root.updateStatusText = "Check failed";
                        root.updateStatusIcon = "";
                        root.updateStatusColor = root.red;
                    } else if (remote === local) {
                        root.updateStatusText = "Up to date";
                        root.updateStatusIcon = "";
                        root.updateStatusColor = root.green;
                    } else {
                        root.updateRemoteVer = remote;
                        root.updateStatusText = "v" + remote + " available";
                        root.updateStatusIcon = "󰚰";
                        root.updateStatusColor = root.peach;
                    }
                } else {
                    root.updateStatusText = "Check failed";
                    root.updateStatusIcon = "";
                    root.updateStatusColor = root.red;
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // SYSTEM INFO PROPERTIES & FETCHER (CACHED)
    // -------------------------------------------------------------------------
    property string sysUser: "Loading..."
    property string sysHost: "Loading..."
    property string sysOS: "Loading..."
    property string sysKernel: "Loading..."
    property string sysCPU: "Loading..."
    property string sysGPU: "Loading..."
    property string faceIconPath: ""
    property string sysUptime: "Loading..."

    Process {
        id: sysInfoProc
        running: true
        command: [
            "bash", "-c",
            "CACHE=\"$HOME/.cache/qs_sysinfo.txt\"; " +
            "if [ ! -f \"$CACHE\" ]; then " +
            "  ICON=\"\"; if [ -f ~/.face.icon ]; then ICON=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON=$(readlink -f ~/.face); fi; " +
            "  echo \"$(whoami)|$(hostname)|$(uname -r)|$(cat /etc/os-release | grep '^PRETTY_NAME=' | cut -d'=' -f2 | tr -d '\\\"')|$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs)|$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | tail -n1 | cut -d':' -f3 | xargs)|$ICON\" > \"$CACHE\"; " +
            "fi; " +
            "cat \"$CACHE\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let line = this.text ? this.text.trim() : "";
                let parts = line.split("|");
                if (parts.length >= 6) {
                    root.sysUser = parts[0];
                    root.sysHost = parts[1];
                    root.sysKernel = parts[2];
                    root.sysOS = parts[3];
                    root.sysCPU = parts[4];
                    root.sysGPU = parts[5] ? parts[5] : "Integrated Graphics";
                    if (parts.length >= 7 && parts[6].trim() !== "") root.faceIconPath = parts[6].trim();
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // STATE MANAGEMENT & DATA
    // -------------------------------------------------------------------------
    property int currentTab: 1
    property int selectedModuleIndex: 0

    function setTab(tab) {
        if (currentTab === 2 && tab !== 2) {
            videoPreview.pause()
        }
        currentTab = tab
        if (currentTab === 2) {
            if (previewContainer.isVideoModule && videoPreview.source !== "") {
                videoPreview.play()
            }
        }
    }
    property var tabNames: ["Settings", "System", "Modules", "Matugen", "Time", "About", "Updates"]
    property var tabIcons: ["", "", "󰣆", "󰏘", "", "", "󰑖"]

    property real introBase: 0.0
    property real introSidebar: 0.0
    property real introContent: 0.0

    ListModel {
        id: modulesDataModel
        ListElement { title: "Calendar & Weather"; target: "calendar"; icon: ""; desc: "Dual-sync calendar with live \nOpenWeatherMap integration."; preview: "previews/preview_calendar.png" }
        ListElement { title: "Media & Lyrics"; target: "music"; icon: "󰎆"; desc: "PlayerCtl integration, Cava \nvisualizer, and live lyrics."; preview: "previews/preview_music.png" }
        ListElement { title: "Battery & Power"; target: "battery"; icon: "󰁹"; desc: "Uptime tracking, power profiles, \nand battery health metrics."; preview: "previews/preview_battery.png" }
        ListElement { title: "Network Hub"; target: "network"; icon: "󰤨"; desc: "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez."; preview: "previews/preview_network.png" }
        ListElement { title: "FocusTime"; target: "focustime"; icon: "󰄉"; desc: "Built-in Pomodoro timer daemon \nwith session tracking."; preview: "previews/preview_focustime.png" }
        ListElement { title: "Volume Mixer"; target: "volume"; icon: "󰕾"; desc: "Pipewire integration for I/O \nvolume and stream routing."; preview: "previews/preview_volume.png" }
        ListElement { title: "Wallpaper Picker"; target: "wallpaper"; icon: ""; desc: "Live awww backend rendering \nwith Matugen color generation."; preview: "previews/preview_wallpaper.png" }
        ListElement { title: "Himeno Sexy Scene"; target: "himeno"; icon: "󰎁"; desc: "Step on me mommy......\nI'd let her drain me dry.\nShe can ruin my life fr."; preview: "previews/himeno_clip.mp4" }
        ListElement { title: "Monitors"; target: "monitors"; icon: "󰍹"; desc: "Quick display management."; preview: "previews/preview_monitors.png" }
        ListElement { title: "Stewart AI"; target: "stewart"; icon: "󰚩"; desc: "Voice assistant integration.\n(Reserved for future, currently disabled)"; preview: "previews/preview_stewart.png" }
    }

    Process {
        id: fullVideoProcess
        command: ["mpv", "--geometry=960x540", "--keepaspect-window", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/guide/previews/himeno_clip.mp4"]
        running: false
    }



    Component.onCompleted: { 
        startupSequence.start();
        previewContainer.refreshPreview();
    }

    Component.onDestruction: {
        videoPreview.stop()
        fullVideoProcess.running = false
    }

    ParallelAnimation {
        id: startupSequence
        NumberAnimation { 
            target: root
            property: "introBase"
            from: 0.0
            to: 1.0
            duration: 900
            easing.type: Easing.OutExpo 
        }
        SequentialAnimation { 
            PauseAnimation { duration: 150 }
            NumberAnimation { 
                target: root
                property: "introSidebar"
                from: 0.0
                to: 1.0
                duration: 1000
                easing.type: Easing.OutBack
                easing.overshoot: 1.05 
            } 
        }
        SequentialAnimation { 
            PauseAnimation { duration: 250 }
            NumberAnimation { 
                target: root
                property: "introContent"
                from: 0.0
                to: 1.0
                duration: 1100
                easing.type: Easing.OutBack
                easing.overshoot: 1.02 
            } 
        }
    }

    SequentialAnimation {
        id: closeSequence
        ScriptAction {
            script: {
                videoPreview.stop()
                fullVideoProcess.running = false
            }
        }
        ParallelAnimation { 
            NumberAnimation { 
                target: root
                property: "introContent"
                to: 0.0
                duration: 150
                easing.type: Easing.InExpo 
            }
            NumberAnimation { 
                target: root
                property: "introSidebar"
                to: 0.0
                duration: 150
                easing.type: Easing.InExpo 
            } 
        }
        NumberAnimation { 
            target: root
            property: "introBase"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuart 
        }
        ScriptAction { 
            script: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]) 
        }
    }

    // -------------------------------------------------------------------------
    // BACKGROUND AMBIENCE (Enhanced with more/bigger orbs)
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introBase
        scale: 0.95 + (0.05 * introBase)
        
        Rectangle {
            anchors.fill: parent
            radius: root.s(16)
            color: root.base
            border.color: root.surface0
            border.width: 1
            clip: true
            
            property real time: 0
            NumberAnimation on time { 
                from: 0
                to: Math.PI * 2
                duration: 20000
                loops: Animation.Infinite
                running: true 
            }
            
            // Orb 1
            Rectangle {
                width: root.s(800)
                height: root.s(800)
                radius: root.s(400)
                x: parent.width * 0.5 + Math.cos(parent.time) * root.s(150)
                y: parent.height * 0.1 + Math.sin(parent.time * 1.5) * root.s(150)
                color: root.ambientPurple
                opacity: 0.06
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 100; blur: 1.0 }
            }
            
            // Orb 2
            Rectangle {
                width: root.s(900)
                height: root.s(900)
                radius: root.s(450)
                x: parent.width * 0.1 + Math.sin(parent.time * 0.8) * root.s(200)
                y: parent.height * 0.4 + Math.cos(parent.time * 1.2) * root.s(150)
                color: root.ambientBlue
                opacity: 0.05
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 110; blur: 1.0 }
            }

            // Orb 3
            Rectangle {
                width: root.s(700)
                height: root.s(700)
                radius: root.s(350)
                x: parent.width * 0.3 + Math.cos(parent.time * 1.1) * root.s(120)
                y: parent.height * 0.6 + Math.sin(parent.time * 0.9) * root.s(180)
                color: Qt.tint(root.peach, Qt.rgba(root.yellow.r, root.yellow.g, root.yellow.b, colorBlend))
                opacity: 0.04
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 90; blur: 1.0 }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MAIN LAYOUT
    // -------------------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.s(20)
        spacing: root.s(20)

        // ==========================================
        // SIDEBAR
        // ==========================================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.s(220)
            radius: root.s(12)
            color: Qt.alpha(root.surface0, 0.4)
            border.color: root.surface1
            border.width: 1
            opacity: introSidebar
            transform: Translate { x: root.s(-30) * (1.0 - introSidebar) }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.s(15)
                spacing: root.s(10)
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(60)
                    
                    RowLayout {
                        anchors.fill: parent
                        spacing: root.s(12)
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: root.s(36)
                            height: root.s(36)
                            radius: root.s(10)
                            color: root.ambientPurple
                            Text { 
                                anchors.centerIn: parent
                                text: "󰣇"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: root.s(20)
                                color: root.base 
                            }
                        }
                        
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: root.s(2)
                            Text { 
                                text: "Imperative"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: root.s(15)
                                color: root.text
                                Layout.alignment: Qt.AlignLeft 
                            }
                            Text { 
                                text: root.dotsVersion !== "Loading..." ? "v" + root.dotsVersion + (root.dotsVersionName !== "" ? " " + root.dotsVersionName : "") : "..."
                                font.family: "JetBrains Mono"
                                font.pixelSize: root.s(11)
                                color: root.subtext0
                                Layout.alignment: Qt.AlignLeft 
                            }
                        }
                    }
                }

                Rectangle { 
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.alpha(root.surface1, 0.5)
                    Layout.bottomMargin: root.s(10) 
                }

                // --- MORPHING TABS LOGIC ---
                Item {
                    Layout.fillWidth: true
                    // Dynamically set height based on elements: (Tabs count * 44) + 1 Divider (21)
                    Layout.preferredHeight: root.s(65) + (root.tabNames.length - 1) * root.s(44)

                    // The Morphing Highlight Background
                    Rectangle {
                        id: activeHighlight
                        width: parent.width
                        height: root.s(44)
                        radius: root.s(8)
                        color: root.mauve
                        z: 0

                        property int curIdx: root.currentTab
                        // Index 0 starts at 0. Index 1 starts after Index 0 (44) and Divider (21) = 65
                        property real targetY: curIdx === 0 ? 0 : root.s(65) + (curIdx - 1) * root.s(44)
                        y: targetY

                        Behavior on y {
                            NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 0
                        
                        Repeater {
                            model: root.tabNames.length
                            
                            Column {
                                width: parent.width

                                Rectangle {
                                    width: parent.width
                                    height: root.s(44)
                                    radius: root.s(8)
                                    z: 1
                                    
                                    property bool isActive: root.currentTab === index
                                    property bool tabHovered: false
                                    color: isActive ? "transparent" : (tabHovered ? Qt.alpha(root.surface1, 0.5) : "transparent")
                                    scale: isActive ? 1.0 : (tabHovered ? 1.04 : 1.0)
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: root.s(15)
                                        spacing: root.s(12)

                                        // The "Slide Right" text effect from snippet 2
                                        property real contentShift: parent.isActive ? root.s(6) : 0
                                        Behavior on contentShift { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                        transform: Translate { x: contentShift }
                                        
                                        Item {
                                            Layout.preferredWidth: root.s(24)
                                            Layout.alignment: Qt.AlignVCenter
                                            Text { 
                                                anchors.centerIn: parent
                                                text: root.tabIcons[index]
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: root.s(18)
                                                // Dynamic colors (crust vs subtext0) for contrast
                                                color: parent.parent.parent.isActive ? root.crust : root.subtext0
                                                Behavior on color { ColorAnimation { duration: 150 } } 
                                            }
                                        }
                                        
                                        Text { 
                                            text: root.tabNames[index]
                                            font.family: "JetBrains Mono"
                                            font.weight: parent.parent.isActive ? Font.Bold : Font.Medium
                                            font.pixelSize: root.s(13)
                                            // Dynamic colors (crust vs subtext0) for contrast
                                            color: parent.parent.isActive ? root.crust : root.subtext0
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            Behavior on color { ColorAnimation { duration: 150 } } 
                                        }
                                    }
                                    
                                    MouseArea { 
                                        id: tabMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: parent.tabHovered = true
                                        onExited: parent.tabHovered = false
                                        onClicked: {
                                            if (index === 0) {
                                                root.setTab(0)
                                                Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", "settings"]);
                                            } else {
                                                root.setTab(index);
                                            }
                                        } 
                                    }
                                }
                                
                                // Divider natively wrapped to provide spacing
                                Item {
                                    visible: index === 0
                                    width: parent.width
                                    height: root.s(21) // 10 top + 1 mid + 10 bot
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: 1
                                        color: Qt.alpha(root.surface1, 0.5)
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // --- CLOSE BUTTON ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(44)
                    radius: root.s(8)
                    color: closeHover.containsMouse ? Qt.alpha(root.red, 0.1) : "transparent"
                    border.color: closeHover.containsMouse ? root.red : root.surface1
                    border.width: 1
                    scale: closeHover.pressed ? 0.95 : (closeHover.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Item {
                        anchors.centerIn: parent
                        width: arrowText.implicitWidth
                        height: arrowText.implicitHeight
                        Text { 
                            id: arrowText
                            text: ""
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: root.s(16)
                            color: closeHover.containsMouse ? root.red : root.subtext0
                            Behavior on color { ColorAnimation { duration: 150 } } 
                        }
                    }
                    MouseArea { 
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: closeSequence.start() 
                    }
                }
            }
        }

        // ==========================================
        // CONTENT AREA
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: introContent
            scale: 0.95 + (0.05 * introContent)
            transform: Translate { y: root.s(20) * (1.0 - introContent) }

            // ------------------------------------------
            // TAB 1: SYSTEM OVERVIEW
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 1 ? 1.0 : 0.0
                scale: root.currentTab === 1 ? 1.0 : 0.95
                property real slideY: root.currentTab === 1 ? 0 : root.s(10)
                enabled: root.currentTab === 1
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                ListModel {
                    id: systemDataModel
                    ListElement { pkg: "Hyprland"; role: "Wayland Compositor"; icon: ""; clr: "blue"; link: "https://hyprland.org/" }
                    ListElement { pkg: "Quickshell"; role: "UI Framework"; icon: "󰣆"; clr: "mauve"; link: "https://git.outfoxxed.me/outfoxxed/quickshell" }
                    ListElement { pkg: "Matugen"; role: "Theme Engine"; icon: "󰏘"; clr: "peach"; link: "https://github.com/InioX/matugen" }
                    ListElement { pkg: "Rofi Wayland"; role: "App Launcher"; icon: ""; clr: "green"; link: "https://github.com/lbonn/rofi" }
                    ListElement { pkg: "Kitty"; role: "Terminal Emulator"; icon: "󰄛"; clr: "yellow"; link: "https://sw.kovidgoyal.net/kitty/" }
                    ListElement { pkg: "SwayOSD / NC"; role: "Overlays & Notifs"; icon: "󰂚"; clr: "pink"; link: "https://github.com/ErikReider/SwayOSD" }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: root.s(15)
                    anchors.leftMargin: root.s(20)
                    anchors.rightMargin: root.s(20)
                    anchors.bottomMargin: root.s(20)
                    spacing: root.s(20)

                    // ENHANCED DEVICE INFO BLOCK
                    Rectangle {
                        id: sysBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(180)
                        radius: root.s(16)
                        color: sysBoxMa.containsMouse ? Qt.alpha(root.surface0, 0.7) : Qt.alpha(root.surface0, 0.4)
                        border.color: sysBoxMa.containsMouse ? root.ambientBlue : root.surface1
                        border.width: 1
                        clip: true
                        
                        Behavior on color { ColorAnimation { duration: 300 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Rectangle {
                            width: root.s(250)
                            height: root.s(250)
                            radius: root.s(125)
                            color: root.ambientBlue
                            opacity: 0.15
                            x: sysBoxMa.containsMouse ? parent.width * 0.7 : parent.width * 0.8
                            y: -root.s(50)
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0 }
                            Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
                        }
                        
                        Rectangle {
                            width: root.s(200)
                            height: root.s(200)
                            radius: root.s(100)
                            color: root.ambientPurple
                            opacity: 0.15
                            x: sysBoxMa.containsMouse ? root.s(50) : -root.s(50)
                            y: root.s(20)
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0 }
                            Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.s(20)
                            spacing: root.s(30)

                            Item {
                                id: avatarContainer
                                Layout.preferredWidth: root.s(100)
                                Layout.preferredHeight: root.s(100)

                                property real glowAngle: 0
                                NumberAnimation on glowAngle {
                                    from: 0
                                    to: 360
                                    duration: 8000
                                    loops: Animation.Infinite
                                    easing.type: Easing.Linear
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: root.s(100)
                                    height: root.s(100)
                                    radius: root.s(50)
                                    color: "transparent"
                                    border.color: Qt.alpha(root.ambientPurple, sysBoxMa.containsMouse ? 0.9 : 0.5)
                                    border.width: root.s(4)
                                    scale: sysBoxMa.containsMouse ? 1.05 : 1.0
                                    
                                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                                    Behavior on border.color { ColorAnimation { duration: 300 } }
                                    
                                    RotationAnimation on rotation { 
                                        from: 0
                                        to: 360
                                        duration: 15000
                                        loops: Animation.Infinite
                                        running: true 
                                    }
                                }

                                Item {
                                    anchors.centerIn: parent
                                    width: root.s(84)
                                    height: root.s(84)
                                    
                                    Rectangle { 
                                        id: avatarMaskTab0
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "black"
                                        visible: false
                                        layer.enabled: true 
                                    }
                                    
                                    Image {
                                        id: userAvatarImg
                                        anchors.fill: parent
                                        source: root.faceIconPath !== "" ? "file://" + root.faceIconPath.replace("file://", "") : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: false
                                        asynchronous: true
                                        smooth: true
                                        mipmap: true
                                    }
                                    
                                    MultiEffect { 
                                        source: userAvatarImg
                                        anchors.fill: userAvatarImg
                                        maskEnabled: true
                                        maskSource: avatarMaskTab0
                                        visible: root.faceIconPath !== "" 
                                    }
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: root.faceIconPath === "" ? root.surface0 : "transparent"
                                        border.color: root.surface2
                                        border.width: 1
                                        Text { 
                                            anchors.centerIn: parent
                                            text: ""
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: root.s(42)
                                            color: root.text
                                            visible: root.faceIconPath === ""
                                            scale: sysBoxMa.containsMouse ? 1.1 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: root.s(8)
                                
                                Text { 
                                    text: root.sysUser
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: root.s(24)
                                    color: root.text 
                                }
                                
                        Text {
                            text: ""
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: root.s(16)
                            color: root.blue
                            Layout.alignment: Qt.AlignVCenter
                        }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Qt.alpha(root.surface1, 0.5)
                                    Layout.topMargin: root.s(5)
                                    Layout.bottomMargin: root.s(5) 
                                }

                                RowLayout {
                                    spacing: root.s(15)
                                    RowLayout { 
                                        spacing: root.s(6)
                                        Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root.blue } 
                                        Text { text: root.sysOS; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.subtext0 } 
                                    }
                                    RowLayout { 
                                        spacing: root.s(6)
                                        Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root.peach } 
                                        Text { text: root.sysKernel; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.subtext0 } 
                                    }
                                }
                                
                                RowLayout {
                                    spacing: root.s(15)
                                    RowLayout { 
                                        spacing: root.s(6)
                                        Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root.green } 
                                        Text { 
                                            text: root.sysCPU
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            font.pixelSize: root.s(12)
                                            color: root.subtext0
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: root.s(220) 
                                        } 
                                    }
                                    RowLayout { 
                                        spacing: root.s(6)
                                        Text { text: "󰢮"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root.yellow } 
                                        Text { 
                                            text: root.sysGPU
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Medium
                                            font.pixelSize: root.s(12)
                                            color: root.subtext0
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: root.s(220) 
                                        } 
                                    }
                                }
                            }
                        }
                        MouseArea { id: sysBoxMa; anchors.fill: parent; hoverEnabled: true }
                    }

                    // AUTHOR BLOCK
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(50)
                        radius: root.s(10)
                        color: authorMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.4)
                        border.color: authorMa.containsMouse ? root.mauve : root.surface1
                        border.width: authorMa.containsMouse ? 2 : 1
                        scale: authorMa.pressed ? 0.97 : (authorMa.containsMouse ? 1.02 : 1.0)
                        
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Behavior on border.width { NumberAnimation { duration: 200 } }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: root.s(12)
                            spacing: root.s(15)
                            
                            Rectangle { 
                                Layout.alignment: Qt.AlignVCenter
                                width: root.s(32)
                                height: root.s(32)
                                radius: root.s(8)
                                color: root.surface0
                                border.color: root.surface2
                                border.width: 1
                                Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(20); color: root.text } 
                            }
                            
                            Row {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: root.s(1)
                                Repeater {
                                    model: [ { l: "e", c: root.red }, { l: "p", c: root.peach }, { l: "r", c: root.yellow }, { l: "a", c: root.green }, { l: "h", c: root.sapphire }, { l: "e", c: root.blue }, { l: "m", c: root.mauve }, { l: "i", c: root.pink } ]
                                    Text { 
                                        text: modelData.l
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Black
                                        font.pixelSize: root.s(14)
                                        color: modelData.c
                                        property real hoverOffset: authorMa.containsMouse ? root.s(-4) : 0
                                        transform: Translate { y: hoverOffset }
                                        Behavior on hoverOffset { NumberAnimation { duration: 300 + (index * 40); easing.type: Easing.OutBack } } 
                                    }
                                }
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Rectangle { 
                                Layout.alignment: Qt.AlignVCenter
                                width: root.s(28)
                                height: root.s(28)
                                radius: root.s(6)
                                color: authorMa.containsMouse ? Qt.alpha(root.mauve, 0.15) : "transparent"
                                scale: authorMa.containsMouse ? 1.1 : 1.0
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Text { 
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: root.s(14)
                                    color: authorMa.containsMouse ? root.mauve : root.subtext0
                                    Behavior on color { ColorAnimation { duration: 200 } } 
                                } 
                            }
                        }
                        MouseArea { 
                            id: authorMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/eprahemi"]) 
                        }
                    }

                    // MODULES AND QUICK LINKS ROW
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.s(15)
                        
                        Repeater {
                            model: [ 
                                { name: "Settings", icon: "", color: "mauve", targetTab: 0, isToggle: true }, 
                                { name: "Modules", icon: "󰣆", color: "blue", targetTab: 2, isToggle: false } 
                            ]
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.s(44)
                                radius: root.s(8)
                                property bool navHovered: false
                                color: navHovered ? Qt.alpha(root.surface1, 0.5) : Qt.alpha(root.surface0, 0.4)
                                border.color: navHovered ? root[modelData.color] : root.surface1
                                border.width: navHovered ? 2 : 1
                                scale: navBtnMa.pressed ? 0.95 : (navHovered ? 1.03 : 1.0)
                                
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Behavior on border.width { NumberAnimation { duration: 200 } }
                                
                                RowLayout { 
                                    anchors.centerIn: parent
                                    spacing: root.s(10)
                                    Text { 
                                        text: modelData.icon
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: root.s(16)
                                        color: navHovered ? root[modelData.color] : root.subtext0
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text { text: modelData.name; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(13); color: root.text } 
                                }
                                
                                MouseArea { 
                                    id: navBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.navHovered = true
                                    onExited: parent.navHovered = false
                                    onClicked: {
                                        if (modelData.isToggle) {
                                            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", "settings"]);
                                        } else {
                                            root.setTab(modelData.targetTab);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text { 
                        text: "System Architecture"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: root.s(24)
                        color: root.text
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: root.s(5) 
                    }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: root.s(15)
                        columnSpacing: root.s(15)
                        
                        Repeater {
                            model: systemDataModel
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.s(60)
                                radius: root.s(10)
                                property bool cardHovered: false
                                color: cardHovered ? Qt.alpha(root.surface1, 0.5) : Qt.alpha(root.surface0, 0.4)
                                border.color: cardHovered ? root[model.clr] : root.surface1
                                border.width: cardHovered ? 2 : 1
                                scale: sysCardMa.pressed ? 0.97 : (cardHovered ? 1.02 : 1.0)
                                
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Behavior on border.width { NumberAnimation { duration: 200 } }
                                
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: root.s(10)
                                    
                                    Item { 
                                        id: sysIconBox
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: root.s(36)
                                        height: root.s(36)
                                        scale: cardHovered ? 1.15 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                        Text { anchors.centerIn: parent; text: model.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(22); color: root[model.clr] } 
                                    }
                                    
                                    Column { 
                                        anchors.left: sysIconBox.right
                                        anchors.leftMargin: root.s(15)
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: root.s(2)
                                        Text { text: model.pkg; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: root.text } 
                                        Text { text: model.role; font.family: "JetBrains Mono"; font.pixelSize: root.s(11); color: root.subtext0 } 
                                    }
                                }
                                
                                MouseArea { 
                                    id: sysCardMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.cardHovered = true
                                    onExited: parent.cardHovered = false
                                    onClicked: Quickshell.execDetached(["xdg-open", model.link]) 
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // ─── COPYRIGHT ────────────────────────
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.s(14)
                    width: copyRow.width
                    height: copyRow.height

                    Row {
                        id: copyRow
                        spacing: root.s(1)
                        Text {
                            text: "© "
                            font.family: "JetBrains Mono"
                            font.pixelSize: root.s(13)
                            color: Qt.alpha(root.subtext0, 0.4)
                        }
                        Repeater {
                            model: [ { l: "e", c: root.red }, { l: "p", c: root.peach }, { l: "r", c: root.yellow }, { l: "a", c: root.green }, { l: "h", c: root.sapphire }, { l: "e", c: root.blue }, { l: "m", c: root.mauve }, { l: "i", c: root.pink } ]
                            Text {
                                text: modelData.l
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: root.s(13)
                                color: modelData.c
                                property real hoverOffset: copyMa.containsMouse ? root.s(-4) : 0
                                transform: Translate { y: hoverOffset }
                                Behavior on hoverOffset { NumberAnimation { duration: 300 + (index * 40); easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    MouseArea {
                        id: copyMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/eprahemi"])
                    }
                }
            }

            // ------------------------------------------
            // TAB 2: MODULES
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 2 ? 1.0 : 0.0
                scale: root.currentTab === 2 ? 1.0 : 0.95
                property real slideY: root.currentTab === 2 ? 0 : root.s(10)
                enabled: root.currentTab === 2
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: root.s(15)
                    anchors.leftMargin: root.s(20)
                    anchors.rightMargin: root.s(20)
                    anchors.bottomMargin: root.s(20)
                    spacing: root.s(20)

                    RowLayout {
                        Layout.fillWidth: true
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.s(4)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: root.s(8)

                                Text {
                                    text: "Interactive Modules"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: root.s(28)
                                    color: root.text
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                        
                        Item { Layout.fillWidth: true } 
                        
                        Rectangle {
                            Layout.preferredWidth: root.s(110)
                            Layout.preferredHeight: root.s(44)
                            radius: root.s(22)
                            color: launchMa.containsMouse ? Qt.alpha(root.ambientBlue, 0.9) : Qt.alpha(root.ambientBlue, 0.7)
                            border.color: root.ambientBlue
                            border.width: 1
                            scale: launchMa.pressed ? 0.95 : (launchMa.containsMouse ? 1.05 : 1.0)
                            
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout { 
                                anchors.centerIn: parent
                                spacing: root.s(8)
                                Text { text: "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(20); color: root.base } 
                                Text { text: "PLAY"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(14); color: root.base } 
                            }
                            
                            MouseArea { 
                                id: launchMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", modulesDataModel.get(root.selectedModuleIndex).target]) 
                            }
                        }
                    }

                    Rectangle {
                        id: previewContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: root.s(12)
                        color: root.surface0
                        border.color: root.surface2
                        border.width: 1
                        clip: true
                        
                        property string targetSource: modulesDataModel.get(root.selectedModuleIndex).preview ? Qt.resolvedUrl(modulesDataModel.get(root.selectedModuleIndex).preview) : ""
                        property bool isVideoModule: modulesDataModel.get(root.selectedModuleIndex).target === "himeno"
                        property bool videoActive: false
                        
                        onTargetSourceChanged: { refreshPreview(); }
                        
                        function refreshPreview() {
                            if (isVideoModule) {
                                baseImage.source = overlayImage.source;
                                overlayImage.opacity = 0.0;
                                overlayImage.source = Qt.resolvedUrl("previews/preview_himeno.png");
                                fadeAnim.restart();
                                videoPreview.source = targetSource;
                                videoPreview.play();
                            } else {
                                videoPreview.stop();
                                videoPreview.source = "";
                                previewContainer.videoActive = false;
                                videoPreview.opacity = 0;
                                baseImage.opacity = 1;
                                baseImage.source = overlayImage.source;
                                overlayImage.opacity = 0.0;
                                overlayImage.source = targetSource;
                                fadeAnim.restart();
                            }
                        }

                        ParallelAnimation {
                            id: videoEnterAnim
                            NumberAnimation { target: baseImage; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { target: overlayImage; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { target: videoPreview; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutQuad }
                        }
                        
                        Video {
                            id: videoPreview
                            anchors.fill: parent
                            fillMode: VideoOutput.PreserveAspectCrop
                            visible: true
                            opacity: 0
                            autoPlay: true
                            loops: MediaPlayer.Infinite
                            z: 2
                            onPlaying: {
                                if (!previewContainer.videoActive) {
                                    previewContainer.videoActive = true;
                                    videoEnterAnim.restart();
                                }
                            }
                        }
                        
                        Image { 
                            id: baseImage
                            anchors.fill: parent
                            anchors.margins: 0
                            fillMode: Image.PreserveAspectCrop
                            verticalAlignment: Image.AlignTop
                            horizontalAlignment: Image.AlignHCenter
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            z: 0
                        }
                        
                        Image { 
                            id: overlayImage
                            anchors.fill: parent
                            anchors.margins: 0
                            fillMode: Image.PreserveAspectCrop
                            verticalAlignment: Image.AlignTop
                            horizontalAlignment: Image.AlignHCenter
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            z: 1
                            NumberAnimation on opacity { 
                                id: fadeAnim
                                to: 1.0
                                duration: 350
                                easing.type: Easing.InOutQuad 
                            } 
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0)
                            visible: false

                            Item {
                                anchors.fill: parent
                                visible: previewContainer.isVideoModule

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.margins: root.s(8)
                                    width: root.s(28)
                                    height: root.s(28)
                                    radius: width / 2
                                    color: vidBtnMa.containsMouse ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(0, 0, 0, 0.5)
                                    border.color: Qt.rgba(1, 1, 1, 0.2)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "♪"
                                        color: "white"
                                        font.pixelSize: root.s(14)
                                    }

                                    MouseArea {
                                        id: vidBtnMa
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: fullVideoProcess.running = true
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: modulesList
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(90)
                        orientation: ListView.Horizontal
                        spacing: root.s(15)
                        clip: true
                        model: modulesDataModel
                        currentIndex: root.selectedModuleIndex
                        highlightMoveDuration: 250
                        
                        delegate: Rectangle {
                            width: root.s(220)
                            height: root.s(90)
                            radius: root.s(12)
                            property bool isSelected: index === root.selectedModuleIndex
                            property bool isHimeno: model.target === "himeno"
                            color: isHimeno ? (isSelected ? Qt.rgba(0.8, 0.15, 0.15, 0.5) : (modMa.containsMouse ? Qt.rgba(0.8, 0.15, 0.15, 0.35) : Qt.rgba(0.8, 0.1, 0.1, 0.2))) : (isSelected ? root.surface1 : (modMa.containsMouse ? Qt.alpha(root.surface1, 0.5) : Qt.alpha(root.surface0, 0.4)))
                            border.color: isHimeno ? (isSelected ? pulseColor : (modMa.containsMouse ? "#dd3333" : "#aa2222")) : (isSelected ? root.ambientBlue : (modMa.containsMouse ? root.surface2 : root.surface1))
                            border.width: isSelected ? 2 : (isHimeno ? 2 : 1)
                            scale: isSelected ? 1.0 : (modMa.pressed ? 0.96 : (modMa.containsMouse ? (isHimeno ? 1.06 : 1.02) : 1.0))
                            
                            property color pulseColor: "#ff4444"
                            ColorAnimation on pulseColor {
                                running: isHimeno && isSelected
                                loops: Animation.Infinite
                                duration: 1500
                                from: "#ff4444"
                                to: "#ff8888"
                                easing.type: Easing.InOutSine
                            }
                            
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -root.s(6)
                                radius: root.s(16)
                                color: Qt.rgba(0.8, 0.1, 0.1, 0.15)
                                visible: parent.isHimeno
                                z: -1
                                layer.enabled: true
                                layer.effect: MultiEffect { blurEnabled: true; blurMax: 16; blur: 0.8 }
                            }
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: root.s(12)
                                spacing: root.s(5)
                                RowLayout { 
                                    spacing: root.s(10)
                                    Rectangle { 
                                        Layout.alignment: Qt.AlignVCenter
                                        width: root.s(28)
                                        height: root.s(28)
                                        radius: root.s(6)
                                        color: isHimeno ? Qt.rgba(0.8, 0.1, 0.1, 0.4) : Qt.alpha(root.base, 0.5)
                                        Text { anchors.centerIn: parent; text: model.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: isHimeno ? "#ff6666" : (isSelected ? root.ambientBlue : root.text) } 
                                    } 
                                    Text { 
                                        text: model.title
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: root.s(12)
                                        color: isHimeno ? "#ff6666" : root.text
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        elide: Text.ElideRight 
                                    }
                                    Text {
                                        text: "❤"
                                        font.pixelSize: root.s(10)
                                        color: "#ff4444"
                                        visible: parent.parent.parent.isHimeno
                                        Layout.alignment: Qt.AlignVCenter
                                        NumberAnimation on scale {
                                            loops: Animation.Infinite
                                            duration: 1000
                                            from: 0.8
                                            to: 1.2
                                            easing.type: Easing.InOutSine
                                        }
                                    } 
                                }
                                Text { 
                                    text: model.desc
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: root.s(10)
                                    color: isHimeno ? Qt.rgba(1, 0.5, 0.5, 0.9) : root.subtext0
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight 
                                }
                            }
                            
                            MouseArea { 
                                id: modMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { 
                                    root.selectedModuleIndex = index; 
                                    modulesList.positionViewAtIndex(index, ListView.Contain); 
                                }
                                onDoubleClicked: { 
                                    root.selectedModuleIndex = index; 
                                    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", model.target]) 
                                } 
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // TAB 3: MATUGEN ENGINE
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 3 ? 1.0 : 0.0
                scale: root.currentTab === 3 ? 1.0 : 0.95
                property real slideY: root.currentTab === 3 ? 0 : root.s(10)
                enabled: root.currentTab === 3
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: root.s(15)
                    anchors.leftMargin: root.s(20)
                    anchors.rightMargin: root.s(20)
                    anchors.bottomMargin: root.s(20)
                    spacing: root.s(20)

                    Text { text: "Theming Engine"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(28); color: root.text; Layout.alignment: Qt.AlignVCenter }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(160)
                        radius: root.s(12)
                        color: Qt.alpha(root.surface0, 0.4)
                        border.color: root.ambientPurple
                        border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.s(20)
                            spacing: root.s(20)
                            
                            Item { Layout.fillWidth: true } 
                            
                            ColumnLayout { 
                                Layout.alignment: Qt.AlignVCenter
                                spacing: root.s(8)
                                Rectangle { 
                                    Layout.alignment: Qt.AlignHCenter
                                    width: root.s(60)
                                    height: root.s(60)
                                    radius: root.s(10)
                                    color: root.surface1
                                    Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(28); color: root.text } 
                                } 
                                Text { text: "Wallpaper"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(12); color: root.text; Layout.alignment: Qt.AlignHCenter } 
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://github.com/eprahemi/WifeRice")
                                }
                            }
                            
                            Item { 
                                Layout.preferredWidth: root.s(60)
                                Layout.preferredHeight: root.s(20)
                                Layout.alignment: Qt.AlignVCenter
                                Repeater { 
                                    model: 3
                                    Item { 
                                        width: parent.width
                                        height: parent.height
                                        Rectangle { 
                                            width: root.s(6)
                                            height: root.s(6)
                                            radius: root.s(3)
                                            color: [root.mauve, root.peach, root.blue][index]
                                            y: parent.height / 2 - root.s(3)
                                            SequentialAnimation on x { 
                                                loops: Animation.Infinite
                                                running: root.currentTab === 3
                                                PauseAnimation { duration: index * 400 }
                                                NumberAnimation { from: 0; to: parent.width; duration: 1200; easing.type: Easing.InOutSine } 
                                            } 
                                            SequentialAnimation on opacity { 
                                                loops: Animation.Infinite
                                                running: root.currentTab === 3
                                                PauseAnimation { duration: index * 400 }
                                                NumberAnimation { from: 0; to: 1; duration: 300 }
                                                PauseAnimation { duration: 600 }
                                                NumberAnimation { from: 1; to: 0; duration: 300 } 
                                            } 
                                        } 
                                    } 
                                } 
                            }
                            
                            Rectangle {
                                width: root.s(180)
                                height: root.s(90)
                                radius: root.s(12)
                                color: root.base
                                border.color: root.ambientPurple
                                Layout.alignment: Qt.AlignVCenter
                                
                                SequentialAnimation on border.width { 
                                    loops: Animation.Infinite
                                    running: root.currentTab === 3
                                    NumberAnimation { from: root.s(1); to: root.s(4); duration: 1000; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: root.s(4); to: root.s(1); duration: 1000; easing.type: Easing.InOutSine } 
                                }
                                
                                ColumnLayout { 
                                    anchors.centerIn: parent
                                    spacing: root.s(8)
                                    Text { text: "Matugen Core"; font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: root.s(15); color: root.ambientPurple; Layout.alignment: Qt.AlignHCenter } 
                                    RowLayout { 
                                        spacing: root.s(4)
                                        Layout.alignment: Qt.AlignHCenter
                                        Repeater { 
                                            model: [root.red, root.peach, root.yellow, root.green, root.blue, root.mauve]
                                            Rectangle { 
                                                Layout.alignment: Qt.AlignVCenter
                                                width: root.s(12)
                                                height: root.s(12)
                                                radius: root.s(6)
                                                color: modelData
                                                SequentialAnimation on scale { 
                                                    loops: Animation.Infinite
                                                    running: root.currentTab === 3
                                                    PauseAnimation { duration: index * 150 }
                                                    NumberAnimation { to: 1.3; duration: 300; easing.type: Easing.OutQuart }
                                                    NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuart }
                                                    PauseAnimation { duration: 1000 } 
                                                } 
                                            } 
                                        } 
                                    } 
                                } 
                            }
                            
                            Item { 
                                Layout.preferredWidth: root.s(60)
                                Layout.preferredHeight: root.s(20)
                                Layout.alignment: Qt.AlignVCenter
                                Repeater { 
                                    model: 3
                                    Item { 
                                        width: parent.width
                                        height: parent.height
                                        Rectangle { 
                                            width: root.s(6)
                                            height: root.s(6)
                                            radius: root.s(3)
                                            color: [root.green, root.yellow, root.pink][index]
                                            y: parent.height / 2 - root.s(3)
                                            SequentialAnimation on x { 
                                                loops: Animation.Infinite
                                                running: root.currentTab === 3
                                                PauseAnimation { duration: index * 400 }
                                                NumberAnimation { from: 0; to: parent.width; duration: 1200; easing.type: Easing.InOutSine } 
                                            } 
                                            SequentialAnimation on opacity { 
                                                loops: Animation.Infinite
                                                running: root.currentTab === 3
                                                PauseAnimation { duration: index * 400 }
                                                NumberAnimation { from: 0; to: 1; duration: 300 }
                                                PauseAnimation { duration: 600 }
                                                NumberAnimation { from: 1; to: 0; duration: 300 } 
                                            } 
                                        } 
                                    } 
                                } 
                            }
                            
                            ColumnLayout { 
                                Layout.alignment: Qt.AlignVCenter
                                spacing: root.s(8)
                                Rectangle { 
                                    Layout.alignment: Qt.AlignHCenter
                                    width: root.s(60)
                                    height: root.s(60)
                                    radius: root.s(10)
                                    color: root.surface1
                                    Text { anchors.centerIn: parent; text: "󰏘"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(28); color: root.text } 
                                } 
                                Text { text: "Templates"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(12); color: root.text; Layout.alignment: Qt.AlignHCenter } 
                            }
                            Item { Layout.fillWidth: true } 
                        }
                    }

                    Text { text: "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:"; font.family: "JetBrains Mono"; font.pixelSize: root.s(13); color: root.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap; Layout.alignment: Qt.AlignVCenter }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 3
                        rowSpacing: root.s(10)
                        columnSpacing: root.s(10)
                        
                        Repeater {
                            model: [ 
                                { f: "kitty-colors.conf", i: "󰄛", c: "yellow" }, 
                                { f: "nvim-colors.lua", i: "", c: "green" }, 
                                { f: "rofi.rasi", i: "", c: "blue" }, 
                                { f: "cava-colors.ini", i: "󰎆", c: "mauve" }, 
                                { f: "sddm-colors.qml", i: "󰍃", c: "peach" }, 
                                { f: "swaync/osd.css", i: "󰂚", c: "pink" } 
                            ]
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.s(45)
                                radius: root.s(8)
                                color: tplMa.containsMouse ? Qt.alpha(root[modelData.c], 0.1) : root.surface0
                                border.color: tplMa.containsMouse ? root[modelData.c] : "transparent"
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                
                                RowLayout { 
                                    anchors.fill: parent
                                    anchors.margins: root.s(10)
                                    spacing: root.s(10)
                                    Item { 
                                        Layout.preferredWidth: root.s(24)
                                        Layout.alignment: Qt.AlignVCenter
                                        Text { anchors.centerIn: parent; text: modelData.i; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root[modelData.c] } 
                                    } 
                                    Text { text: modelData.f; font.family: "JetBrains Mono"; font.weight: Font.Medium; font.pixelSize: root.s(12); color: root.text; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter } 
                                }
                                MouseArea { id: tplMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // TAB 4: TIME SETTINGS
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 4 ? 1.0 : 0.0
                scale: root.currentTab === 4 ? 1.0 : 0.95
                property real slideY: root.currentTab === 4 ? 0 : root.s(10)
                enabled: root.currentTab === 4
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - root.s(32)
                    spacing: root.s(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.s(48)
                        height: root.s(48)
                        radius: root.s(14)
                        color: Qt.alpha(root.peach, 0.15)
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: root.s(26)
                            color: root.peach
                        }
                    }

                    Text {
                        text: "Time Zone"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: root.s(16)
                        color: root.text
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(root.s(360), parent.width)
                        height: root.s(50)
                        radius: root.s(12)
                        color: detectBtn.containsMouse ? Qt.alpha(root.peach, 0.2) : Qt.alpha(root.surface0, 0.4)
                        border.color: detectBtn.containsMouse ? root.peach : root.surface1
                        border.width: detectBtn.containsMouse ? 2 : 1
                        scale: detectBtn.pressed ? 0.95 : (detectBtn.containsMouse ? 1.02 : 1.0)

                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: root.s(10)
                            Text { text: "󰖟"; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(20); color: root.peach }
                            Text { text: "Auto Detect Timezone"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(14); color: root.text }
                            Rectangle {
                                radius: root.s(5)
                                color: Qt.alpha(root.green, 0.15)
                                border.color: Qt.alpha(root.green, 0.4)
                                border.width: 1
                                implicitHeight: root.s(18)
                                implicitWidth: recTxt.implicitWidth + root.s(8)
                                Text {
                                    id: recTxt
                                    anchors.centerIn: parent
                                    text: "Recommended"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: root.s(8)
                                    color: root.green
                                }
                            }

                        }

                        MouseArea {
                            id: detectBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["kitty", "bash", "-c", "TZ=$(curl -s --max-time 5 https://ipapi.co/timezone 2>/dev/null || curl -s --max-time 5 http://ip-api.com/json 2>/dev/null | grep -oP '\\\"timezone\\\":\\\"\\K[^\\\"]+'); if [ -n \"$TZ\" ]; then echo \"Detected: $TZ\"; sudo timedatectl set-timezone \"$TZ\" && echo \"Timezone set to $TZ\"; else echo \"Could not detect timezone.\"; fi; echo; read -p 'Press Enter to close...' "])
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(root.s(320), parent.width)
                        height: 1
                        color: Qt.alpha(root.surface1, 0.3)
                    }

                    Item {
                        id: chipContainer
                        width: parent.width
                        height: root.s(280)
                        opacity: 1.0

                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Timer {
                            id: continentFadeTimer
                            interval: 150
                            property int targetIndex: 0
                            onTriggered: {
                                root.selectedContinent = targetIndex;
                                chipContainer.opacity = 1.0;
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: root.s(6)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: root.s(3)

                                Repeater {
                                    model: root.continentData

                                    Rectangle {
                                        id: pill
                                        property var cont: modelData
                                        property bool isActive: index === root.selectedContinent
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: root.s(26)
                                        radius: root.s(6)
                                        color: isActive ? Qt.alpha(cont.color, 0.25) : Qt.alpha(root.surface0, 0.2)
                                        border.color: isActive ? cont.color : "transparent"
                                        border.width: isActive ? 1 : 0
                                        scale: pillMa.pressed ? 0.95 : 1.0

                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        Behavior on border.color { ColorAnimation { duration: 200 } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: root.s(3)
                                            Text {
                                                text: cont.icon
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: root.s(11)
                                                color: isActive ? cont.color : root.subtext0
                                            }
                                            Text {
                                                text: cont.region
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: root.s(11)
                                                color: isActive ? cont.color : root.subtext0
                                            }
                                        }

                                        MouseArea {
                                            id: pillMa
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
    if (index !== root.selectedContinent) {
        chipContainer.opacity = 0.0;
        continentFadeTimer.targetIndex = index;
        continentFadeTimer.restart();
    }
}
                                        }
                                    }
                                }
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: zoneFlow.height
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Flow {
                                    id: zoneFlow
                                    width: parent.width
                                    spacing: root.s(6)

                                    Repeater {
                                        model: root.continentData[root.selectedContinent].zones

                                        Rectangle {
                                            height: root.s(30)
                                            width: txt.implicitWidth + root.s(16)
                                            radius: root.s(5)
                                            property bool zoneHovered: false
                                            color: zoneHovered ? Qt.alpha(root.continentData[root.selectedContinent].color, 0.2) : Qt.alpha(root.surface0, 0.25)
                                            border.color: zoneHovered ? root.continentData[root.selectedContinent].color : "transparent"
                                            border.width: zoneHovered ? 1 : 0
                                            scale: zoneMa.pressed ? 0.95 : (zoneHovered ? 1.02 : 1.0)

                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                            Behavior on color { ColorAnimation { duration: 120 } }

                                            Text {
                                                id: txt
                                                anchors.centerIn: parent
                                                text: modelData.disp
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: root.s(12)
                                                color: parent.zoneHovered ? root.continentData[root.selectedContinent].color : root.subtext0
                                            }
                                            MouseArea {
                                                id: zoneMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onEntered: parent.zoneHovered = true
                                                onExited: parent.zoneHovered = false
                                                onClicked: Quickshell.execDetached(["kitty", "bash", "-c", "TZ=\"" + modelData.zone + "\"; sudo timedatectl set-timezone \"$TZ\" && echo \"Timezone set to $TZ\"; read -p 'Press Enter to close...' "])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // TAB 5: ABOUT
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 5 ? 1.0 : 0.0
                scale: root.currentTab === 5 ? 1.0 : 0.95
                property real slideY: root.currentTab === 5 ? 0 : root.s(10)
                enabled: root.currentTab === 5
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: root.s(24)

                    // ─── LINK CARDS ────────────────────────────────────
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: root.s(30)

                        Repeater {
                            model: [
                                { name: "GitHub", icon: "", color: "blue", url: "https://github.com/eprahemi" },
                                { name: "Eprahemi", icon: "󰣇", color: "mauve", url: "https://github.com/eprahemi/WifeRice" },
                                { name: "Wallpapers", icon: "", color: "peach", url: "https://wallvault.pages.dev/" }
                            ]

                            Rectangle {
                                Layout.preferredWidth: root.s(140)
                                Layout.preferredHeight: root.s(140)
                                radius: root.s(16)
                                color: repoMa.containsMouse ? Qt.alpha(root[modelData.color], 0.15) : Qt.alpha(root.surface0, 0.4)
                                border.color: repoMa.containsMouse ? root[modelData.color] : root.surface1
                                border.width: 1
                                scale: repoMa.pressed ? 0.95 : (repoMa.containsMouse ? 1.05 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: root.s(15)

                                    Text {
                                        text: modelData.icon
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: root.s(42)
                                        color: root[modelData.color]
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: root.s(13)
                                        color: root.text
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: repoMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["xdg-open", modelData.url])
                                }
                            }
                        }
                    }

                    // ─── DIVIDER ───────────────────────────────────────
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.s(240)
                        Layout.preferredHeight: 1
                        color: Qt.alpha(root.text, 0.08)
                    }

                    // ─── VERSION DISPLAY ───────────────────────────────
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: root.s(8)

                        Image {
                            source: "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/guide/makima_icon.svg"
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Version"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Medium
                            font.pixelSize: root.s(12)
                            color: root.subtext0
                        }

                        Text {
                            text: root.dotsVersion !== "Loading..." ? root.dotsVersion + (root.dotsVersionName !== "" ? " " + root.dotsVersionName : "") : "..."
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: root.s(12)
                            color: root.text
                        }
                    }

                }

                // ─── COPYRIGHT ────────────────────────
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.s(14)
                    width: copyRow2.width
                    height: copyRow2.height

                    Row {
                        id: copyRow2
                        spacing: root.s(1)
                        Text {
                            text: "© "
                            font.family: "JetBrains Mono"
                            font.pixelSize: root.s(13)
                            color: Qt.alpha(root.subtext0, 0.4)
                        }
                        Repeater {
                            model: [ { l: "e", c: root.red }, { l: "p", c: root.peach }, { l: "r", c: root.yellow }, { l: "a", c: root.green }, { l: "h", c: root.sapphire }, { l: "e", c: root.blue }, { l: "m", c: root.mauve }, { l: "i", c: root.pink } ]
                            Text {
                                text: modelData.l
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: root.s(13)
                                color: modelData.c
                                property real hoverOffset: copyMa2.containsMouse ? root.s(-4) : 0
                                transform: Translate { y: hoverOffset }
                                Behavior on hoverOffset { NumberAnimation { duration: 300 + (index * 40); easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    MouseArea {
                        id: copyMa2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/eprahemi"])
                    }
                }
            }

            // ------------------------------------------
            // TAB 6: UPDATES & CHANGELOG
            // ------------------------------------------
            Item {
                anchors.fill: parent
                opacity: root.currentTab === 6 ? 1.0 : 0.0
                scale: root.currentTab === 6 ? 1.0 : 0.95
                property real slideY: root.currentTab === 6 ? 0 : root.s(10)
                enabled: root.currentTab === 6
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on slideY { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: root.s(15)
                    anchors.leftMargin: root.s(20)
                    anchors.rightMargin: root.s(20)
                    anchors.bottomMargin: root.s(20)
                    spacing: root.s(20)

                    // ─── HEADER ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.s(15)

                        Rectangle {
                            Layout.preferredWidth: root.s(48)
                            Layout.preferredHeight: root.s(48)
                            radius: root.s(12)
                            color: Qt.alpha(root.green, 0.15)
                            Text {
                                anchors.centerIn: parent
                                text: "󰑖"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: root.s(24)
                                color: root.green
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: root.s(4)
                            Text {
                                text: "Updates & Changelog"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: root.s(28)
                                color: root.text
                            }
                            Text {
                                text: "Track what's new in your dotfiles"
                                font.family: "JetBrains Mono"
                                font.pixelSize: root.s(13)
                                color: root.subtext0
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: root.s(140)
                            Layout.preferredHeight: root.s(44)
                            radius: root.s(22)
                            color: checkMa.containsMouse ? Qt.alpha(root.green, 0.9) : Qt.alpha(root.green, 0.7)
                            border.color: root.green
                            border.width: 1
                            scale: checkMa.pressed ? 0.95 : (checkMa.containsMouse ? 1.05 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: root.s(8)
                                Text {
                                    text: root.checkingUpdates ? "󰑮" : ""
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: root.s(20)
                                    color: root.base
                                    RotationAnimation on rotation {
                                        from: 0; to: 360
                                        duration: 1500; loops: Animation.Infinite
                                        running: root.checkingUpdates
                                    }
                                }
                                Text {
                                    text: root.checkingUpdates ? "CHECKING" : "CHECK"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: root.s(14)
                                    color: root.base
                                }
                            }

                            MouseArea {
                                id: checkMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.checkingUpdates) {
                                        root.checkingUpdates = true;
                                        root.updateStatusText = "Checking...";
                                        root.updateStatusIcon = "󰑮";
                                        root.updateStatusColor = root.subtext0;
                                        updateChecker.running = true;
                                    }
                                }
                            }
                        }
                    }

                    // ─── VERSION DISPLAY ───────────────────────────────
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: versionRow.implicitWidth
                        implicitHeight: versionRow.implicitHeight
                        scale: versionRowMa.containsMouse ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: versionRow
                            anchors.centerIn: parent
                            spacing: root.s(8)

                            Image {
                                source: "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/guide/himeno.svg"
                                fillMode: Image.PreserveAspectFit
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Version"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Medium
                                font.pixelSize: root.s(12)
                                color: root.subtext0
                            }

                            Text {
                                text: root.dotsVersion !== "Loading..." ? root.dotsVersion + (root.dotsVersionName !== "" ? " " + root.dotsVersionName : "") : "..."
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(12)
                                color: root.text
                            }
                        }

                        MouseArea {
                            id: versionRowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // ─── UPDATE STATUS ────────────────────────────────
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: updateStatusRow.implicitWidth
                        implicitHeight: updateStatusRow.implicitHeight
                        visible: root.updateStatusText !== "Click CHECK"
                        scale: 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                        RowLayout {
                            id: updateStatusRow
                            anchors.centerIn: parent
                            spacing: root.s(6)

                            Text {
                                text: root.updateStatusIcon
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: root.s(14)
                                color: root.updateStatusColor
                            }

                            Text {
                                text: root.updateStatusText
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(13)
                                color: root.updateStatusColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.updateStatusText.includes("available") ? Qt.PointingHandCursor : Qt.ArrowCursor
                            hoverEnabled: true
                            onEntered: if (root.updateStatusText.includes("available")) parent.scale = 1.08
                            onExited: parent.scale = 1.0
                            onClicked: {
                                if (root.updateStatusText.includes("available")) {
                                    let url = "https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh";
                                    let cmd = "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c \"$(curl -fsSL " + url + ")\"; else bash -c \"$(curl -fsSL " + url + ")\"; fi";
                                    Quickshell.execDetached(["bash", "-c", cmd]);
                                }
                            }
                        }
                    }

                    // ─── DIVIDER ────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.alpha(root.surface1, 0.3)
                        Layout.topMargin: root.s(8)
                        Layout.bottomMargin: root.s(8)
                    }

                    // ─── CHANGELOG SECTION ─────────────────────────────
                    Text {
                        text: "Recent Changes"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: root.s(18)
                        color: root.text
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: root.s(6)

                        model: ListModel {
                            ListElement { version: "v1.7.18"; title: "Fix Thunar Thumbnails"; desc: "Fixed RAW/ODF/EPUB tumbler plugins, clears thumbnail cache on restore"; icon: "󰋼"; clr: "blue"; detail: "Fixed Thunar thumbnails for users who couldn't see image or video previews. Fix 1: Replaced broken 'raw-thumbnailer' AUR package in install.sh with 'libopenraw' from official repos — tumbler's raw thumbnailer plugin needs libopenrawgnome.so.9 to load. Fix 2: Added 'libgepub' to THUMB_PKGS for EPUB document thumbnails. Fix 3: 'raw-thumbnailer' was an AUR-only package that silently failed to install via pacman — now removed. Fix 4: Added tumblerd restart and ~/.cache/thumbnails clearing to restore.sh so restored users get working thumbnails immediately. Fix 5: All users should run 'sudo pacman -S libgsf libopenraw libgepub && rm -rf ~/.cache/thumbnails && systemctl --user restart tumblerd' to fix existing installations." }
                            ListElement { version: "v1.7.17"; title: "Fix Battery Sound in Quickshell"; desc: "battery_fetch.sh now uses pw-play/paplay + nohup so audio always plays"; icon: "󰁹"; clr: "green"; detail: "Low battery notifications (20%/10%/5%/3%) now play audio reliably for all users. Fix 1: Added pw-play and paplay as primary audio players — mpg123/ffplay fail silently when spawned from Quickshell's Process sandbox. Fix 2: Added nohup + explicit /dev/null redirect to fully detach audio playback from the shell process tree, preventing any SIGHUP from killing the sound. All users already have pipewire-pulse installed, so this is zero-dependency." }
                            ListElement { version: "v1.7.16"; title: "Cleanup Stale References"; desc: "Removes old imperative-dots-version file on update"; icon: "󰛖"; clr: "mauve"; detail: "Removes stale ~/.local/state/imperative-dots-version file if present. No functional changes." }
                            ListElement { version: "v1.7.15"; title: "3% Critical Countdown"; desc: "30s countdown + auto-suspend in real-time battery monitor"; icon: "󰁹"; clr: "red"; detail: "Added the 3% critical threshold with 30-second countdown, sound every 3s, color-changing urgency, charger-detect escape hatch, and auto-suspend at 0 to battery_fetch.sh — fires instantly on udev events, not waiting for the 6-hour bat-monitor timer." }
                            ListElement { version: "v1.7.14"; title: "Real-Time Battery Sounds"; desc: "Battery alerts now play sounds instantly (udev-triggered), mpg123 installed"; icon: "󰁹"; clr: "green"; detail: "Low battery notifications (20%/10%/5%) now play sounds immediately via battery_fetch.sh, which runs on every udev power supply change — no more waiting for the 6-hour bat-monitor timer. Added mpg123 package for lightweight MP3 playback. Fixed bash syntax error in battery_fetch.sh." }
                            ListElement { version: "v1.7.8"; title: "Wallpaper Preservation"; desc: "SDDM theme always updates, user wallpaper never overwritten"; icon: "󰋼"; clr: "green"; detail: "SDDM theme files (Main.qml, Colors.qml, etc.) are always updated on reinstall, but the user's login wallpaper — regardless of filename — is never overwritten. Only deploys default wallpaper if no image exists in the theme directory." }
                            ListElement { version: "v1.7.7"; title: "Bug Fix Batch"; desc: "24 audit bugs squashed — hardcoded paths, wrong URLs, broken scripts, PulseAudio refs, and more"; icon: "󰛕"; clr: "green"; detail: "Comprehensive bug fix release. Fixed hardcoded /home/eprahemi/ paths in env.conf. Restored missing journald-cleanup script deployment. Updated updates.json to current version. Fixed restore.sh writing stale version 1.5.4. Fixed UpdaterPopup.qml GitHub API calls using master instead of main. Replaced deprecated qs binary with quickshell across reload.sh and Config.qml. Added .zshrc overwrite guard in install.sh and restore.sh. Fixed lock screen wallpaper check using -d instead of -f. Added self-delete guard for .hyprland-dots. Fixed step numbering consistency. Fixed broken LOCAL_VERSION parsing in update_notifier.sh. Fixed weather.sh path in settings_watcher.sh. Fixed unexpanded tilde in matugen_reload.sh. Replaced pulseaudio references with PipeWire. Updated wiferice-wallpapers URLs to WifeRice. Renamed misleading base64 variable. Added settings_watcher compile and thumbnail cache clear to restore.sh. Added env.conf to .gitignore. Consistent CURRENT_USER variable usage." }
                            ListElement { version: "v1.7.6"; title: "Security Patch Batch"; desc: "Patched privilege escalation in IPC sockets, hardened env sanitization, fixed unsafe temp file creation, removed deprecated sudoers fallback, batched dbus security hardening"; icon: "󰒃"; clr: "red"; detail: "Security Patch Batch. Patched privilege escalation vector in QS IPC socket permissions. Hardened shell environment variable sanitization across all scripts. Fixed unsafe temporary file creation (CWE-377) in installer routines. Removed deprecated sudoers fallback that bypassed authentication checks. Batched security hardening for dbus activation policies. Mitigated XDG autostart injection path. Strengthened filesystem permission isolation for runtime directories. Fixed black screen on update by removing systemd-logind restart during install. Power button tap now locks screen, long press shuts down." }
                            ListElement { version: "v1.7.5"; title: "Battery Alerts, Auth Fixes, Volume Control"; desc: "4-stage battery alerts with per-level sounds, PAM fix, power button suspend, 4% volume step with hold-repeat"; icon: "󰁹"; clr: "red"; detail: "v1.7.5 release. New 4-stage low battery alert system: 20% lowbattery20-10.mp3 + normal notification, 10% same sound + critical notification, 5% lowbattery5.mp3 + critical notification, 3% 30s countdown with color-changing urgency every 10s + lowbattery5.mp3 every 3s. Countdown stops if charger plugged in — suspends at 0 if still discharging. Per-threshold sound support. Fixed false wrong-password errors (disabled pam_systemd_home.so). Power button tap = suspend, long press = poweroff. New volume script with 4% step and hold-repeat support." }
                            ListElement { version: "v1.5.7"; title: "NVIDIA Optimus Fix & Proton VPN"; desc: "Fixed dGPU always-on overheating, added Proton VPN installer, system-wide smoothness"; icon: "󰢮"; clr: "blue"; detail: "v1.5.7 release. CRITICAL NVIDIA Optimus fix: removed global __NV_PRIME_RENDER_OFFLOAD from env.conf that kept the dGPU always active — now the Intel iGPU handles desktop, Discord, and browsers by default, while the NVIDIA RTX GPU only activates on demand via prime-run for gaming. This fixes overheating, battery drain, and system lag on all Optimus laptops (MSI Thin, etc.). Added Proton VPN CLI and GTK app to the installer. Discord hardware acceleration should be disabled in Discord Settings > Advanced for best performance." }
                            ListElement { version: "v1.5.6"; title: "Timezone Picker & Fade Transitions"; desc: "Continent pills, country chips, auto-detect with badge, fade morphing"; icon: ""; clr: "peach"; detail: "v1.5.6 release. New Timezone tab with interactive continent pills and alphabetically-sorted country chips. Auto-detect timezone button with green Recommended badge. Smooth fade transitions when switching continents. Left/right arrow keyboard navigation for continent cycling. Fixed brace balance issue that broke the guide popup. Increased font sizes for readability. Vertically centered layout. Icon and button sizes improved. Added recommended badge to auto-detect button. Full morph animation on continent switch." }
                            ListElement { version: "v1.5.4"; title: "Emergency Fix Release"; desc: "Timezone removed, Thunar optional, audio/thumbnail/NVIDIA fixes"; icon: "󰑖"; clr: "red"; detail: "Emergency v1.5.4 release. Removed timezone geo-location API checker that could change system time based on VPN location. Removed forced Thunar install — file manager keybinding now uses xdg-open. Fixed audio driver being broken after update by ensuring pipewire/wireplumber user services are enabled. Fixed thumbnails not showing by enabling tumblerd user service post-install. Fixed NVIDIA Optimus laptop overheating and 0% battery by configuring nvidia.NVreg_DynamicPowerManagement=0x02, enabling nvidia-suspend/hibernate/resume services, and installing nvidia-prime for PRIME render offload. Preserved user lock screen/login screen/face icon customizations — never overwrites existing wallpapers, SDDM theme QML files, or profile pictures." }
                            ListElement { version: "v1.5.3"; title: "Stable Release"; desc: "Finalized notifications, icon fixes, video cleanup"; icon: "󰂚"; clr: "green"; detail: "Stable v1.5.3 release. All notification features finalized: glassmorphism popups, smart keyword-mapped icons, smooth height-collapse transitions, battery icon fix for notify-send, Himeno video stops on guide close/focus loss, and full changelog history." }
                            ListElement { version: "v1.5.1"; title: "Premium Notifications"; desc: "Glassmorphism, icons, smooth transitions"; icon: "󰂚"; clr: "mauve"; detail: "Complete notification popup redesign: glassmorphism cards with animated ambient orbs, smart keyword-mapped nerd font icons for every app type, left accent bar with glow intensity, smooth height-collapse remove transitions with no glitching, hover-reveal dismiss button, auto-dismiss countdown progress bar, and refined add/remove animations with spring easing." }
                            ListElement { version: "v1.5.0"; title: "Himeno Edition Release"; desc: "Stable release — video, animations, polish"; icon: "󰎁"; clr: "red"; detail: "Official v1.5.0 Himeno Edition release. All features finalized: Himeno Sexy Scene module with video playback, liquid morphing tab transitions, pulsing red card styling with heart indicator, white tint hover effects across all interactive elements, sidebar tab hover scale, fixes for hover state persistence on click, and full changelog history." }
                            ListElement { version: "v1.4.9"; title: "Himeno Edition"; desc: "Himeno video, red styling, liquid morphing"; icon: "󰎁"; clr: "red"; detail: "New Himeno Sexy Scene module with inline video playback via QtMultimedia. Red-themed card styling with pulsing border, heart icon, and outer glow. Full liquid morphing animations on all tabs (scale + opacity + slide). Smooth hover transitions on all interactive elements. Settings/Modules nav buttons and system cards now have white tint hover + border glow. Sidebar tabs scale up on hover with OutBack easing." }
                            ListElement { version: "v1.4.8"; title: "Settings Slide Fix"; desc: "150ms delay, smoother slide, weather auto-refresh"; icon: "󰑐"; clr: "blue"; detail: "Top bar elements now wait 150ms before sliding when settings opens — no more empty gap before popup appears. Weather refreshes instantly after saving API key/city. Reduced slide distance to 70% for perfect fit." }
                            ListElement { version: "v1.4.7"; title: "Preview Initialization"; desc: "Fixed preview not showing on first load"; icon: "󰋼"; clr: "mauve"; detail: "Fixed GuidePopup preview container not initializing on first open. onTargetSourceChanged now calls refreshPreview() function. Component.onCompleted triggers initial preview setup. Brace balance verified at 504/504." }
                            ListElement { version: "v1.4.6"; title: "Clickable Update Status"; desc: "Hover & click to update, smoother animations"; icon: "󰚰"; clr: "peach"; detail: "Update status text is now clickable — hover for smooth scale animation, click to open terminal and run the installer. Bottom 'update' button also improved with hover effects and redirects to terminal." }
                            ListElement { version: "v1.4.5"; title: "Rebrand to WifeRice"; desc: "Capital R, cleaner identity, all URLs updated"; icon: "󰜥"; clr: "mauve"; detail: "GitHub repo renamed to eprahemi/WifeRice with capital R. All references updated across guide, updater, installer, and README." }
                            ListElement { version: "v1.4.4"; title: "GuidePopup Overhaul"; desc: "Updates tab, makima icon, keyboard nav, glow arc"; icon: "󰅟"; clr: "mauve"; detail: "New Updates tab with version checker and changelog. Makima icon in About tab. Keyboard navigation with up/down arrows to switch tabs. Rotating glow border around avatar. Hover scale effects on version row. Clickable wallpaper link. Arch logo in System tab." }
                            ListElement { version: "v1.4.3"; title: "WiFi & Volume Refined"; desc: "Fixed WiFi/BT popup, refined volume orb"; icon: "󰕾"; clr: "blue"; detail: "Fixed WiFi and Bluetooth popup display issues. Refined volume orb with smoother drag interaction and instant mute text feedback." }
                            ListElement { version: "v1.4.2"; title: "Hero Orb Volume Fixes"; desc: "Smooth drag, no glitch, instant mute text"; icon: "󰓃"; clr: "peach"; detail: "Replaced Behavior on transform with animated property for volume orb. Removed visible binding glitch. Instant mute/unmute text display on tap." }
                            ListElement { version: "v1.4.1"; title: "Cleanup & Rebase"; desc: "Single default wallpaper, branding update"; icon: "󰛖"; clr: "green"; detail: "Cleaned up wallpaper handling to use a single default wallpaper. Rebranded to Eprahemi with professional ASCII art banner in installer." }
                            ListElement { version: "v1.4.0"; title: "WiFi Password Counter"; desc: "Character counter, smoother orb drag"; icon: "󰤨"; clr: "yellow"; detail: "Added WiFi password character counter in corner of input field. Smoother orb drag sensitivity across all modules." }
                            ListElement { version: "v1.3.9"; title: "Hero Orb Drag Control"; desc: "Drag up/down for volume, tap to mute"; icon: "󰝝"; clr: "pink"; detail: "Volume control via Hero Orb — drag up/down to adjust volume, tap to toggle mute. Haptic-style visual feedback on interaction." }
                            ListElement { version: "v1.3.8"; title: "Low Battery Warnings"; desc: "Alerts at 20%, 10%, 5%"; icon: "󰁹"; clr: "red"; detail: "Added low battery warning notifications at 20%, 10%, and 5% thresholds with distinct visual urgency levels." }
                        }

                        delegate: Rectangle {
                            id: chgDelegate
                            width: ListView.view.width
                            height: root.s(52)
                            radius: root.s(8)
                            color: chMa.containsMouse ? Qt.alpha(root[model.clr], 0.08) : Qt.alpha(root.surface0, 0.3)
                            border.color: chMa.containsMouse ? Qt.alpha(root[model.clr], 0.3) : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: root.s(10)
                                spacing: root.s(12)

                                Rectangle {
                                    Layout.preferredWidth: root.s(28)
                                    Layout.preferredHeight: root.s(28)
                                    radius: root.s(6)
                                    color: Qt.alpha(root.base, 0.3)
                                    Text { anchors.centerIn: parent; text: model.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: root[model.clr] }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: root.s(2)
                                    RowLayout {
                                        spacing: root.s(8)
                                        Text { text: model.version; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(12); color: root[model.clr] }
                                        Text { text: model.title; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: root.s(12); color: root.text }
                                        Item { Layout.fillWidth: true }
                                    }
                                    Text { text: model.desc; font.family: "JetBrains Mono"; font.pixelSize: root.s(11); color: root.subtext0 }
                                }
                            }

                            MouseArea {
                                id: chMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.showHint(model.detail, this)
                                onExited: root.hideHint()
                            }
                        }
                    }

                    // ─── UPDATE INSTRUCTIONS ───────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(50)
                        radius: root.s(10)
                        color: Qt.alpha(root.surface0, 0.4)
                        border.color: root.surface1
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.s(12)
                            spacing: root.s(10)

                            Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(16); color: root.subtext0 }

                            Text {
                                text: "Run "
                                font.family: "JetBrains Mono"
                                font.pixelSize: root.s(12)
                                color: root.subtext0
                            }

                            Rectangle {
                                Layout.preferredHeight: root.s(26)
                                Layout.preferredWidth: cmdText.implicitWidth + root.s(16)
                                radius: root.s(4)
                                color: updateBtnMa.containsMouse ? Qt.alpha(root.green, 0.15) : root.base
                                border.color: updateBtnMa.containsMouse ? Qt.alpha(root.green, 0.4) : root.surface2
                                border.width: 1
                                scale: updateBtnMa.containsMouse ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    id: cmdText
                                    anchors.centerIn: parent
                                    text: "update"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: root.s(11)
                                    color: root.green
                                }

                                MouseArea {
                                    id: updateBtnMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        let url = "https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh";
                                        let cmd = "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c \"$(curl -fsSL " + url + ")\"; else bash -c \"$(curl -fsSL " + url + ")\"; fi";
                                        Quickshell.execDetached(["bash", "-c", cmd]);
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: root.s(28)
                                Layout.preferredHeight: root.s(28)
                                radius: root.s(6)
                                color: cpMa.containsMouse ? root.surface1 : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: cpMa.containsMouse ? root.mauve : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                                MouseArea {
                                    id: cpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["bash", "-c", "echo update | wl-copy"])
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: root.s(28)
                                Layout.preferredHeight: root.s(28)
                                radius: root.s(6)
                                color: docMa.containsMouse ? root.surface1 : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14); color: docMa.containsMouse ? root.green : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                                MouseArea {
                                    id: docMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/eprahemi/WifeRice/releases"])
                                }
                            }
                        }
                    }
                }
            }

        }
    }
}
