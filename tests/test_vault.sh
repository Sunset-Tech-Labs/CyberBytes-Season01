#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-vault"
compose=(docker compose -p "$project" -f compose.yaml)
started=0
anonymous_output="$(mktemp)"

cleanup() {
  rm -f "$anonymous_output"
  if [[ "$started" -eq 1 ]]; then
    "${compose[@]}" down -v --remove-orphans
  fi
}

wait_for_vault_ready() {
  local container_id status attempt
  container_id="$("${compose[@]}" ps -q vault)"

  for attempt in $(seq 1 30); do
    status="$(docker inspect --format '{{.State.Health.Status}}' "$container_id")"
    if [[ "$status" == "healthy" ]]; then
      return 0
    fi
    sleep 1
  done

  echo "vault did not become healthy within 30 seconds" >&2
  "${compose[@]}" logs vault >&2
  return 1
}

trap cleanup EXIT
started=1
"${compose[@]}" up -d --build operations vault
wait_for_vault_ready

"${compose[@]}" exec -T operations sh -ec '
  rm -f /tmp/nightglass-research.tar.gz
  smbclient //172.30.30.20/research \
    -U "nightglass%Lumen-Archive-47!" \
    -c "get nightglass-research.tar.gz /tmp/nightglass-research.tar.gz"
  test -s /tmp/nightglass-research.tar.gz
'

"${compose[@]}" exec -T operations sh -ec '
  archive=/tmp/nightglass-research.tar.gz
  tar -tzf "$archive" | grep -Fx "README.txt"
  tar -tzf "$archive" | grep -Fx "prototype-spec.txt"
  tar -xOzf "$archive" prototype-spec.txt |
    grep -F "DAWNSTAR-NIGHTGLASS-RETRIEVED"
'

set +e
"${compose[@]}" exec -T operations \
  smbclient //172.30.30.20/research -N -c 'ls' \
  >"$anonymous_output" 2>&1
anonymous_status=$?
set -e

if [[ "$anonymous_status" -eq 0 ]]; then
  echo "unauthenticated clients must not read the research share" >&2
  exit 1
fi

if ! grep -Fq 'NT_STATUS_ACCESS_DENIED' "$anonymous_output"; then
  echo "anonymous access failed without the expected access-denied response" >&2
  cat "$anonymous_output" >&2
  exit 1
fi
