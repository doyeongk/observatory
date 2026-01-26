#!/bin/bash
# Update dashboard state with real metrics

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%
MEM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "N/A")
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# Get clawdbot info
UPTIME=$(systemctl show clawdbot --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2 || echo "unknown")
DATE=$(date '+%A, %B %d')

# Read and JSON-escape the canvas HTML
CANVAS_HTML=$(cat ~/clawd/dashboard/.canvas 2>/dev/null || echo '<p class="text-gray-500">...</p>')
CANVAS_JSON=$(echo "$CANVAS_HTML" | jq -Rs '{"html": .}')

cat > ~/clawd/dashboard/state.json << EOJSON
{
  "date": "$DATE",
  "mood": "$(cat ~/clawd/dashboard/.mood 2>/dev/null || echo '🤖')",
  "pi": {
    "cpu": "$CPU",
    "memory": "$MEM",
    "temp": "$TEMP",
    "disk": "$DISK"
  },
  "clawdbot": {
    "uptime": "$UPTIME",
    "sessions": "1",
    "lastActivity": "$(date '+%H:%M:%S')"
  },
  "canvas": $CANVAS_JSON
}
EOJSON

# Auto-commit if there are changes
cd ~/clawd/dashboard
if ! git diff --quiet .canvas .mood state.json 2>/dev/null; then
  git add .canvas .mood state.json
  git commit -m "observatory: $(date '+%Y-%m-%d %H:%M') update" --quiet
  git push --quiet 2>/dev/null || true
fi
