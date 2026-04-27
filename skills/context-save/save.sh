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