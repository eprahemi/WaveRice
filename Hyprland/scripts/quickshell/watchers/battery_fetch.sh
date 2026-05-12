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
        nohup pw-play "$file" >/dev/null 2>&1 ||
        nohup paplay "$file" >/dev/null 2>&1 ||
        nohup mpg123 --quiet "$file" >/dev/null 2>&1 ||
        nohup ffplay -nodisp -autoexit "$file" >/dev/null 2>&1 ||
        true
    )
}

# ─── CHARGER PLUG / UNPLUG SOUNDS ────────────────────────────────────
CHARGER_PLUG_SOUND="$HOME/.config/hypr/scripts/quickshell/battery/charger-plug-sound.mp3"
CHARGER_UNPLUG_SOUND="$HOME/.config/hypr/scripts/quickshell/battery/charger-unplug-sound.mp3"
PREV_STATUS_FILE="$WARN_DIR/prev_status"
PREV_STATUS=$(cat "$PREV_STATUS_FILE" 2>/dev/null || echo "")

if [ "$PREV_STATUS" != "$status" ] && [ -n "$PREV_STATUS" ]; then
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        _play_bat_sound "$CHARGER_PLUG_SOUND" &
    elif [ "$status" = "Discharging" ]; then
        _play_bat_sound "$CHARGER_UNPLUG_SOUND" &
    fi
fi
echo "$status" > "$PREV_STATUS_FILE"

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

    # 3% critical countdown + auto-suspend (backgrounded so TopBar JSON returns immediately)
    if [ "$percent" -le 3 ] && [ ! -f "$WARN_DIR/notified_3" ]; then
        touch "$WARN_DIR/notified_3"
        _play_bat_sound "$BAT_SOUND_53" &
        (
            for i in 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0; do
                [ $((i % 3)) -eq 0 ] && _play_bat_sound "$BAT_SOUND_53" &
                if [ "$i" -gt 20 ]; then URG="low"
                elif [ "$i" -gt 10 ]; then URG="normal"
                else URG="critical"; fi
                notify-send -u "$URG" -t 2000 "Battery Critical" "Laptop will suspend in ${i}s — plug in charger!" 2>/dev/null || true
                sleep 1
                CURRENT_STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
                if [ "$CURRENT_STATUS" != "Discharging" ]; then
                    rm -f "$WARN_DIR/notified_3"
                    break
                fi
            done
            STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
            if [ "$STATUS" = "Discharging" ]; then
                systemctl suspend 2>/dev/null || loginctl suspend 2>/dev/null || true
            fi
        ) &
    fi
else
    for threshold in 20 10 5 3; do
        [ "$percent" -gt "$threshold" ] && rm -f "$WARN_DIR/notified_$threshold"
    done
fi

jq -n -c --arg percent "$percent" --arg status "$status" --arg icon "$(get_battery_icon)" '{percent: $percent, status: $status, icon: $icon}'
