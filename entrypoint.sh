#!/bin/bash
set -e

if [ "$SKIP_FIREWALL" != "true" ] && [ -f /usr/local/bin/init-firewall.sh ]; then
  /usr/local/bin/init-firewall.sh
fi

exec gosu appuser "$@"