#!/usr/bin/env bash
MUSIC_DIR="$HOME/.config/hypr/scripts/quickshell/music"
STATE_DIR="/tmp/lock-music"

_apply_volume() {
  sleep 0.1
  SINK_ID=$(pactl list sink-inputs 2>/dev/null | grep -B20 'pw-play' | grep 'Sink Input #' | head -1 | grep -o '[0-9][0-9]*')
  pactl set-sink-input-volume "$SINK_ID" "50%" 2>/dev/null
}

case "${1:-playlist}" in
  playlist)
    ls "$MUSIC_DIR"/*.mp3 2>/dev/null
    ;;
  current)
    cat "$STATE_DIR/song" 2>/dev/null || ls "$MUSIC_DIR"/*.mp3 2>/dev/null | head -1
    ;;
  next)
    mapfile -t SONGS < "$STATE_DIR/playlist" 2>/dev/null
    TOTAL=${#SONGS[@]}
    [[ $TOTAL -eq 0 ]] && exit 1
    INDEX=$(($(cat "$STATE_DIR/index" 2>/dev/null || echo -1) + 1))
    INDEX=$((INDEX % TOTAL))
    echo "$INDEX" > "$STATE_DIR/index"
    echo "${SONGS[$INDEX]}" > "$STATE_DIR/song"
    basename "${SONGS[$INDEX]}" .mp3 > "$STATE_DIR/display-name"
    kill "$(cat "$STATE_DIR/pid" 2>/dev/null)" 2>/dev/null
    pw-play "${SONGS[$INDEX]}" 2>/dev/null &
    echo $! > "$STATE_DIR/pid"
    _apply_volume
    echo "${SONGS[$INDEX]}"
    ;;
  prev)
    mapfile -t SONGS < "$STATE_DIR/playlist" 2>/dev/null
    TOTAL=${#SONGS[@]}
    [[ $TOTAL -eq 0 ]] && exit 1
    INDEX=$(($(cat "$STATE_DIR/index" 2>/dev/null || echo 1) - 1))
    INDEX=$(((INDEX + TOTAL) % TOTAL))
    echo "$INDEX" > "$STATE_DIR/index"
    echo "${SONGS[$INDEX]}" > "$STATE_DIR/song"
    basename "${SONGS[$INDEX]}" .mp3 > "$STATE_DIR/display-name"
    kill "$(cat "$STATE_DIR/pid" 2>/dev/null)" 2>/dev/null
    pw-play "${SONGS[$INDEX]}" 2>/dev/null &
    echo $! > "$STATE_DIR/pid"
    _apply_volume
    echo "${SONGS[$INDEX]}"
    ;;
  play)
    INDEX="${2:-0}"
    mapfile -t SONGS < "$STATE_DIR/playlist" 2>/dev/null
    TOTAL=${#SONGS[@]}
    [[ $TOTAL -eq 0 ]] && exit 1
    echo "$INDEX" > "$STATE_DIR/index"
    echo "${SONGS[$INDEX]}" > "$STATE_DIR/song"
    basename "${SONGS[$INDEX]}" .mp3 > "$STATE_DIR/display-name"
    kill "$(cat "$STATE_DIR/pid" 2>/dev/null)" 2>/dev/null
    pw-play "${SONGS[$INDEX]}" 2>/dev/null &
    echo $! > "$STATE_DIR/pid"
    _apply_volume
    echo "${SONGS[$INDEX]}"
    ;;
  pause)
    pkill -STOP pw-play 2>/dev/null
    echo "paused"
    ;;
  resume)
    pkill -CONT pw-play 2>/dev/null
    echo "resumed"
    ;;
  toggle)
    if [[ -f "$STATE_DIR/paused" ]]; then
      rm "$STATE_DIR/paused"
      pkill -CONT pw-play 2>/dev/null
      echo "resumed"
    else
      touch "$STATE_DIR/paused"
      pkill -STOP pw-play 2>/dev/null
      echo "paused"
    fi
    ;;
  name)
    echo "$(basename "$(cat "$STATE_DIR/song" 2>/dev/null)" .mp3)"
    ;;
esac
