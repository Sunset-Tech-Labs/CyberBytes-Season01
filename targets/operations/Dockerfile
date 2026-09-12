FROM debian:12-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssh-server dovecot-imapd supervisor \
    iproute2 iputils-ping netcat-openbsd nmap smbclient curl \
    && useradd -m -s /bin/bash relay \
    && echo 'relay:OrbitRelay!' | chpasswd \
    && mkdir -p /home/relay/Maildir/cur /home/relay/Maildir/new \
        /home/relay/Maildir/tmp /run/sshd /var/log/supervisor \
    && chown -R relay:relay /home/relay/Maildir \
    && chmod 0700 /home/relay/Maildir /home/relay/Maildir/cur \
        /home/relay/Maildir/new /home/relay/Maildir/tmp \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY targets/operations/sshd_config /etc/ssh/sshd_config
COPY targets/operations/dovecot.conf /etc/dovecot/dovecot.conf
COPY targets/operations/supervisord.conf /etc/supervisor/conf.d/dawnstar.conf
COPY targets/operations/entrypoint.sh /usr/local/sbin/dawnstar-operations-entrypoint
COPY targets/operations/mail/1700000000.Mnightglass /home/relay/Maildir/new/1700000000.Mnightglass

RUN chmod 0755 /usr/local/sbin/dawnstar-operations-entrypoint \
    && chown relay:relay /home/relay/Maildir/new/1700000000.Mnightglass \
    && chmod 0600 /home/relay/Maildir/new/1700000000.Mnightglass

EXPOSE 22 143

ENTRYPOINT ["/usr/local/sbin/dawnstar-operations-entrypoint"]
