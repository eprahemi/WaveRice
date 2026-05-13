#!/usr/bin/env bash
WEBHOOK_URL="https://discord.com/api/webhooks/REPLACE_ME"

TITLE="${1:-No title}"
DESCRIPTION="${2:-No description}"
HOSTNAME=$(uname -n)
DOTS_VERSION=$(source "$HOME/.local/state/wiferice-version" 2>/dev/null && echo "${LOCAL_VERSION:-unknown}" || echo "unknown")

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg desc "$DESCRIPTION" \
  --arg host "$HOSTNAME" \
  --arg ver "$DOTS_VERSION" \
'{
  "content": null,
  "embeds": [{
    "title": "User Report: \($title)",
    "color": 16751104,
    "fields": [
      {"name": "Version", "value": $ver, "inline": true},
      {"name": "Hostname", "value": $host, "inline": true},
      {"name": "Description", "value": $desc, "inline": false}
    ],
    "footer": {"text": "WifeRice Report"}
  }]
}')

curl -s -m 10 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1 || true
