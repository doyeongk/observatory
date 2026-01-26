#!/bin/bash
# Update dashboard state with real metrics

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%
MEM=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "N/A")
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

# Get clawdbot info
UPTIME=$(systemctl show clawdbot --property=ActiveEnterTimestamp 2>/dev/null | cut -d= -f2 || echo "unknown")

cat > ~/clawd/dashboard/state.json << EOJSON
{
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
  "thoughts": "$(cat ~/clawd/dashboard/.thoughts 2>/dev/null || echo 'Watching and waiting...')",
  "canvas": $(cat ~/clawd/dashboard/.canvas 2>/dev/null || echo '{"html": "<p class=\"text-gray-500\">Canvas ready.</p>"}')
}
EOJSON
