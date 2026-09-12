#!/bin/sh
set -eu

case "${LAB_EPISODE:-}" in
  01|02|03|04|05|06|07|08) ;;
  *)
    echo "LAB_EPISODE must be one of 01 through 08" >&2
    exit 64
    ;;
esac

ssh-keygen -A
rsyslogd
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/dawnstar.conf
