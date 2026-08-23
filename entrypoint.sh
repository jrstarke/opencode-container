#!/bin/bash
set -e

if [ "$SKIP_FIREWALL" != "true" ] && [ -f /usr/local/bin/init-firewall.sh ]; then
  /usr/local/bin/init-firewall.sh
fi

# ~/.claude is a named volume that persists across --rm runs, which is only
# actually wanted for one thing: the OAuth credentials in
# ~/.claude/.credentials.json, without which every run would need a fresh
# browser login. Everything else under ~/.claude either drifts from the
# image (CLAUDE.md/settings.json/plugins get silently shadowed by whatever
# the volume captured the first time it was created — a rebuild changes
# nothing at runtime until this fix) or leaks across unrelated host projects
# (memory, session history, file-history/backups of edited files, prompt
# history — all keyed by container path, so every different host project run
# through this sandbox shares one bucket since they all mount to /workspace).
# Allowlist rather than enumerate the leaky parts: anything new Claude Code
# starts writing under ~/.claude in a future version defaults to wiped, not
# silently persisted.
find /home/appuser/.claude -mindepth 1 -maxdepth 1 ! -name .credentials.json -exec rm -rf {} +
cp -r /opt/sandbox-seed/CLAUDE.md /opt/sandbox-seed/settings.json /opt/sandbox-seed/plugins /home/appuser/.claude/
chown -R appuser:appuser /home/appuser/.claude

if [ -n "$GIT_USER_NAME" ] || [ -n "$GIT_USER_EMAIL" ]; then
  gosu appuser git config --global user.name "$GIT_USER_NAME"
  gosu appuser git config --global user.email "$GIT_USER_EMAIL"
fi

case "$1" in
  opencode)
    shift
    exec gosu appuser opencode "$@"
    ;;
  agy)
    shift
    exec gosu appuser agy "$@"
    ;;
  *)
    exec gosu appuser "$@"
    ;;
esac
