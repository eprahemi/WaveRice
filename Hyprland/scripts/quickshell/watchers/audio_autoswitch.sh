#!/usr/bin/env bash

BUILT_IN_PATTERN="pci.*analog-stereo"
EXTERNAL_PATTERN="(headphone|headset|bluez|bluetooth|usb)"

# ─── HELPERS ──────────────────────────────────────────────────────────────

_external_sink() {
  pactl list sinks short | grep -iE "$EXTERNAL_PATTERN" | head -1 | awk '{print $2}'
}

_builtin_sink() {
  pactl list sinks short | grep -iE "$BUILT_IN_PATTERN" | head -1 | awk '{print $2}'
}

_default_sink() {
  pactl info | grep "Default Sink" | awk -F': ' '{print $2}'
}

_switch_to() {
  local target="$1"
  local current
  current="$(_default_sink)"
  [ "$target" != "$current" ] && pactl set-default-sink "$target"
}

# ─── APPLY ON STARTUP ────────────────────────────────────────────────────
# If an external sink is already connected when this script starts, switch to it

startup_external="$(_external_sink)"
if [ -n "$startup_external" ]; then
  _switch_to "$startup_external"
fi

# ─── EVENT LISTENER ──────────────────────────────────────────────────────
# Only react to sink 'new' (device plugged) and 'remove' (device unplugged).
# Sink 'change' events include user manual default-sink switches — we IGNORE
# those so users can freely choose between multiple connected devices.

pactl subscribe | while read -r raw_event; do
  # Parse: Event 'new' on sink #43
  read -r _ event_type _ object_type _ <<< "$raw_event"
  event_type="${event_type//\'/}"
  object_type="${object_type//\'/}"

  # Only react to sink add/remove
  if [ "$object_type" != "sink" ] || { [ "$event_type" != "new" ] && [ "$event_type" != "remove" ]; }; then
    continue
  fi

  sleep 0.3

  external="$(_external_sink)"

  if [ -n "$external" ]; then
    # At least one external device is present — switch to the first one
    _switch_to "$external"
  else
    # Last external was removed — revert to built-in
    built_in="$(_builtin_sink)"
    [ -n "$built_in" ] && _switch_to "$built_in"
  fi
done
