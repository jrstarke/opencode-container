# Context Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement hybrid context persistence system with daemon + skill for regular agent context saves

**Architecture:** Shell script handles persistence with dual output (JSON + markdown). OpenCode skill provides manual triggers. Cron provides automatic periodicity.

**Tech Stack:** Bash shell scripts, JSON (jq), cron, OpenCode skill system

---

### Task 1: Create save-context.sh script

**Files:**
- Create: `scripts/save-context.sh`

**Environment:**
- Requires: `jq` for JSON manipulation
- Output files: `.context/state.json`, `.context/memory.md`

- [ ] **Step 1: Create scripts directory**

```bash
mkdir -p /workspace/scripts
```

- [ ] **Step 2: Write save-context.sh**

```bash
#!/bin/bash
# Context persistence script - saves state to both JSON and markdown

CONTEXT_DIR="/workspace/.context"
STATE_FILE="$CONTEXT_DIR/state.json"
MEMORY_FILE="$CONTEXT_DIR/memory.md"

# Get session info
SESSION_ID="${SESSION_ID:-$(date +%s)}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SAVE_COUNT=0

# Load existing state if exists
if [ -f "$STATE_FILE" ]; then
    SAVE_COUNT=$(jq -r '.save_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)
fi

# Parse arguments
MESSAGE="${1:-auto-save}"
ACTIVE_FILES="${2:-}"
WIP_ITEMS="${3:-[]}"
DECISIONS="${4:-[]}"

# Build state object
STATEOBJ=$(jq -n \
    --arg last_save "$TIMESTAMP" \
    --arg session_id "$SESSION_ID" \
    --argjson save_count $((SAVE_COUNT + 1)) \
    --arg active_files "$ACTIVE_FILES" \
    --argjson wip "$WIP_ITEMS" \
    --argjson decisions "$DECISIONS" \
    '{
        last_save: $last_save,
        session_id: $session_id,
        save_count: $save_count,
        active_files: ($active_files | split(",") | map(select(. != ""))),
        wip: $wip,
        decisions: $decisions
    }')

# Write state.json
echo "$STATEOBJ" | jq '.' > "$STATE_FILE"

# Update memory.md
{
    echo "# Session Memory"
    echo ""
    echo "**Last updated:** $TIMESTAMP"
    echo ""
    echo "## Current Session"
    echo ""
    echo "- Session ID: $SESSION_ID"
    echo "- Save count: $((SAVE_COUNT + 1))"
    echo ""
    echo "## Active Files"
    echo ""
    if [ -n "$ACTIVE_FILES" ]; then
        echo "$ACTIVE_FILES" | tr ',' '\n' | sed 's/^/- /'
    else
        echo "_None recorded_"
    fi
    echo ""
    echo "## Work in Progress"
    echo ""
    echo "$WIP_ITEMS" | jq -r '.[] | "- \(.task) [\(.status)]\n"' 2>/dev/null || echo "_None_"
    echo ""
    echo "## Recent Decisions"
    echo ""
    echo "$DECISIONS" | jq -r '.[] | "- \(.topic): \(.decision)\n"' 2>/dev/null || echo "_None_"
} > "$MEMORY_FILE"

echo "Context saved at $TIMESTAMP"
```

- [ ] **Step 3: Make script executable**

```bash
chmod +x /workspace/scripts/save-context.sh
```

- [ ] **Step 4: Verify jq is available**

```bash
which jq || apt-get update && apt-get install -y jq
```

- [ ] **Step 5: Test script**

```bash
cd /workspace && ./scripts/save-context.sh "test save" "test.py,test2.py" '[]' '[]'
cat .context/state.json
```

Expected: JSON with session data printed

- [ ] **Step 6: Commit**

```bash
git add scripts/save-context.sh .context/
git commit -m "feat: add save-context.sh script"
```

---

### Task 2: Create context-save skill

**Files:**
- Create: `skills/context-save/SKILL.md`
- Create: `skills/context-save/save.sh`

- [ ] **Step 1: Create skills directory**

```bash
mkdir -p /workspace/skills/context-save
```

- [ ] **Step 2: Write SKILL.md**

```markdown
# Skill: context-save

# Context Save Skill

Manual and checkpoint context saving for agents.

## Actions

### save
Save current context with optional message.

**Usage:** `context-save save "optional message"`

**Writes to:**
- `.context/state.json` (structured)
- `.context/memory.md` (human-readable)

### checkpoint
Force save before risky operations.

**Usage:** `context-save checkpoint`

Similar to save but marks as checkpoint in metadata.

### summarize
Output current context to terminal.

**Usage:** `context-save summarize`

Reads from `.context/state.json` and prints summary.

## Triggers

Invoke this skill when:
- User asks to save context
- Before dangerous operations (git reset --hard, force push)
- At natural breakpoints in workflow
- When context changes significantly

## Auto-save

For automatic saves, use cron:
```bash
*/5 * * * * /workspace/scripts/save-context.sh "auto-save" "" "[]" "[]"
```
```

- [ ] **Step 3: Write save.sh helper**

```bash
#!/bin/bash
# context-save skill helper

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT_SCRIPT="$SCRIPT_DIR/../../scripts/save-context.sh"

ACTION="$1"
shift

# Get active files from git or simple list
ACTIVE_FILES="${ACTIVE_FILES:-$(git ls-files 2>/dev/null | head -5 | tr '\n' ',')}"

case "$ACTION" in
    save)
        MESSAGE="${1:-manual-save}"
        ACTIVE_FILES="$2" # Optional: pass specific files
        "$CONTEXT_SCRIPT" "$MESSAGE" "${ACTIVE_FILES:-}" "[]" "[]"
        ;;
    checkpoint)
        MESSAGE="checkpoint: ${1:-}"
        "$CONTEXT_SCRIPT" "$MESSAGE" "${ACTIVE_FILES:-}" "[]" "[]"
        echo "Checkpoint saved"
        ;;
    summarize)
        if [ -f "/workspace/.context/state.json" ]; then
            cat /workspace/.context/state.json | jq '.'
        else
            echo "No context found"
        fi
        ;;
    *)
        echo "Usage: context-save {save|checkpoint|summarize}"
        ;;
esac
```

- [ ] **Step 4: Make save.sh executable**

```bash
chmod +x /workspace/skills/context-save/save.sh
```

- [ ] **Step 5: Test skill**

```bash
/workspace/skills/context-save/save.sh summarize
```

Expected: JSON state printed

- [ ] **Step 6: Commit**

```bash
git add skills/context-save/
git commit -m "feat: add context-save skill"
```

---

### Task 3: Set up cron for auto-save

**Files:**
- Create: `cron/context-save` (cron job file)

- [ ] **Step 1: Create cron directory**

```bash
mkdir -p /workspace/cron
```

- [ ] **Step 2: Create cron job file**

```bash
# Auto-save context every 5 minutes
*/5 * * * * appuser /workspace/scripts/save-context.sh "auto-save" "" "[]" "[]" >> /tmp/context-save.log 2>&1
```

- [ ] **Step 3: Install cron job**

```bash
crontab /workspace/cron/context-save
```

- [ ] **Step 4: Verify cron is running**

```bash
crontab -l
```

Expected: Shows the context-save cron entry

- [ ] **Step 5: Commit**

```bash
git add cron/
git commit -m "feat: add cron for auto-save"
```

---

### Task 4: Integration test

**Files:**
- Test: All created files

- [ ] **Step 1: Manual save via skill**

```bash
/workspace/skills/context-save/save.sh save "integration test"
```

- [ ] **Step 2: Verify JSON output**

```bash
cat /workspace/.context/state.json | jq '.'
```

Expected: save_count incremented, timestamp updated

- [ ] **Step 3: Verify markdown output**

```bash
cat /workspace/.context/memory.md
```

Expected: Human-readable output with timestamp

- [ ] **Step 4: Verify both files exist**

```bash
ls -la /workspace/.context/
```

Expected: state.json and memory.md both present

- [ ] **Step 5: Summarize via skill**

```bash
/workspace/skills/context-save/save.sh summarize
```

Expected: Full context printed to terminal

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "test: verify context persistence integration"
```

---

**Plan complete.**