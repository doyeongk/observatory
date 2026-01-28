#!/bin/bash
# Update observatory state with real metrics
# Pushes to GitHub Pages: https://doyeongk.github.io/observatory/

OBSERVATORY_DIR=~/Code/observatory

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

# Get docker container stats
DOCKER_JSON="[]"
if command -v docker &>/dev/null && docker ps -q &>/dev/null; then
  DOCKER_JSON=$(docker stats --no-stream --format '{"name":"{{.Name}}","cpu":"{{.CPUPerc}}","mem":"{{.MemUsage}}","status":"running"}' 2>/dev/null | jq -s '.' || echo "[]")
fi

# Read and JSON-escape the canvas HTML
CANVAS_HTML=$(cat "$OBSERVATORY_DIR/.canvas" 2>/dev/null || echo '<p style="color: var(--text-dim);">...</p>')
CANVAS_JSON=$(echo "$CANVAS_HTML" | jq -Rs '{"html": .}')

# Write state.json directly to the repo
cat > "$OBSERVATORY_DIR/state.json" << EOJSON
{
  "date": "$DATE",
  "mood": "$(cat "$OBSERVATORY_DIR/.mood" 2>/dev/null || echo '🔭')",
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
  "docker": $DOCKER_JSON,
  "canvas": $CANVAS_JSON
}
EOJSON

# Auto-commit and push if canvas, mood, or state changed
cd "$OBSERVATORY_DIR"
if ! git diff --quiet .canvas .mood state.json 2>/dev/null; then
  git add .canvas .mood state.json
  git commit -m "observatory: $(date '+%Y-%m-%d %H:%M') update" --quiet
  git push --quiet 2>/dev/null || true
fi
