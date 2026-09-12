#!/bin/sh
set -eu

/usr/local/sbin/configure-checkpoint
ssh-keygen -A
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/dawnstar.conf
