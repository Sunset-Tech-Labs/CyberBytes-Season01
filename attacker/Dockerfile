FROM kalilinux/kali-rolling

# I've included both kali-tools-top10 and kali-linux-headless in the file
# Both may take longer to start up the container, so unless you plan a 
# persistent container, install the tools you need once inside a container
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        #kali-tools-top10 \  
        #kali-linux-headless \ 
        nmap \
        curl \
        jq \
        iproute2 \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        libcap2-bin \
    && setcap -r /usr/lib/nmap/nmap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]
