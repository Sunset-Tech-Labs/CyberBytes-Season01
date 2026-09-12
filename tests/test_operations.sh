#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-operations"
compose=(docker compose -p "$project" -f compose.yaml)
started=0

cleanup() {
  if [[ "$started" -eq 1 ]]; then
    "${compose[@]}" down -v --remove-orphans
  fi
}

wait_for_operations_ready() {
  local container_id status attempt
  container_id="$("${compose[@]}" ps -q operations)"

  for attempt in $(seq 1 30); do
    status="$(docker inspect --format '{{.State.Health.Status}}' "$container_id")"
    if [[ "$status" == "healthy" ]]; then
      return 0
    fi
    sleep 1
  done

  echo "operations did not become healthy within 30 seconds" >&2
  "${compose[@]}" logs operations >&2
  return 1
}

trap cleanup EXIT
started=1
"${compose[@]}" up -d --build perimeter operations
wait_for_operations_ready

"${compose[@]}" exec -T perimeter sh -ec '
  nc -z -w 3 172.30.20.20 22
  nc -z -w 3 172.30.20.20 143
  curl --fail --silent --show-error \
    --url imap://172.30.20.20/INBOX \
    --user "relay:OrbitRelay!" >/dev/null

  message="$(curl --fail --silent --show-error \
    --url "imap://172.30.20.20/INBOX/;UID=1" \
    --user "relay:OrbitRelay!")"
  printf "%s\n" "$message" | grep -F "nightglass"
  printf "%s\n" "$message" | grep -F "Lumen-Archive-47!"
  printf "%s\n" "$message" | grep -F "172.30.30.20"
'

"${compose[@]}" exec -T operations sh -ec '
  if nc -z -w 1 172.30.30.10 22; then
    echo "SSH must not listen on the Research address" >&2
    exit 1
  fi
  if nc -z -w 1 172.30.30.10 143; then
    echo "IMAP must not listen on the Research address" >&2
    exit 1
  fi
'
