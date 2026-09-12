#!/bin/sh
set -eu

exec /usr/sbin/smbd --foreground --no-process-group
