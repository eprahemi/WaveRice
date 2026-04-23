import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    MatugenColors { id: _theme }
    
    readonly property color base: _theme.base
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue

    property var allClips: []
    
    // Pagination properties
    property int currentOffset: 0
    property int fetchLimit: 18
    property bool isLoading: false
    property bool hasMore: true
    
    // Global state
    property int navDuration: 0
    property bool previewMode: false
    property bool previewAnimationDone: false
    property string fullTextPreview: ""

    onPreviewModeChanged: {
        if (!previewMode) {
            fullTextPreview = "";
            previewAnimationDone = false;
        }
    }

    Process {
        id: fullTextFetcher
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                window.fullTextPreview = this.text;
            }
        }
    }

    function updatePreviewText() {
        window.fullTextPreview = "";
        let item = clipModel.get(clipList.currentIndex);
        if (item && item.type === "text") {
            fullTextFetcher.command = ["cliphist", "decode", item.id.toString()];
            fullTextFetcher.running = true;
        }
    }

    Process {
        id: clipFetcher
        running: true
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        let newItems = JSON.parse(this.text);
                        
                        if (newItems.length < window.fetchLimit) {
                            window.hasMore = false;
                        }
                        
                        if (window.currentOffset === 0) {
                            window.allClips = newItems;
                            window.filterClips(searchInput.text);
                        } else {
                            window.appendClips(newItems);
                        }
                    }
                } catch(e) {
                    console.log("Error parsing clipboard list: ", e);
                } finally {
                    window.isLoading = false;
                }
            }
        }
    }

    ListModel {
        id: clipModel
    }

    function loadMore() {
        if (isLoading || !hasMore) return;
        isLoading = true;
        currentOffset += fetchLimit;
        clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", window.currentOffset, window.fetchLimit];
        clipFetcher.running = true;
    }

    function appendClips(newItems) {
        let q = searchInput.text.toLowerCase();
        for (let i = 0; i < newItems.length; i++) {
            allClips.push(newItems[i]);
            if (q === "" || newItems[i].type === "image" || newItems[i].content.toLowerCase().includes(q)) {
                clipModel.append(newItems[i]);
            }
        }
    }

    function filterClips(query) {
        clipList.currentIndex = -1;
        clipList.positionViewAtBeginning();

        let q = query.toLowerCase();
        clipModel.clear();

        for (let i = 0; i < allClips.length; i++) {
            if (allClips[i].type === "image" || allClips[i].content.toLowerCase().includes(q)) {
                clipModel.append(allClips[i]);
            }
        }

        if (clipModel.count > 0) {
            clipList.currentIndex = 0;
        }
    }

    function copyToClipboard(id) {
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + id + " | wl-copy"]);
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    Timer {
        id: focusTimer
        interval: 50
        running: true
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Connections {
        target: window
        function onVisibleChanged() {
            if (window.visible) {
                focusTimer.restart();
                introPhaseAnim.restart();
                window.navDuration = 0; 
                window.previewMode = false;
                window.previewAnimationDone = false;
                window.fullTextPreview = "";
                
                window.currentOffset = 0;
                window.hasMore = true;
                window.isLoading = true;
                clipFetcher.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py", 0, window.fetchLimit];
                clipFetcher.running = true;
            }
        }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    property real introPhase: 0
    NumberAnimation on introPhase {
        id: introPhaseAnim
        from: 0; to: 1; duration: 400; easing.type: Easing.OutQuart; running: true
    }

    Rectangle {
        id: mainBg
        width: parent.width
        
        property real searchHeight: window.s(65)
        property real separatorHeight: 1
        
        property int cols: 3
        property real cellW: (width - window.s(20)) / cols
        property real cellH: window.s(120)
        
        property real maxVisibleRows: 4
        property real visibleRows: Math.min(Math.ceil(clipModel.count / cols), maxVisibleRows)
        property real targetListHeight: clipModel.count === 0 ? 0 : (visibleRows * cellH)
        property real targetMargins: clipModel.count > 0 ? window.s(20) : 0

        property real animatedListHeight: targetListHeight
        property real animatedMargins: targetMargins

        Behavior on animatedListHeight { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on animatedMargins { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        height: searchHeight + separatorHeight + animatedMargins + animatedListHeight

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        radius: window.s(16)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
        border.color: window.surface1
        border.width: 1
        clip: true

        transform: Translate { y: (window.introPhase - 1) * window.s(40) }
        opacity: window.introPhase

        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
            opacity: 0.08
            color: window.mauve
            Behavior on color { ColorAnimation { duration: 1000 } }
        }
        
        Rectangle {
            width: parent.width * 0.9; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
            opacity: 0.06
            color: window.blue
            Behavior on color { ColorAnimation { duration: 1000 } }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.searchHeight
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: window.s(15)
                    anchors.leftMargin: window.s(20)
                    anchors.rightMargin: window.s(20)
                    spacing: window.s(15)

                    Item {
                        width: window.s(18)
                        height: window.s(18)

                        Text {
                            anchors.centerIn: parent
                            text: "󰅌"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: window.s(18)
                            color: searchInput.activeFocus ? window.mauve : window.subtext0
                            
                            opacity: !window.previewMode ? 1 : 0
                            scale: !window.previewMode ? 1 : 0.5
                            rotation: !window.previewMode ? 0 : -90
                            
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰈈"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: window.s(18)
                            color: window.mauve
                            
                            opacity: window.previewMode ? 1 : 0
                            scale: window.previewMode ? 1 : 0.5
                            rotation: window.previewMode ? 0 : 90
                            
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        background: Item {} 
                        color: window.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(16)
                        
                        placeholderText: "Search"
                        placeholderTextColor: window.subtext0 
                        
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true

                        onTextChanged: {
                            if (window.previewMode) {
                                window.previewMode = false;
                            }
                            filterClips(text);
                        }

                        Keys.onTabPressed: {
                            if (clipModel.count > 0) {
                                window.previewMode = !window.previewMode;
                                if (window.previewMode) {
                                    window.updatePreviewText();
                                }
                            }
                            event.accepted = true;
                        }

                        Keys.onRightPressed: {
                            window.previewMode = false;
                            window.navDuration = 300; 
                            if (clipList.currentIndex < clipModel.count - 1) { clipList.currentIndex++; }
                            event.accepted = true;
                        }
                        Keys.onLeftPressed: {
                            window.previewMode = false;
                            window.navDuration = 300;
                            if (clipList.currentIndex > 0) { clipList.currentIndex--; }
                            event.accepted = true;
                        }
                        Keys.onDownPressed: {
                            window.previewMode = false;
                            window.navDuration = 300;
                            if (clipList.currentIndex + mainBg.cols < clipModel.count) { clipList.currentIndex += mainBg.cols; }
                            else { clipList.currentIndex = clipModel.count - 1; }
                            event.accepted = true;
                        }
                        Keys.onUpPressed: {
                            window.previewMode = false;
                            window.navDuration = 300;
                            if (clipList.currentIndex - mainBg.cols >= 0) { clipList.currentIndex -= mainBg.cols; }
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: {
                            if (clipList.currentIndex >= 0 && clipList.currentIndex < clipModel.count) {
                                copyToClipboard(clipModel.get(clipList.currentIndex).id);
                            }
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: {
                            if (window.previewMode) {
                                window.previewMode = false;
                            } else {
                                Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                            }
                            event.accepted = true;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.separatorHeight
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
            }

            GridView {
                id: clipList
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.animatedListHeight
                Layout.topMargin: mainBg.animatedMargins / 2
                Layout.bottomMargin: mainBg.animatedMargins / 2
                Layout.leftMargin: window.s(10)
                Layout.rightMargin: window.s(10)
                
                clip: true
                model: clipModel
                cellWidth: mainBg.cellW
                cellHeight: mainBg.cellH
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                highlightFollowsCurrentItem: false
                
                onContentYChanged: {
                    if (contentY + height >= contentHeight - window.s(80)) {
                        window.loadMore();
                    }
                }

                NumberAnimation {
                    id: smoothScrollAnim
                    target: clipList
                    property: "contentY"
                    duration: window.navDuration > 0 ? window.navDuration : 0
                    easing.type: Easing.OutQuart
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        let row = Math.floor(currentIndex / mainBg.cols);
                        let targetY = row * mainBg.cellH;

                        if (window.navDuration > 0) {
                            if (targetY < contentY) {
                                smoothScrollAnim.to = targetY;
                                smoothScrollAnim.start();
                            } else if (targetY + mainBg.cellH > contentY + height) {
                                smoothScrollAnim.to = targetY + mainBg.cellH - height;
                                smoothScrollAnim.start();
                            }
                        } else {
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: window.s(4)
                        radius: window.s(2)
                        color: window.surface2
                        opacity: 0.5
                    }
                }

                highlight: Item {
                    z: 0 
                    Rectangle {
                        id: activeHighlight
                        width: clipList.cellWidth - window.s(10)
                        height: clipList.cellHeight - window.s(10)
                        radius: window.s(8)
                        color: window.mauve

                        property int curIdx: clipList.currentIndex
                        property real targetX: curIdx === -1 ? 0 : (curIdx % mainBg.cols) * clipList.cellWidth
                        property real targetY: curIdx === -1 ? 0 : Math.floor(curIdx / mainBg.cols) * clipList.cellHeight

                        Behavior on x { NumberAnimation { duration: window.navDuration; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: window.navDuration; easing.type: Easing.OutCubic } }

                        x: targetX + window.s(5)
                        y: targetY + window.s(5)
                        opacity: clipList.count > 0 && clipList.currentIndex >= 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                delegate: Item {
                    id: delegateRoot
                    width: clipList.cellWidth
                    height: clipList.cellHeight
                    
                    z: index === clipList.currentIndex ? 50 : 1
                    
                    Rectangle {
                        id: cardBg
                        x: window.s(5)
                        y: window.s(5)
                        width: parent.width - window.s(10)
                        height: parent.height - window.s(10)
                        
                        radius: window.s(8)
                        
                        color: ma.containsMouse && index !== clipList.currentIndex ? Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4) : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            z: 2
                            x: window.s(8)
                            y: window.s(8)
                            width: window.s(22)
                            height: window.s(22)
                            radius: window.s(6)
                            
                            color: index === clipList.currentIndex ? window.crust : Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.85)
                            
                            Text {
                                anchors.centerIn: parent
                                text: (index + 1)
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(11)
                                font.weight: Font.Bold
                                color: index === clipList.currentIndex ? window.mauve : window.text
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: window.s(4)
                            visible: model.type === "image"
                            color: "transparent"
                            radius: window.s(6)
                            clip: true
                            
                            Image {
                                anchors.fill: parent
                                source: model.type === "image" ? "file://" + model.content : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: false
                                cache: true
                                smooth: true
                                mipmap: true
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: window.s(12)
                            anchors.topMargin: window.s(36)
                            visible: model.type === "text"
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: model.content
                                font.family: "JetBrains Mono"
                                font.pixelSize: window.s(13)
                                font.weight: index === clipList.currentIndex ? Font.Bold : Font.Medium
                                color: index === clipList.currentIndex ? window.base : window.text
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                                maximumLineCount: 3
                                
                                property real textShift: index === clipList.currentIndex ? window.s(4) : 0
                                transform: Translate { x: textShift }
                                Behavior on textShift { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: !window.previewMode
                            enabled: !window.previewMode
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                window.navDuration = 100;
                                clipList.currentIndex = index;
                                
                                if (mouse.button === Qt.RightButton) {
                                    window.previewMode = true;
                                    window.updatePreviewText();
                                } else {
                                    copyToClipboard(model.id);
                                }
                            }
                        }
                    }
                }
            }
        }

        // FULL SCREEN PREVIEW OVERLAY
        Rectangle {
            id: previewMorph
            z: 100
            
            property var curItem: clipList.currentIndex >= 0 && clipModel.count > 0 ? clipModel.get(clipList.currentIndex) : null
            property int curIdx: clipList.currentIndex !== -1 ? clipList.currentIndex : 0
            
            // Expanded target dimensions
            property real gridX: window.s(10)
            property real gridY: mainBg.searchHeight + mainBg.separatorHeight + mainBg.animatedMargins / 2
            property real gridW: mainBg.width - window.s(20)
            property real gridH: mainBg.animatedListHeight
            
            // Start dimensions (Matches exactly the physical position of the selected list item)
            property real startX: gridX + (curIdx % mainBg.cols) * clipList.cellWidth + window.s(5)
            property real startY: gridY + Math.floor(curIdx / mainBg.cols) * clipList.cellHeight - clipList.contentY + window.s(5)
            property real startW: clipList.cellWidth - window.s(10)
            property real startH: clipList.cellHeight - window.s(10)
            
            color: window.crust
            border.color: window.mauve
            border.width: window.previewMode ? window.s(2) : 0
            Behavior on border.width { NumberAnimation { duration: 250 } }
            clip: true
            
            // Matte Header Bar
            Rectangle {
                id: previewHeader
                width: parent.width
                height: window.s(30)
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.7)
                anchors.top: parent.top
                
                opacity: window.previewMode ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                
                Rectangle {
                    width: window.s(8)
                    height: window.s(8)
                    radius: window.s(4)
                    color: window.blue
                    anchors.right: parent.right
                    anchors.rightMargin: window.s(20)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            // Image Preview
            Image {
                anchors.top: previewHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: window.s(20)
                
                source: (previewMorph.curItem && previewMorph.curItem.type === "image") ? "file://" + previewMorph.curItem.content : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: false
                visible: previewMorph.curItem && previewMorph.curItem.type === "image"
                
                opacity: window.previewMode ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; } }
            }
            
            // Text Preview
            Flickable {
                anchors.top: previewHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: window.s(20)
                
                contentWidth: width
                contentHeight: textPreviewContent.paintedHeight
                clip: true
                
                visible: previewMorph.curItem && previewMorph.curItem.type === "text"
                opacity: window.previewMode ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; } }
                
                TextEdit {
                    id: textPreviewContent
                    width: parent.width
                    // DEFERRED LOADING: Use short text until animation finishes, then inject the massive string
                    text: {
                        if (!window.previewMode || !previewMorph.curItem || previewMorph.curItem.type !== "text") return "";
                        if (window.previewAnimationDone && window.fullTextPreview !== "") {
                            return window.fullTextPreview;
                        }
                        return previewMorph.curItem.content;
                    }
                    color: window.text
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(14)
                    wrapMode: TextEdit.Wrap
                    readOnly: true
                    selectByMouse: true
                    selectionColor: window.surface2
                    selectedTextColor: window.mauve
                }
            }
            
            states: [
                State {
                    name: "hidden"
                    when: !window.previewMode
                    PropertyChanges { 
                        target: previewMorph; 
                        opacity: 0; 
                        x: previewMorph.startX; 
                        y: previewMorph.startY; 
                        width: previewMorph.startW; 
                        height: previewMorph.startH; 
                        radius: window.s(8) 
                    }
                },
                State {
                    name: "visible"
                    when: window.previewMode
                    PropertyChanges { 
                        target: previewMorph; 
                        opacity: 1; 
                        x: previewMorph.gridX; 
                        y: previewMorph.gridY; 
                        width: previewMorph.gridW; 
                        height: previewMorph.gridH; 
                        radius: window.s(12) 
                    }
                }
            ]
            
            transitions: [
                Transition {
                    from: "hidden"; to: "visible"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: previewMorph; property: "opacity"; duration: 100 }
                            NumberAnimation { properties: "x,y,width,height,radius"; duration: 250; easing.type: Easing.OutExpo }
                        }
                        // Flip the flag only AFTER the heavy geometry animation finishes
                        ScriptAction { script: { window.previewAnimationDone = true; } }
                    }
                },
                Transition {
                    from: "visible"; to: "hidden"
                    ParallelAnimation {
                        NumberAnimation { properties: "x,y,width,height,radius"; duration: 350; easing.type: Easing.OutExpo }
                        SequentialAnimation {
                            PauseAnimation { duration: 200 }
                            NumberAnimation { target: previewMorph; property: "opacity"; to: 0; duration: 150 }
                        }
                    }
                }
            ]
        }
    }
}
