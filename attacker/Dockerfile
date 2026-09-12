FROM kalilinux/kali-rolling AS episode-01
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    iproute2 iputils-ping libcap2-bin netcat-openbsd nmap \
    && setcap -r /usr/lib/nmap/nmap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM episode-01 AS episode-02
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl inetutils-ftp hydra openssh-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM episode-02 AS episode-03
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    metasploit-framework \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY attacker/metasploit/dawnstar_telemetry_exec.rb /root/.msf4/modules/exploits/linux/misc/dawnstar_telemetry_exec.rb

FROM episode-03 AS episode-04
COPY attacker/tools/lab-enum.sh /usr/local/bin/lab-enum
RUN chmod 0755 /usr/local/bin/lab-enum

FROM episode-04 AS episode-05
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    proxychains4 sshpass \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM episode-05 AS episode-06
FROM episode-06 AS episode-07
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    smbclient \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM episode-07 AS episode-08
CMD ["sleep", "infinity"]
