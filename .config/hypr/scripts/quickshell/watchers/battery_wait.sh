#!/usr/bin/env bash
PIPE="/tmp/qs_battery_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null
trap 'rm -f "$PIPE"; kill $(jobs -p) 2>/dev/null; exit 0' EXIT INT TERM
udevadm monitor --subsystem-match=power_supply 2>/dev/null | grep --line-buffered "change" > "$PIPE" &
read -r _ < "$PIPE"
