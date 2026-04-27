#!/bin/bash
set -e

if [ "$SKIP_FIREWALL" != "true" ] && [ -f /usr/local/bin/init-firewall.sh ]; then
  /usr/local/bin/init-firewall.sh
fi

if [ -f /home/appuser/.cron ]; then
  crontab /home/appuser/.cron
fi

service cron start

exec gosu appuser "$@"