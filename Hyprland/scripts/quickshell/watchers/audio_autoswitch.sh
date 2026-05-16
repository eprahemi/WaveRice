#!/usr/bin/env bash

BUILT_IN_PATTERN="pci.*analog-stereo"
EXTERNAL_PATTERN="(headphone|headset|bluez|bluetooth|usb)"

pactl subscribe | while read -r event; do
  if echo "$event" | grep -q "server"; then
    continue
  fi

  sleep 0.3

  external=$(pactl list sinks short | grep -iE "$EXTERNAL_PATTERN" | head -1)

  if [ -n "$external" ]; then
    sink_name=$(echo "$external" | awk '{print $2}')
    current=$(pactl info | grep "Default Sink" | awk -F': ' '{print $2}')
    if [ "$sink_name" != "$current" ]; then
      pactl set-default-sink "$sink_name"
    fi
  else
    built_in=$(pactl list sinks short | grep -iE "$BUILT_IN_PATTERN" | head -1 | awk '{print $2}')
    if [ -n "$built_in" ]; then
      current=$(pactl info | grep "Default Sink" | awk -F': ' '{print $2}')
      if [ "$built_in" != "$current" ]; then
        pactl set-default-sink "$built_in"
      fi
    fi
  fi
done
