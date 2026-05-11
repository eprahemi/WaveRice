#!/usr/bin/env bash

MUSIC_DIR="$HOME/.config/hypr/scripts/quickshell/music"
STATE_DIR="/tmp/lock-music"
CTRL="$HOME/.config/hypr/scripts/quickshell/music_control.sh"

mkdir -p "$STATE_DIR"

ls "$MUSIC_DIR"/*.mp3 > "$STATE_DIR/playlist" 2>/dev/null

mapfile -t SONGS < "$STATE_DIR/playlist" 2>/dev/null
TOTAL=${#SONGS[@]}

INDEX=$(cat "$STATE_DIR/index" 2>/dev/null || echo 0)
INDEX=$((INDEX % TOTAL))

echo "$INDEX" > "$STATE_DIR/index"
echo "${SONGS[$INDEX]}" > "$STATE_DIR/song"
basename "${SONGS[$INDEX]}" .mp3 > "$STATE_DIR/display-name"

pw-play "${SONGS[$INDEX]}" 2>/dev/null &
echo $! > "$STATE_DIR/pid"

# Apply volume
sleep 0.1
SINK_ID=$(pactl list sink-inputs 2>/dev/null | grep -B20 'pw-play' | grep 'Sink Input #' | head -1 | grep -o '[0-9][0-9]*')
pactl set-sink-input-volume "$SINK_ID" "50%" 2>/dev/null
echo 50 > "$STATE_DIR/volume"

quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml

kill "$(cat "$STATE_DIR/pid" 2>/dev/null)" 2>/dev/null
wait 2>/dev/null
