#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-perimeter"
compose=(docker compose -p "$project" -f compose.yaml)

cleanup() {
  "${compose[@]}" down -v --remove-orphans
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

trap cleanup EXIT
"${compose[@]}" up -d --build attacker perimeter
wait_for_perimeter_ready
"${compose[@]}" exec -T attacker bash -o errexit -o pipefail -lc '
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "21/tcp.*open"
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "22/tcp.*open"
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "80/tcp.*open"
  nmap -Pn -p 21,22,80,4040 172.30.10.10 | grep "4040/tcp.*closed"
  curl -fsS http://172.30.10.10/ | grep "Dawnstar Applied Sciences"
  curl -fsS ftp://172.30.10.10/staff.txt | grep "nova"
  curl -fsS ftp://172.30.10.10/password-policy.txt | grep "Dawnstar"
'
