#!/usr/bin/env bash

# Directory to save screenshots
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Define timestamp for filenames
time=$(date +'%Y-%m-%d-%H%M%S')
FILENAME="$SAVE_DIR/Screenshot_$time.png"
CACHE_FILE="$HOME/.cache/qs_screenshot_geom"

# Notification Function
send_notification() {
    if [ -s "$FILENAME" ]; then
        notify-send -a "Screenshot" \
                    -i "$FILENAME" \
                    "Screenshot Saved" \
                    "File: Screenshot_$time.png\nFolder: $SAVE_DIR"
    fi
}

# Parse arguments
EDIT_MODE=false
FULL_MODE=false
GEOMETRY=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --edit) EDIT_MODE=true; shift ;;
        --full) FULL_MODE=true; shift ;;
        --geometry) GEOMETRY="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# ---------------------------------------------------------
# PHASE 1: Execution (Instant Fullscreen OR Region Callback)
# ---------------------------------------------------------
if [ "$FULL_MODE" = true ] || [ -n "$GEOMETRY" ]; then
    
    GRIM_CMD="grim -"
    if [ -n "$GEOMETRY" ]; then
        GRIM_CMD="grim -g \"$GEOMETRY\" -"
    fi

    if [ "$EDIT_MODE" = true ]; then
        eval $GRIM_CMD | GSK_RENDERER=gl satty --filename - --output-filename "$FILENAME" --init-tool brush --copy-command wl-copy
    else
        eval $GRIM_CMD | tee "$FILENAME" | wl-copy
    fi
    
    send_notification
    exit 0
fi

# ---------------------------------------------------------
# PHASE 2: UI Trigger (Launch Standalone Quickshell Overlay)
# ---------------------------------------------------------
if [ "$EDIT_MODE" = true ]; then
    export QS_SCREENSHOT_EDIT="true"
else
    export QS_SCREENSHOT_EDIT="false"
fi

# Load previous geometry if it exists
if [ -f "$CACHE_FILE" ]; then
    export QS_CACHED_GEOM=$(cat "$CACHE_FILE")
else
    export QS_CACHED_GEOM=""
fi

# Spin up a secondary, isolated Quickshell instance
quickshell -p ~/.config/hypr/scripts/quickshell/ScreenshotOverlay.qml
