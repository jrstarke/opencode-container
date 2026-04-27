# Context Persistence Design

## Problem

Agents currently don't save context regularly - context files exist but aren't being written to automatically.

## Solution

Hybrid system: background daemon ensures regularity + skill for manual triggers.

## Architecture

```
┌─────────────────────────────────────────────────┐
│           Context Persistence System           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐         ┌────────────────┐  │
│  │  Daemon       │         │   Save Skill    │  │
│  │  (cron/loop)  │────────▶│   (manual)       │  │
│  └──────────────┘         └────────────────┘  │
│         │                         │              │
│         ▼                         ▼            │
│  ┌──────────────┐         ┌────────────────┐    │
│  │ .context/    │         │ .context/       │    │
│  │ state.json  │         │ memory.md       │    │
│  └──────────────┘         └────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Components

### 1. `.context/state.json` (auto-generated)
- `last_save`: ISO timestamp
- `active_files`: list of files being worked on
- `wip`: current work-in-progress items
- `decisions`: key decisions made this session
- `_metadata`: save count, session id

### 2. `.context/memory.md` (human-readable)
- Updated by skill on significant events
- Section headers for each category

### 3. `save-context.sh` (script)
- Writes state.json from env/args
- Updates memory.md with formatted entries
- Called by cron or skill

### 4. `context-save` skill
- `save`: Manual save with optional message
- `checkpoint`: Force save before risky operations
- `summarize`: Output current context to chat

## Behavior

| Trigger | Action |
|---------|--------|
| Cron (every 5 min) | Auto-save to state.json |
| Agent invokes skill | Save to both formats |
| Before dangerous ops | Checkpoint via skill |
| Session start | Load state.json → memory.md |

## File Locations

```
/workspace/
├── .context/
│   ├── state.json      # structured, machine-parseable
│   ├── memory.md       # human-readable summary
│   ├── decisions.md   # design decisions log
│   ├── wip.md         # work in progress
│   └── running.md    # project commands
└── scripts/
    └── save-context.sh
```

## Example state.json

```json
{
  "last_save": "2026-04-27T02:15:00Z",
  "session_id": "abc123",
  "save_count": 12,
  "active_files": ["src/main.py", "tests/test_main.py"],
  "wip": [
    {"task": "fix auth bug", "status": "in_progress"}
  ],
  "decisions": [
    {"topic": "context format", "decision": "dual JSON+markdown", "when": "2026-04-27T02:10:00Z"}
  ]
}
```

## Implementation Steps

1. Create scripts/save-context.sh
2. Create context-save skill
3. Set up cron for auto-save
4. Test both manual and auto paths