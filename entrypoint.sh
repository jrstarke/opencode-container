#!/bin/bash
set -e

if [ "$SKIP_FIREWALL" != "true" ] && [ -f /usr/local/bin/init-firewall.sh ]; then
  /usr/local/bin/init-firewall.sh
fi

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
