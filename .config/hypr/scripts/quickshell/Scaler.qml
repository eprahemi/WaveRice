import QtQuick
import "WindowRegistry.js" as LayoutMath 

QtObject {
    id: root

    property real currentWidth: 1920.0
    
    property real uiScale: masterWindow.globalUiScale
    
    // Recalculates automatically if currentWidth OR uiScale changes
    property real baseScale: LayoutMath.getScale(currentWidth, uiScale)
    
    function s(val) { 
        return LayoutMath.s(val, baseScale); 
    }
}
