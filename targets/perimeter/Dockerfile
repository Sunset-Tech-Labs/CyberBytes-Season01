FROM debian:12-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssh-server vsftpd nginx-light python3 sudo supervisor rsyslog curl \
    iproute2 iputils-ping netcat-openbsd \
    && useradd -m -s /bin/bash nova \
    && useradd -m -s /bin/bash telemetry \
    && echo 'nova:Dawnstar2026!' | chpasswd \
    && passwd -l telemetry \
    && mkdir -p /run/sshd /srv/ftp /var/log/supervisor /var/run/vsftpd/empty \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY targets/perimeter/sshd_config /etc/ssh/sshd_config
COPY targets/perimeter/vsftpd.conf /etc/vsftpd.conf
COPY targets/perimeter/nginx.conf /etc/nginx/nginx.conf
COPY targets/perimeter/www/ /var/www/html/
COPY targets/perimeter/ftp/ /srv/ftp/
COPY targets/perimeter/telemetry.py /opt/dawnstar/telemetry.py
COPY targets/perimeter/supervisord.conf /etc/supervisor/conf.d/dawnstar.conf
COPY targets/perimeter/entrypoint.sh /usr/local/sbin/dawnstar-entrypoint

RUN chmod 0755 /usr/local/sbin/dawnstar-entrypoint \
    && chmod 0644 /opt/dawnstar/telemetry.py \
    && chmod -R a+rX /srv/ftp /var/www/html

EXPOSE 21 22 80 4040

ENTRYPOINT ["/usr/local/sbin/dawnstar-entrypoint"]
