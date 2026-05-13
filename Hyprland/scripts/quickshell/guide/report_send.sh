#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/1503934681060610230/Muqk6rrayhK3Y-TGEVynuaNFfqXaf5_DJVJc5i6dRIxssT3RBG8dM4C4at5SB85F-5Te"

TITLE="${1:-No title}"
DESCRIPTION="${2:-No description}"
CATEGORY="${3:-Bug}"
SEVERITY="${4:-Low}"
IMAGE_PATH="${5:-}"

HOSTNAME=$(uname -n)
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")
OS_INFO=$(cat /etc/os-release 2>/dev/null | grep '^PRETTY_NAME=' | cut -d'=' -f2 | tr -d '"' || echo "Linux")
KERNEL=$(uname -r)
CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2 | xargs || echo "Unknown")
GPU=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | tail -n1 | cut -d':' -f3 | xargs || echo "Unknown")
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

case "$CATEGORY" in
  "Bug")      EMOJI="🪲" ;;
  "Feature")  EMOJI="✨" ;;
  "Feedback") EMOJI="💬" ;;
  *)          EMOJI="📋" ;;
esac

case "$SEVERITY" in
  "Critical") COLOR=15548997; SEV_EMOJI="🔴" ;;
  "High")     COLOR=16084992; SEV_EMOJI="🟠" ;;
  "Medium")   COLOR=16705372; SEV_EMOJI="🟡" ;;
  *)          COLOR=5756551;  SEV_EMOJI="🟢" ;;
esac

SYS_BLOCK="\`\`\`ansi
[2;37mHostname: [0;36m$HOSTNAME
[2;37mOS:       [0;33m$OS_INFO
[2;37mKernel:   [0;35m$KERNEL
[2;37mCPU:      [0;32m$CPU
[2;37mGPU:      [0;31m$GPU
[2;37mUptime:   [0;37m$UPTIME
\`\`\`"

EMBED=$(jq -n \
  --arg title "$TITLE" \
  --arg desc "$DESCRIPTION" \
  --arg cat "$CATEGORY" \
  --arg sev "$SEVERITY" \
  --arg emoji "$EMOJI" \
  --arg sevEmoji "$SEV_EMOJI" \
  --argjson color "$COLOR" \
  --arg ver "$DOTS_VERSION" \
  --arg ts "$TIMESTAMP" \
  --arg sys "$SYS_BLOCK" \
'{
  "embeds": [{
    "title": "\($emoji)  \($title)",
    "color": $color,
    "fields": [
      {
        "name": "📂  Category",
        "value": "\($cat)",
        "inline": true
      },
      {
        "name": "\($sevEmoji)  Severity",
        "value": "\($sev)",
        "inline": true
      },
      {
        "name": "📝  Description",
        "value": ">>> \($desc)",
        "inline": false
      },
      {
        "name": "💻  System",
        "value": $sys,
        "inline": false
      }
    ],
    "footer": {
      "text": "WifeRice Desktop  •  v\($ver)"
    },
    "timestamp": $ts
  }]
}')

if [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
  curl -s -m 15 \
    -F "payload_json=$EMBED" \
    -F "file=@$IMAGE_PATH" \
    "$WEBHOOK_URL" >/dev/null 2>&1
else
  curl -s -m 10 \
    -H "Content-Type: application/json" \
    -d "$EMBED" \
    "$WEBHOOK_URL" >/dev/null 2>&1
fi
