#!/bin/sh
set -eu

ssh-keygen -A
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/dawnstar.conf
