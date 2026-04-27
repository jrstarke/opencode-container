# Skill: context-save

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