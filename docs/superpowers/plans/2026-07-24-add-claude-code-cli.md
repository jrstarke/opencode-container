# Add Claude Code CLI Implementation Plan

## Goal
Install latest Claude Code CLI binary, create config directory, expose `claude` command.

## Tasks
1. **Dockerfile**: add download/extract of `claude` binary and create `/home/appuser/.claude/config` with correct ownership.
2. **entrypoint.sh**: add case for `claude` to exec via `gosu appuser`.
3. **Smoke test**: add script `test/claude_smoke_test.sh` that runs `claude --help` in built image.
