#!/bin/bash
set -e

if [ "$SKIP_FIREWALL" != "true" ] && [ -f /usr/local/bin/init-firewall.sh ]; then
  /usr/local/bin/init-firewall.sh
fi

if [ -n "$GIT_USER_NAME" ] || [ -n "$GIT_USER_EMAIL" ]; then
  gosu appuser git config --global user.name "$GIT_USER_NAME"
  gosu appuser git config --global user.email "$GIT_USER_EMAIL"
fi

exec gosu appuser "$@"
