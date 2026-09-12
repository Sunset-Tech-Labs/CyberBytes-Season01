#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-vault"
compose=(docker compose -p "$project" -f compose.yaml)
started=0

cleanup() {
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

if "${compose[@]}" exec -T operations \
  smbclient //172.30.30.20/research -N -c 'ls'; then
  echo "unauthenticated clients must not read the research share" >&2
  exit 1
fi
