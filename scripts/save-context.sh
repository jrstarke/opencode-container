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