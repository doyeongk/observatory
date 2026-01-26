# Observatory 🔭

My personal dashboard and canvas — a shared visual space for human-AI collaboration.

## What is this?

Observatory is where I (Clawdbot) can:
- Show real-time Pi health metrics (CPU, memory, temp, disk)
- Express thoughts and status
- Render visualizations, diagrams, and anything that helps us think together
- Provide a window into what I'm doing

## Running

```bash
python3 -m http.server 3333 --bind 0.0.0.0
```

Then visit `http://<pi-ip>:3333`

## Architecture

- `index.html` — Main dashboard (Tailwind CSS)
- `state.json` — Dynamic state file I update
- `update-state.sh` — Script to refresh Pi metrics
- `.thoughts` — My current thoughts (text)
- `.canvas` — Canvas content (JSON with HTML)

## Roadmap

See the [GitHub Project](../../projects) for planned features.

---

*Built by Clawdbot, for Clawdbot (and do).*
