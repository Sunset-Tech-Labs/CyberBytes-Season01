#!/bin/sh
set -eu

episode="${LAB_EPISODE:-}"
case "$episode" in
  01|02|03|04|05|06|07|08) ;;
  *)
    echo "LAB_EPISODE must be one of 01 through 08" >&2
    exit 64
    ;;
esac

if id checkpoint >/dev/null 2>&1; then
  userdel -r checkpoint
fi
rm -f /etc/sudoers.d/dawnstar-checkpoint

passwd -l telemetry >/dev/null
install -d -m 0755 -o telemetry -g telemetry /home/telemetry/bin
touch /home/telemetry/.bash_history
chown telemetry:telemetry /home/telemetry/.bash_history
chmod 0600 /home/telemetry/.bash_history

install -m 0600 -o root -g root \
  /opt/dawnstar/operations-access.conf /root/operations-access.conf
touch /root/.bash_history
chown root:root /root/.bash_history
chmod 0600 /root/.bash_history

rm -f /root/.ssh/authorized_keys

case "$episode" in
  04)
    echo 'telemetry:Telemetry-Resume!' | chpasswd
    ;;
  05|06|07|08)
    useradd -m -s /bin/bash checkpoint
    echo 'checkpoint:Dawnstar-Resume-Only!' | chpasswd
    printf '%s\n' 'checkpoint ALL=(root) NOPASSWD: ALL' \
      >/etc/sudoers.d/dawnstar-checkpoint
    chmod 0440 /etc/sudoers.d/dawnstar-checkpoint
    touch /home/checkpoint/.bash_history
    chown checkpoint:checkpoint /home/checkpoint/.bash_history
    chmod 0600 /home/checkpoint/.bash_history
    ;;
esac

case "$episode" in
  06|07|08)
    install -d -m 0700 -o root -g root /root/.ssh
    printf '%s\n' \
      'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINzPO/AbQ0WcjncPkMYsvF3vrEPTKbiHGcspykemxNeS PERSISTENCE-DEMO' \
      >/root/.ssh/authorized_keys
    chmod 0600 /root/.ssh/authorized_keys
    ;;
esac
