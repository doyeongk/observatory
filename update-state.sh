#!/bin/bash
# Update dashboard state with real metrics

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%
MEM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "N/A")
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# Get clawdbot info from process
GATEWAY_PID=$(pgrep -f clawdbot-gateway 2>/dev/null | head -1)
if [ -n "$GATEWAY_PID" ]; then
  UPTIME=$(ps -o etimes= -p "$GATEWAY_PID" 2>/dev/null | awk '{h=int($1/3600); m=int(($1%3600)/60); printf "%dh %dm", h, m}')
  # Count active session transcripts (rough proxy for session count)
  SESSIONS=$(find ~/.clawdbot/agents/main/sessions -name "*.jsonl" -mmin -1440 2>/dev/null | wc -l)
else
  UPTIME="offline"
  SESSIONS="0"
fi
DATE=$(date '+%A, %B %d')

# Read and JSON-escape the canvas HTML
CANVAS_HTML=$(cat ~/clawd/dashboard/.canvas 2>/dev/null || echo '<p class="text-gray-500">...</p>')
CANVAS_JSON=$(echo "$CANVAS_HTML" | jq -Rs '{"html": .}')

# Write to tmpfs (RAM), symlink from dashboard dir
STATE_FILE="/tmp/observatory-state.json"
cat > "$STATE_FILE" << EOJSON
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
    "sessions": "$SESSIONS",
    "lastActivity": "$(date '+%H:%M:%S')"
  },
  "canvas": $CANVAS_JSON
}
EOJSON

# Auto-commit only if canvas or mood changed (not stats)
cd ~/clawd/dashboard
if ! git diff --quiet .canvas .mood 2>/dev/null; then
  git add .canvas .mood
  git commit -m "observatory: $(date '+%Y-%m-%d %H:%M') update" --quiet
  git push --quiet 2>/dev/null || true
fi
