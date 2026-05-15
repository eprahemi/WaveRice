import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import QtCore
import Qt.labs.folderlistmodel
import QtMultimedia
import Quickshell
import Quickshell.Io
import "../" 

Item {
    id: window
    width: Screen.width

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    MatugenColors { id: _theme }

    property string widgetArg: ""
    property string targetWallName: ""
    property bool initialFocusSet: false
    property int visibleItemCount: -1
    property int scrollAccum: 0
    property real scrollThreshold: window.s(300)

    property string currentFilter: "All"
    property string _lastFilter: "All"
    property var colorMap: ({})
    property int cacheVersion: 0 
    
    property bool isApplying: false
    property bool isMonitorSelectorOpen: false
    property bool showApplyPulse: false
    property real mouseX: 0
    property real mouseY: 0
    Timer {
        id: applyUnlockTimer
        interval: 250
        onTriggered: window.isApplying = false
    }
    
    Timer {
        id: applyPulseTimer
        interval: 800
        onTriggered: window.showApplyPulse = false
    }
    
    property bool isStartup: localFolderModel.status === FolderListModel.Loading || srcModel.status === FolderListModel.Loading
    property bool isReady: visible && localFolderModel.status === FolderListModel.Ready
    
    property bool isModelChanging: false
    
    property bool isScrollingBlocked: false
    property bool jumpToLastOnFilterChange: false
    property bool overshootBounce: false
    
    property string activeWallName: (view.currentIndex >= 0 && activeModel && activeModel.count > 0) ? window.getCleanName(activeModel.get(view.currentIndex).fileName || "") : ""
    property string activeWallFileUrl: (view.currentIndex >= 0 && activeModel && activeModel.count > 0) ? activeModel.get(view.currentIndex).fileUrl : ""
    property string activeWallHex: window.colorMap[activeWallName] || "#888888"
    
    property var colorPalette: {
        let hex = window.activeWallHex;
        hex = String(hex).trim().replace(/#/g, '');
        if (hex.length !== 6) hex = "888888";
        let r = parseInt(hex.substring(0,2), 16) / 255;
        let g = parseInt(hex.substring(2,4), 16) / 255;
        let b = parseInt(hex.substring(4,6), 16) / 255;
        return [
            { color: "#" + hex, offset: 0 },
            { color: Qt.rgba(r * 0.7, g * 0.85, b * 0.6, 1), offset: 1 },
            { color: Qt.rgba(r * 0.5, g * 0.5, b * 0.9, 1), offset: 2 },
            { color: Qt.rgba(r * 0.3, g * 0.3, b * 0.3, 1), offset: 3 }
        ];
    }

    readonly property var filterData: [
        { name: "All", hex: "", label: "All" },
        { name: "Video", hex: "", label: "Vid" },
        { name: "Red", hex: "#FF4500", label: "" },
        { name: "Orange", hex: "#FFA500", label: "" },
        { name: "Yellow", hex: "#FFD700", label: "" },
        { name: "Green", hex: "#32CD32", label: "" },
        { name: "Blue", hex: "#1E90FF", label: "" },
        { name: "Purple", hex: "#8A2BE2", label: "" },
        { name: "Pink", hex: "#FF69B4", label: "" },
        { name: "Monochrome", hex: "#A9A9A9", label: "" }
    ]

    ListModel { id: monitorModel }

    Process {
        id: monitorProc
        command: ["sh", "-c", "export PATH=$PATH:/usr/bin:/usr/local/bin:/run/current-system/sw/bin && hyprctl monitors -j"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                let response = this.text; 
                if (response && response.trim().length > 0) {
                    try {
                        var monitors = JSON.parse(response);
                        monitorModel.clear();
                        for (var i = 0; i < monitors.length; i++) {
                            monitorModel.append({ "name": monitors[i].name, "selected": true });
                        }
                    } catch(e) { console.log("[MonitorSync] ERROR parsing JSON: " + e); }
                }
            }
        }
    }

    function loadMonitors() { monitorProc.running = true; }

    function getMonitorOutputs() {
        if (monitorModel.count <= 1) return "all"; 
        let selected = [];
        for (let i = 0; i < monitorModel.count; i++) {
            if (monitorModel.get(i).selected) selected.push(monitorModel.get(i).name);
        }
        if (selected.length === 0) return "none";
        if (selected.length === monitorModel.count) return "all";
        return selected.join(",");
    }

    function applyWallpaper(safeFileName, isVideo) {
        if (!safeFileName || window.isApplying) return;
        let outputs = window.getMonitorOutputs();
        if (outputs === "none") return;
        
        window.isApplying = true;
        window.showApplyPulse = true;
        applyUnlockTimer.restart();
        applyPulseTimer.restart();
        
        window.targetWallName = safeFileName;
        let cleanName = window.getCleanName(safeFileName);
        let reloadScript = Qt.resolvedUrl("matugen_reload.sh").toString();
        if (reloadScript.startsWith("file://")) reloadScript = decodeURIComponent(reloadScript.substring(7));

        const escapeBash = (str) => String(str).replace(/(["\\$`])/g, '\\$1');
        const randomTransition = window.transitions[Math.floor(Math.random() * window.transitions.length)];
        const escOutputs = escapeBash(outputs);
        const logFile = "/tmp/qs_awww_debug.log";
        
        const originalFile = window.srcDir + "/" + cleanName;
        const thumbFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/thumbs/" + safeFileName;
        const escOriginal = escapeBash(originalFile);
        const escThumb = escapeBash(thumbFile);
        const escReload = escapeBash(reloadScript);

        let wallpaperCmd = "";
        if (isVideo) {
            wallpaperCmd = `
                echo "" >> ${logFile}
                echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL VIDEO: ${escOriginal} TO ${escOutputs}" >> ${logFile}
                if [ "${escOutputs}" = "all" ]; then
                    mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' "${escOriginal}" >> ${logFile} 2>&1 &
                else
                    IFS=',' read -ra MON_ARR <<< "${escOutputs}"
                    for mon in "\${MON_ARR[@]}"; do
                        mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' "\$mon" "${escOriginal}" >> ${logFile} 2>&1 &
                    done
                fi
            `;
        } else {
            wallpaperCmd = `
                echo "" >> ${logFile}
                echo "[$(date +'%H:%M:%S.%3N')] APPLYING LOCAL IMAGE: ${escOriginal} TO ${escOutputs}" >> ${logFile}
                if [ "${escOutputs}" = "all" ]; then
                    awww img "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
                else
                    awww img -o "${escOutputs}" "${escOriginal}" --transition-type ${randomTransition} --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 1 >> ${logFile} 2>&1 &
                fi
            `;
        }

        const fullScript = `
            cp "${isVideo ? escThumb : escOriginal}" ${Quickshell.env("HOME")}/.cache/current_wallpaper.png || true
            pkill mpvpaper || true
            ${wallpaperCmd}
            ( matugen image "${escThumb}" --source-color-index 0 || true; bash "${escReload}" || true ) &
        `;
        Quickshell.execDetached(["bash", "-c", fullScript]);
    }
    
    onVisibleChanged: {
        if (!visible) {
            window.initialFocusSet = false;
            window.isApplying = false;
            window.isMonitorSelectorOpen = false;
        } else {
            window.isFilterAnimating = true;
            filterAnimationTimer.restart();
            window.applyFilters(true);
        }
    }

    property bool isLoading: localFolderModel.status === FolderListModel.Loading || 
                             srcModel.status === FolderListModel.Loading

    property bool showSpinner: window.isLoading

    property string currentNotification: {
        if (isLoading) return "Generating thumbnails...";
        if (window.visibleItemCount === 0) return "No wallpapers found";
        if (window.currentFilter === "All") return "";
        if (window.currentFilter === "Video") return "Videos";
        return window.currentFilter;
    }
    
    property bool showNotification: !window.isStartup && currentNotification !== ""

    function getCleanName(name) {
        if (!name) return "";
        let clean = String(name);
        return clean.startsWith("000_") ? clean.substring(4) : clean;
    }

    onWidgetArgChanged: {
        if (widgetArg !== "") {
            targetWallName = widgetArg;
            initialFocusSet = false;
            tryFocus();
        }
    }

    function executeFocusRestore(targetIndex, requirePositioning) {
        let targetModel = localProxyModel;
        if (targetIndex !== -1 && targetIndex < targetModel.count) {
            window.isModelChanging = true;
            if (requirePositioning) {
                view.forceLayout();
                view.positionViewAtIndex(targetIndex, ListView.Center);
            }
            view.currentIndex = targetIndex;
            window.isModelChanging = false;
            window.initialFocusSet = true;
        }
    }

    function tryFocus() {
        if (initialFocusSet) return;
        if (localProxyModel.count > 0) {
            let foundIndex = -1;
            let cleanTarget = window.getCleanName(targetWallName);
            if (cleanTarget !== "") {
                for (let i = 0; i < localProxyModel.count; i++) {
                    let fname = localProxyModel.get(i).fileName || "";
                    if (window.getCleanName(fname) === cleanTarget) {
                        foundIndex = i;
                        break;
                    }
                }
            }
            let finalIndex = foundIndex !== -1 ? foundIndex : 0;
            window.executeFocusRestore(finalIndex, true);
        }
    }

    function getModelForFilter(filter) {
        return localProxyModel;
    }

    function updateVisibleCount() {
        let targetModel = window.getModelForFilter(window.currentFilter);
        if (!targetModel || targetModel.count === 0) { window.visibleItemCount = 0; return; }
        let count = 0;
        for (let i = 0; i < targetModel.count; i++) {
            let fname = targetModel.get(i).fileName || "";
            let isVid = fname.startsWith("000_");
            if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) count++;
        }
        window.visibleItemCount = count;
    }

    readonly property string homeDir: "file://" + Quickshell.env("HOME")
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"
    readonly property string srcDir: {
        const dir = Quickshell.env("WALLPAPER_DIR")
        return (dir && dir !== "") ? dir : Quickshell.env("HOME") + "/Pictures/Wallpapers"
    }

    readonly property var transitions: ["simple", "fade", "left", "right", "top", "bottom", "wipe", "grow", "center", "outer", "random", "wave"]

    readonly property real itemWidth: window.s(400)
    readonly property real itemHeight: window.s(420)
    readonly property real borderWidth: window.s(3)
    readonly property real spacing: window.s(10)
    readonly property real skewFactor: -0.35

    Timer { id: scrollThrottle; interval: 150 }

    property bool isFilterAnimating: false
    Timer { id: filterAnimationTimer; interval: 800; onTriggered: window.isFilterAnimating = false }

    property bool isItemAnimating: false
    Timer { id: itemAnimationTimer; interval: 500; onTriggered: window.isItemAnimating = false }

    function getHexBucket(hexStr) {
        if (!hexStr) return "Monochrome";
        hexStr = String(hexStr).trim().replace(/#/g, '');
        if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);
        if (hexStr.length !== 6) return "Monochrome";
        let r = parseInt(hexStr.substring(0,2), 16) / 255;
        let g = parseInt(hexStr.substring(2,4), 16) / 255;
        let b = parseInt(hexStr.substring(4,6), 16) / 255;
        if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";
        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let d = max - min;
        let h = 0, s = max === 0 ? 0 : d / max, v = max;
        if (max !== min) {
            if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
            else if (max === g) h = (b - r) / d + 2;
            else h = (r - g) / d + 4;
            h /= 6;
        }
        h = h * 360;
        if (s < 0.05 || v < 0.08) return "Monochrome";
        if (h >= 345 || h < 15) return "Red";
        if (h >= 15 && h < 45) return "Orange";
        if (h >= 45 && h < 75) return "Yellow";
        if (h >= 75 && h < 165) return "Green";
        if (h >= 165 && h < 260) return "Blue";
        if (h >= 260 && h < 315) return "Purple";
        if (h >= 315 && h < 345) return "Pink";
        return "Monochrome";
    }

    function checkItemMatchesFilter(fileName, isVid, cv, filter) {
        if (filter === "All") return true;
        if (filter === "Video") return isVid;
        let hexColor = window.colorMap[String(fileName)];
        if (!hexColor) return filter === "Monochrome";
        return window.getHexBucket(hexColor) === filter;
    }

    FolderListModel {
        id: markerModel
        folder: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_picker/colors_markers"
        showDirs: false
        nameFilters: ["*_HEX_*"]
        onCountChanged: window.processMarkers()
        onStatusChanged: { if (status === FolderListModel.Ready) window.processMarkers() }
    }

    FolderListModel {
        id: srcModel
        folder: "file://" + window.srcDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
        showDirs: false
    }

    function processMarkers() {
        let newMap = {};
        for (let i = 0; i < markerModel.count; i++) {
            let markerName = markerModel.get(i, "fileName") || "";
            if (!markerName) continue;
            let splitIdx = markerName.lastIndexOf("_HEX_");
            if (splitIdx !== -1) {
                newMap[markerName.substring(0, splitIdx)] = "#" + markerName.substring(splitIdx + 5);
            }
        }
        window.colorMap = newMap;
        window.cacheVersion++;
        window.updateVisibleCount();
    }

    function triggerColorExtraction() {
        const extractScript = `
            COLOR_DIR="$HOME/.cache/wallpaper_picker/colors_markers"
            THUMBS="$HOME/.cache/wallpaper_picker/thumbs"
            CSV="$HOME/.cache/wallpaper_picker/colors.csv"
            mkdir -p "$COLOR_DIR"
            if [ -f "$CSV" ]; then
                while IFS=, read -r fname hexcode; do
                    cleanhex=$(echo "$hexcode" | tr -d '\r#' | cut -c 1-6)
                    if [ -n "$cleanhex" ] && [ -n "$fname" ]; then touch "$COLOR_DIR/$fname""_HEX_$cleanhex" 2>/dev/null; fi
                done < "$CSV"
                mv "$CSV" "$CSV.bak" 2>/dev/null
            fi
            if command -v magick &> /dev/null; then CMD="magick"; else CMD="convert"; fi
            for file in "$THUMBS"/*; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file"); found=0
                    for marker in "$COLOR_DIR/$filename"_HEX_*; do if [ -e "$marker" ]; then found=1; break; fi; done
                    if [ $found -eq 0 ]; then
                        hex=$($CMD "$file" -modulate 100,200 -resize "1x1^" -gravity center -extent 1x1 -depth 8 -format "%[hex:p{0,0}]" info:- 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)
                        if [ -n "$hex" ]; then touch "$COLOR_DIR/$filename""_HEX_$hex"; fi
                    fi
                fi
            done
        `;
        Quickshell.execDetached(["bash", "-c", extractScript]);
    }

    function stepToNextValidIndex(direction) {
        let targetModel = window.getModelForFilter(window.currentFilter);
        if (!targetModel || targetModel.count === 0) return;
        let start = view.currentIndex;
        let found = -1;
        if (direction === 1) {
            for (let i = start + 1; i < targetModel.count; i++) {
                let fname = targetModel.get(i).fileName || "";
                if (checkItemMatchesFilter(fname, fname.startsWith("000_"), window.cacheVersion, window.currentFilter)) { found = i; break; }
            }
        } else {
            for (let i = start - 1; i >= 0; i--) {
                let fname = targetModel.get(i).fileName || "";
                if (checkItemMatchesFilter(fname, fname.startsWith("000_"), window.cacheVersion, window.currentFilter)) { found = i; break; }
            }
        }
        if (found !== -1) { view.currentIndex = found; return; }
        let filterOrder = ["All", "Video", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Monochrome"];
        let currentFilterIdx = filterOrder.indexOf(window.currentFilter);
        if (currentFilterIdx === -1) {
            let current = start;
            for (let i = 0; i < targetModel.count; i++) {
                current = (current + direction + targetModel.count) % targetModel.count;
                let fname = targetModel.get(current).fileName || "";
                if (checkItemMatchesFilter(fname, fname.startsWith("000_"), window.cacheVersion, window.currentFilter)) { view.currentIndex = current; return; }
            }
            return;
        }
        let nextFilterIdx = currentFilterIdx + direction;
        if (nextFilterIdx >= 0 && nextFilterIdx < filterOrder.length) {
            window.jumpToLastOnFilterChange = (direction === -1);
            window.currentFilter = filterOrder[nextFilterIdx];
        }
    }

    function cycleFilter(direction) {
        let currentIdx = -1;
        for (let i = 0; i < window.filterData.length; i++) {
            if (window.filterData[i].name === window.currentFilter) { currentIdx = i; break; }
        }
        if (currentIdx !== -1) {
            let nextIdx = (currentIdx + direction + window.filterData.length) % window.filterData.length;
            window.currentFilter = window.filterData[nextIdx].name;
        }
    }

    function applyFilters(forceSnap) {
        let targetModel = window.getModelForFilter(window.currentFilter);
        if (!targetModel || targetModel.count === 0) { window.updateVisibleCount(); return; }
        let firstValidIndex = -1, lastValidIndex = -1;
        let cleanTarget = window.getCleanName(window.targetWallName);
        let targetIndex = -1;
        for (let i = 0; i < targetModel.count; i++) {
            let fname = targetModel.get(i).fileName || "";
            if (checkItemMatchesFilter(fname, fname.startsWith("000_"), window.cacheVersion, window.currentFilter)) {
                if (firstValidIndex === -1) firstValidIndex = i;
                lastValidIndex = i;
                if (cleanTarget !== "" && window.getCleanName(fname) === cleanTarget) targetIndex = i;
            }
        }
        let indexToFocus = -1;
        if (targetIndex !== -1) indexToFocus = targetIndex;
        else if (window.jumpToLastOnFilterChange && lastValidIndex !== -1) indexToFocus = lastValidIndex;
        else if (firstValidIndex !== -1) indexToFocus = firstValidIndex;
        window.jumpToLastOnFilterChange = false;
        if (indexToFocus !== -1) window.executeFocusRestore(indexToFocus, forceSnap === true);
        window.updateVisibleCount();
    }

    onCurrentFilterChanged: {
        window.isFilterAnimating = true;
        filterAnimationTimer.restart();
        window.isModelChanging = true;
        window._lastFilter = window.currentFilter;
        Qt.callLater(() => {
            view.forceActiveFocus();
            window.applyFilters(false);
            window.isModelChanging = false;
            window.updateFilterIndicator();
        });
    }

    Shortcut { sequence: "Left"; enabled: !window.isScrollingBlocked && !window.isApplying; onActivated: window.stepToNextValidIndex(-1) }
    Shortcut { sequence: "Right"; enabled: !window.isScrollingBlocked && !window.isApplying; onActivated: window.stepToNextValidIndex(1) }
    Shortcut { sequence: "Return"; enabled: !window.isScrollingBlocked && !window.isApplying; onActivated: { let m = window.getModelForFilter(window.currentFilter); if (view.currentIndex >= 0 && view.currentIndex < m.count) { let f = m.get(view.currentIndex).fileName; if (f) window.applyWallpaper(String(f), String(f).startsWith("000_")); } } }
    Shortcut { sequence: "Tab"; enabled: !window.isApplying; onActivated: window.cycleFilter(1) }
    Shortcut { sequence: "Backtab"; enabled: !window.isApplying; onActivated: window.cycleFilter(-1) }

    ListModel { id: localProxyModel }
    readonly property var activeModel: localProxyModel

    FolderListModel {
        id: localFolderModel
        folder: window.thumbDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: window.syncLocalModel()
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() }
    }

    function syncLocalModel() {
        let startIdx = localProxyModel.count;
        let endIdx = localFolderModel.count;
        if (endIdx < startIdx) { window.isModelChanging = true; localProxyModel.clear(); startIdx = 0; window.isModelChanging = false; }
        let batch = [];
        for (let i = startIdx; i < endIdx; i++) {
            let fn = localFolderModel.get(i, "fileName");
            if (fn !== undefined) batch.push({ "fileName": fn, "fileUrl": String(localFolderModel.get(i, "fileUrl")) });
        }
        if (batch.length > 0) localProxyModel.append(batch);
        window.updateVisibleCount();
        if (!window.initialFocusSet && localProxyModel.count > 0) window.tryFocus();
    }

    ListView {
        id: view
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: window.s(115)
        anchors.bottomMargin: window.s(15)
        
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

        spacing: 0
        orientation: ListView.Horizontal
        clip: false

        interactive: !window.isScrollingBlocked && !window.isApplying
        cacheBuffer: 2000

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.spacing) / 2)
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.spacing) / 2)
        
        highlightMoveDuration: window.initialFocusSet ? 700 : 0
        highlightResizeDuration: 700
        highlightResizeVelocity: -1
        focus: true
        
        // FEATURE 10: Overshoot bounce
        onMovementEnded: {
            if (contentX < -window.s(20)) {
                window.overshootBounce = true;
                positionViewAtIndex(view.currentIndex, ListView.Center);
            } else if (contentX > contentWidth - width + window.s(20)) {
                window.overshootBounce = true;
                positionViewAtIndex(view.currentIndex, ListView.Center);
            }
        }
        
        onCurrentIndexChanged: {
            window.isItemAnimating = true;
            itemAnimationTimer.restart();
        }
        
        add: Transition {
            enabled: window.initialFocusSet
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack }
            }
        }
        addDisplaced: Transition {
            enabled: window.initialFocusSet
            NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic }
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2)) }

        model: window.activeModel

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            // FEATURE 8: Mouse tracking for glow
            onMouseXChanged: window.mouseX = mouseX
            onMouseYChanged: window.mouseY = mouseY

            onWheel: (wheel) => {
                if (window.isScrollingBlocked || window.isApplying) { wheel.accepted = true; return; }
                if (scrollThrottle.running) { wheel.accepted = true; return; }

                let dx = wheel.angleDelta.x
                let dy = wheel.angleDelta.y
                let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy

                // FEATURE 10: Scroll momentum accumulation
                scrollAccum += delta

                if (Math.abs(scrollAccum) >= scrollThreshold) {
                    window.stepToNextValidIndex(scrollAccum > 0 ? -1 : 1)
                    scrollAccum = 0
                    scrollThrottle.start()
                }

                wheel.accepted = true
            }        
        }

        delegate: Item {
            id: delegateRoot
            
            readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
            readonly property bool isCurrent: ListView.isCurrentItem && !window.isScrollingBlocked
            readonly property bool isFakeSelected: window.isScrollingBlocked && index === 0
            readonly property bool isVisuallyEnlarged: isCurrent || isFakeSelected
            readonly property bool isVideo: safeFileName.startsWith("000_")
            readonly property bool matchesFilter: window.checkItemMatchesFilter(safeFileName, isVideo, window.cacheVersion, window.currentFilter)
            
            readonly property real targetWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5) : (window.itemWidth * 0.5)
            readonly property real targetHeight: isVisuallyEnlarged ? (window.itemHeight + window.s(30)) : window.itemHeight
            
            property bool isPlayingVideo: false
            
            // FEATURE 2: Parallax offset
            property real parallaxOffset: isVisuallyEnlarged ? 0 : ((index - ListView.view.currentIndex) * window.s(12))

            Timer {
                id: videoPlayTimer
                interval: 250
                running: delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo && !window.isScrollingBlocked && !window.isFilterAnimating && !window.isItemAnimating
                onTriggered: { if (delegateRoot.isVisuallyEnlarged && delegateRoot.isVideo) { delegateRoot.isPlayingVideo = true; previewPlayer.play(); } }
            }

            onIsVisuallyEnlargedChanged: {
                if (!isVisuallyEnlarged) { isPlayingVideo = false; videoPlayTimer.stop(); previewPlayer.stop(); }
            }
            
            width: matchesFilter ? (targetWidth + window.spacing) : 0
            visible: width > 0.1 || opacity > 0.01
            opacity: matchesFilter ? (isVisuallyEnlarged ? 1.0 : 0.35) : 0.0
            
            scale: matchesFilter ? (isVisuallyEnlarged ? 1.08 : 0.72) : 0.4

            height: matchesFilter ? targetHeight : 0
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            anchors.verticalCenterOffset: window.s(15)

            z: isVisuallyEnlarged ? 10 : 1
            
            Behavior on scale { enabled: window.initialFocusSet; NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on width { enabled: window.initialFocusSet; NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: window.initialFocusSet; NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on opacity { enabled: window.initialFocusSet; NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            Item {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ((window.itemHeight - height) / 2) * window.skewFactor
                
                width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + window.spacing)) : 0
                height: parent.height

                transform: Matrix4x4 {
                    property real s: window.skewFactor
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: delegateRoot.matchesFilter && !window.isScrollingBlocked && !window.isApplying
                    onClicked: {
                        view.currentIndex = index
                        window.applyWallpaper(delegateRoot.safeFileName, delegateRoot.isVideo)
                    }
                    hoverEnabled: true
                    onMouseXChanged: window.mouseX = mouseX + delegateRoot.x
                    onMouseYChanged: window.mouseY = mouseY + delegateRoot.y
                }

                Image {
                    anchors.fill: parent
                    source: fileUrl !== undefined ? fileUrl : ""
                    sourceSize: Qt.size(1, 1)
                    fillMode: Image.Stretch
                    visible: true
                    asynchronous: true
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth
                    Rectangle { anchors.fill: parent; color: _theme.base }
                    clip: true

                    Image {
                        anchors.centerIn: parent
                        // FEATURE 2: Parallax image depth
                        anchors.horizontalCenterOffset: window.s(-50) + delegateRoot.parallaxOffset
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
                        height: window.itemHeight + window.s(30)
                        fillMode: Image.PreserveAspectCrop
                        source: fileUrl !== undefined ? fileUrl : ""
                        asynchronous: true

                        Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    
                    MediaPlayer {
                        id: previewPlayer
                        source: delegateRoot.isPlayingVideo ? "file://" + window.srcDir + "/" + window.getCleanName(delegateRoot.safeFileName) : ""
                        audioOutput: AudioOutput { muted: true }
                        videoOutput: previewOutput
                        loops: MediaPlayer.Infinite
                    }

                    VideoOutput {
                        id: previewOutput
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: window.s(-50) + delegateRoot.parallaxOffset
                        width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
                        height: window.itemHeight + window.s(30)
                        fillMode: VideoOutput.PreserveAspectCrop
                        visible: delegateRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState

                        Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }

                    // FEATURE 8: Mouse-follow glow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -window.s(12)
                        color: "transparent"
                        border.width: delegateRoot.isVisuallyEnlarged ? window.s(2) : 0
                        border.color: delegateRoot.isVisuallyEnlarged ? _theme.blue : "transparent"
                        opacity: delegateRoot.isVisuallyEnlarged ? 1.0 : 0.0
                        visible: true
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: delegateRoot.isVisuallyEnlarged
                            shadowColor: _theme.blue
                            shadowBlur: 1.0
                            shadowVerticalOffset: delegateRoot.isVisuallyEnlarged ? 0 : 0
                            shadowHorizontalOffset: delegateRoot.isVisuallyEnlarged ? ((window.mouseX - delegateRoot.width/2) * 0.02) : 0
                        }
                    }

                    // FEATURE 5: Apply pulse animation
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -window.s(8)
                        color: "transparent"
                        border.width: window.showApplyPulse && delegateRoot.isVisuallyEnlarged ? window.s(6) : 0
                        border.color: _theme.blue
                        opacity: window.showApplyPulse && delegateRoot.isVisuallyEnlarged ? 0.8 : 0.0
                        visible: true
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        visible: delegateRoot.isVideo && (!delegateRoot.isPlayingVideo || previewPlayer.playbackState !== MediaPlayer.PlayingState)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: window.s(10)
                        width: window.s(32)
                        height: window.s(32)
                        radius: window.s(6)
                        color: Qt.rgba(_theme.base.r, _theme.base.g, _theme.base.b, 0.6)
                        transform: Matrix4x4 {
                            property real s: -window.skewFactor
                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                        
                        Canvas {
                            anchors.fill: parent
                            anchors.margins: window.s(8)
                            property real scaleTrigger: window.s(1)
                            onScaleTriggerChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                var s = window.s;
                                ctx.reset();
                                ctx.fillStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.93);
                                ctx.beginPath();
                                ctx.moveTo(s(4), 0);
                                ctx.lineTo(s(14), s(8));
                                ctx.lineTo(s(4), s(16));
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // FEATURE 6: Sliding filter indicator + filter bar
    // =========================================================================
    Rectangle {
        id: filterBarBackground
        anchors.top: parent.top
        anchors.topMargin: window.isReady ? window.s(40) : window.s(-100)
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        anchors.horizontalCenter: parent.horizontalCenter
        z: 20
        height: window.s(56)
        width: filterRow.width + window.s(24)
        radius: window.s(14)
        
        color: Qt.rgba(_theme.mantle.r, _theme.mantle.g, _theme.mantle.b, 0.90)
        border.color: _theme.surface2
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(_theme.blue.r, _theme.blue.g, _theme.blue.b, 0.3)
            shadowBlur: 0.5
            shadowVerticalOffset: 2
        }

        Row {
            id: filterRow
            anchors.centerIn: parent
            spacing: window.s(12)

            // FEATURE 6: Sliding filter indicator pill
            Rectangle {
                id: filterIndicator
                anchors.verticalCenter: parent.verticalCenter
                width: currentFilterWidth
                height: window.s(40)
                radius: window.s(12)
                color: Qt.rgba(_theme.blue.r, _theme.blue.g, _theme.blue.b, 0.15)
                border.color: Qt.rgba(_theme.blue.r, _theme.blue.g, _theme.blue.b, 0.3)
                border.width: 1
                z: -1
                
                property real currentFilterWidth: window.s(40)
                property real targetX: 0
                x: targetX
                
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                Behavior on currentFilterWidth { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: notifDrawer
                height: window.s(44)
                property real paddingLeft: window.showSpinner ? window.s(40) : window.s(16)
                property real targetWidth: window.showNotification ? Math.min(notifTextDrawer.implicitWidth + paddingLeft + window.s(20), window.s(300)) : 0
                width: targetWidth
                visible: width > 0.1
                radius: window.s(10)
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                
                color: window.showNotification ? _theme.surface2 : "transparent"
                border.color: window.showNotification ? _theme.surface1 : "transparent"
                border.width: 1

                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Item {
                    visible: window.showSpinner
                    width: window.s(44)
                    height: window.s(44)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: notifSpinner
                        width: window.s(14)
                        height: window.s(14)
                        anchors.centerIn: parent
                        property real scaleTrigger: window.s(1)
                        onScaleTriggerChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            var s = window.s;
                            ctx.reset();
                            ctx.lineWidth = s(2);
                            ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.3);
                            ctx.beginPath();
                            ctx.arc(s(7), s(7), s(5), 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.strokeStyle = Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.9);
                            ctx.beginPath();
                            ctx.arc(s(7), s(7), s(5), 0, Math.PI * 0.5);
                            ctx.stroke();
                        }
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 800
                            running: window.showSpinner && window.showNotification
                        }
                    }
                }

                Text {
                    id: notifTextDrawer
                    anchors.left: parent.left
                    anchors.leftMargin: window.showSpinner ? window.s(40) : window.s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, window.s(300) - anchors.leftMargin - window.s(16))
                    text: window.currentNotification
                    color: _theme.text
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(14)
                    font.bold: true
                    elide: Text.ElideRight

                    opacity: window.showNotification ? 0.9 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                    Behavior on anchors.leftMargin { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                }
            }

            Rectangle {
                id: monitorDrawer
                visible: monitorModel.count > 1
                height: window.s(44)
                property real expandedWidth: window.s(44) + monitorListRow.width + window.s(8)
                width: visible ? (window.isMonitorSelectorOpen ? expandedWidth : window.s(44)) : 0
                radius: window.s(10)
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                color: window.isMonitorSelectorOpen ? _theme.surface2 : "transparent"
                border.color: window.isMonitorSelectorOpen ? _theme.text : _theme.surface1
                border.width: window.isMonitorSelectorOpen ? window.s(2) : 1
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                MouseArea {
                    id: monitorIconMouse
                    width: window.s(44)
                    height: window.s(44)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    hoverEnabled: true
                    enabled: !window.isApplying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.isMonitorSelectorOpen = !window.isMonitorSelectorOpen
                }

                Canvas {
                    id: monitorIcon
                    width: window.s(18)
                    height: window.s(18)
                    anchors.centerIn: monitorIconMouse
                    property string activeColor: window.isMonitorSelectorOpen ? _theme.text : (monitorIconMouse.containsMouse ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7))
                    onActiveColorChanged: requestPaint()
                    property real scaleTrigger: window.s(1)
                    onScaleTriggerChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        var s = window.s;
                        ctx.reset();
                        ctx.lineWidth = s(2);
                        ctx.strokeStyle = activeColor;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.rect(s(2), s(3), s(14), s(9));
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(s(9), s(12));
                        ctx.lineTo(s(9), s(16));
                        ctx.moveTo(s(5), s(16));
                        ctx.lineTo(s(13), s(16));
                        ctx.stroke();
                    }
                }

                Row {
                    id: monitorListRow
                    anchors.left: monitorIconMouse.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: window.s(8)
                    opacity: window.isMonitorSelectorOpen ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    Repeater {
                        model: monitorModel
                        delegate: Item {
                            width: monitorText.contentWidth + window.s(16)
                            height: window.s(32)
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent
                                radius: window.s(6)
                                color: model.selected ? _theme.text : _theme.surface1
                                border.color: model.selected ? _theme.text : _theme.surface2
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 250 } }
                                Behavior on border.color { ColorAnimation { duration: 250 } }
                                Text {
                                    id: monitorText
                                    text: model.name
                                    anchors.centerIn: parent
                                    color: model.selected ? _theme.base : _theme.text
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(12)
                                    font.bold: model.selected
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: window.isMonitorSelectorOpen && !window.isApplying
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.selected) {
                                        let activeCount = 0;
                                        for (let i = 0; i < monitorModel.count; i++) { if (monitorModel.get(i).selected) activeCount++; }
                                        if (activeCount > 1) monitorModel.setProperty(index, "selected", false);
                                    } else {
                                        monitorModel.setProperty(index, "selected", true);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Repeater {
                id: filterRepeater
                model: window.filterData

                delegate: Item {
                    id: filterItem
                    width: !visible ? 0 : ((modelData.name === "Video" || modelData.name === "All") ? window.s(44) : (modelData.hex === "" ? filterText.contentWidth + window.s(24) : window.s(36)))
                    height: !visible ? 0 : window.s(36)
                    anchors.verticalCenter: parent.verticalCenter
                    
                    onVisibleChanged: updateFilterIndicator()
                    onWidthChanged: if (index <= filterRepeater.model.length) updateFilterIndicator()

                    Rectangle {
                        anchors.fill: parent
                        radius: window.s(10)
                        color: modelData.hex === "" 
                                ? (window.currentFilter === modelData.name ? _theme.surface2 : "transparent") 
                                : modelData.hex
                        border.color: window.currentFilter === modelData.name ? _theme.text : _theme.surface1
                        border.width: window.currentFilter === modelData.name ? window.s(2) : 1
                        scale: window.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }

                        Text {
                            id: filterText
                            visible: modelData.hex === "" && modelData.name !== "Video" && modelData.name !== "All"
                            text: modelData.label
                            anchors.centerIn: parent
                            color: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(14)
                            font.bold: window.currentFilter === modelData.name
                            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
                        }

                        Canvas {
                            visible: modelData.name === "Video"
                            width: window.s(14); height: window.s(16)
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: window.s(2)
                            property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
                            onActiveColorChanged: requestPaint()
                            property real scaleTrigger: window.s(1)
                            onScaleTriggerChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                var s = window.s;
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(s(14), s(8));
                                ctx.lineTo(0, s(16));
                                ctx.closePath();
                                ctx.fill();
                            }
                        }

                        Canvas {
                            visible: modelData.name === "All"
                            width: window.s(14); height: window.s(14)
                            anchors.centerIn: parent
                            property string activeColor: window.currentFilter === modelData.name ? _theme.text : Qt.rgba(_theme.text.r, _theme.text.g, _theme.text.b, 0.7)
                            onActiveColorChanged: requestPaint()
                            property real scaleTrigger: window.s(1)
                            onScaleTriggerChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                var s = window.s;
                                ctx.reset();
                                ctx.fillStyle = activeColor;
                                ctx.fillRect(0, 0, s(6), s(6));
                                ctx.fillRect(s(8), 0, s(6), s(6));
                                ctx.fillRect(0, s(8), s(6), s(6));
                                ctx.fillRect(s(8), s(8), s(6), s(6));
                            }
                        }
                    }

                    MouseArea {
                        id: filterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !window.isApplying
                        onClicked: window.currentFilter = modelData.name
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }


        }
    }
    
    // FEATURE 6: Update filter indicator position function
    function updateFilterIndicator() {
        let filters = filterRepeater.children || [];
        let target = null;
        let totalOffset = 0;
        
        for (let i = 0; i < window.filterData.length; i++) {
            let fd = window.filterData[i];
            for (let j = 0; j < filters.length; j++) {
                let child = filters[j];
                if (child.modelData && child.modelData.name === fd.name) {
                    if (fd.name === window.currentFilter) {
                        target = child;
                    }
                    if (child === target) break;
                    totalOffset += child.width + window.s(12);
                    break;
                }
            }
            if (target) break;
        }
        
        if (target) {
            filterIndicator.targetX = totalOffset - window.s(4);
            filterIndicator.currentFilterWidth = target.width + window.s(8);
        }
    }
    
    Component.onCompleted: {
        window.loadMonitors();
        view.forceActiveFocus();
        window.processMarkers();
        window.triggerColorExtraction();
    }


}
