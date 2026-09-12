FROM debian:12-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    samba supervisor ca-certificates \
    && useradd --system --no-create-home --shell /usr/sbin/nologin nightglass \
    && printf '%s\n%s\n' 'Lumen-Archive-47!' 'Lumen-Archive-47!' \
        | smbpasswd -a -s nightglass \
    && mkdir -p /opt/nightglass /srv/research \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY targets/vault/smb.conf /etc/samba/smb.conf
COPY targets/vault/entrypoint.sh /usr/local/sbin/dawnstar-vault-entrypoint
COPY targets/vault/nightglass/README.txt /opt/nightglass/README.txt
COPY targets/vault/nightglass/prototype-spec.txt /opt/nightglass/prototype-spec.txt

RUN tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
      -czf /srv/research/nightglass-research.tar.gz \
      -C /opt/nightglass README.txt prototype-spec.txt \
    && chmod 0755 /usr/local/sbin/dawnstar-vault-entrypoint \
    && chmod 0555 /srv/research \
    && chmod 0444 /srv/research/nightglass-research.tar.gz

EXPOSE 445

ENTRYPOINT ["/usr/local/sbin/dawnstar-vault-entrypoint"]
