#!/usr/bin/env bash
set -euo pipefail

image="dawnstar-attacker-test"
docker build --target episode-08 -f attacker/Dockerfile -t "$image" .
docker run --rm "$image" bash -lc '
  command -v ip
  command -v ping
  command -v nmap
  command -v nc
  command -v curl
  command -v hydra
  command -v msfconsole
  command -v proxychains4
  command -v ssh
  command -v smbclient
  command -v lab-enum
'
