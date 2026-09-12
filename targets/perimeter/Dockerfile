FROM debian:12-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssh-server vsftpd nginx-light python3 sudo supervisor rsyslog curl \
    iproute2 iputils-ping netcat-openbsd \
    && useradd -m -s /bin/bash nova \
    && useradd -m -s /bin/bash telemetry \
    && echo 'nova:Dawnstar2026!' | chpasswd \
    && passwd -l telemetry \
    && mkdir -p /home/telemetry/bin /run/sshd /srv/ftp /var/log/supervisor \
        /var/log/telemetry /var/run/vsftpd/empty \
    && chown -R telemetry:telemetry /home/telemetry/bin /var/log/telemetry \
    && touch /root/.bash_history /home/telemetry/.bash_history /var/log/auth.log \
    && chown telemetry:telemetry /home/telemetry/.bash_history \
    && chown root:adm /var/log/auth.log \
    && chmod 0600 /root/.bash_history /home/telemetry/.bash_history \
    && chmod 0640 /var/log/auth.log \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY targets/perimeter/sshd_config /etc/ssh/sshd_config
COPY targets/perimeter/vsftpd.conf /etc/vsftpd.conf
COPY targets/perimeter/nginx.conf /etc/nginx/nginx.conf
COPY targets/perimeter/www/ /var/www/html/
COPY targets/perimeter/ftp/ /srv/ftp/
COPY targets/perimeter/telemetry.py /opt/dawnstar/telemetry.py
COPY targets/perimeter/operations-access.conf /opt/dawnstar/operations-access.conf
COPY targets/perimeter/archive-telemetry /usr/local/sbin/archive-telemetry
COPY targets/perimeter/dawnstar-telemetry-sudoers /etc/sudoers.d/dawnstar-telemetry
COPY targets/perimeter/configure-checkpoint.sh /usr/local/sbin/configure-checkpoint
COPY targets/perimeter/supervisord.conf /etc/supervisor/conf.d/dawnstar.conf
COPY targets/perimeter/entrypoint.sh /usr/local/sbin/dawnstar-entrypoint

RUN chmod 0755 /usr/local/sbin/archive-telemetry \
        /usr/local/sbin/configure-checkpoint /usr/local/sbin/dawnstar-entrypoint \
    && chmod 0440 /etc/sudoers.d/dawnstar-telemetry \
    && chmod 0600 /opt/dawnstar/operations-access.conf \
    && chmod 0644 /opt/dawnstar/telemetry.py \
    && visudo -cf /etc/sudoers.d/dawnstar-telemetry \
    && chmod -R a+rX /srv/ftp /var/www/html

EXPOSE 21 22 80 4040

ENTRYPOINT ["/usr/local/sbin/dawnstar-entrypoint"]
