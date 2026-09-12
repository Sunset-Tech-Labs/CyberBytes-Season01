#!/usr/bin/env bash
set -u
printf '%s\n' '== Identity ==' && id
printf '%s\n' '== Kernel ==' && uname -a
printf '%s\n' '== Interfaces ==' && ip -brief address
printf '%s\n' '== Routes ==' && ip route
printf '%s\n' '== Listening sockets ==' && ss -lntup
printf '%s\n' '== Sudo rights ==' && sudo -n -l 2>&1
printf '%s\n' '== SUID files =='
find / -xdev -perm -4000 -type f 2>/dev/null | sort
printf '%s\n' '== Root-owned writable path components =='
find /usr/local /opt -maxdepth 3 -user root -writable 2>/dev/null | sort
