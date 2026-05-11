#!/usr/bin/env bash
get_battery_percent() { LC_ALL=C cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"; }
get_battery_status() { LC_ALL=C cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo "Full"; }
get_battery_icon() {
    local percent=$(get_battery_percent)
    local status=$(get_battery_status)
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        if [ "$percent" -ge 90 ]; then echo "󰂅"
        elif [ "$percent" -ge 80 ]; then echo "󰂋"
        elif [ "$percent" -ge 60 ]; then echo "󰂊"
        elif [ "$percent" -ge 40 ]; then echo "󰢞"
        elif [ "$percent" -ge 20 ]; then echo "󰂆"
        else echo "󰢜"; fi
    else
        if [ "$percent" -ge 90 ]; then echo "󰁹"
        elif [ "$percent" -ge 80 ]; then echo "󰂂"
        elif [ "$percent" -ge 70 ]; then echo "󰂁"
        elif [ "$percent" -ge 60 ]; then echo "󰂀"
        elif [ "$percent" -ge 50 ]; then echo "󰁿"
        elif [ "$percent" -ge 40 ]; then echo "󰁾"
        elif [ "$percent" -ge 30 ]; then echo "󰁽"
        elif [ "$percent" -ge 20 ]; then echo "󰁼"
        elif [ "$percent" -ge 10 ]; then echo "󰁻"
        else echo "󰁺"; fi
    fi
}

# ─── LOW BATTERY WARNINGS + SOUNDS ──────────────────────────────────
percent=$(get_battery_percent)
status=$(get_battery_status)
WARN_DIR="/tmp/qs_battery_warn"
BAT_SOUND_2010="$HOME/.config/hypr/scripts/quickshell/battery/lowbattery20-10.mp3"
BAT_SOUND_53="$HOME/.config/hypr/scripts/quickshell/battery/lowbattery5.mp3"
mkdir -p "$WARN_DIR"

_play_bat_sound() {
    local file="$1"
    [ -f "$file" ] && (
        mpg123 --quiet "$file" 2>/dev/null ||
        ffplay -nodisp -autoexit "$file" 2>/dev/null ||
        true
    )
}

if [ "$status" = "Discharging" ]; then
    for threshold in 20 10 5; do
        [ "$percent" -gt "$threshold" ] && continue
        flag="$WARN_DIR/notified_$threshold"
        [ -f "$flag" ] && continue
        touch "$flag"
        case $threshold in
            20) _play_bat_sound "$BAT_SOUND_2010" &
                notify-send -u critical -t 5000 "Battery Low" "Battery at ${percent}% — consider charging" ;;
            10) _play_bat_sound "$BAT_SOUND_2010" &
                notify-send -u critical -t 8000 "Battery Very Low" "Only ${percent}% remaining — plug in soon!" ;;
            5)  _play_bat_sound "$BAT_SOUND_53" &
                notify-send -u critical -t 10000 "Battery Critical" "${percent}% — system will suspend soon!" ;;
        esac
    done
else
    for threshold in 20 10 5; do
        [ "$percent" -gt "$threshold" ] && rm -f "$WARN_DIR/notified_$threshold"
    done
fi

jq -n -c --arg percent "$percent" --arg status "$status" --arg icon "$(get_battery_icon)" '{percent: $percent, status: $status, icon: $icon}'
