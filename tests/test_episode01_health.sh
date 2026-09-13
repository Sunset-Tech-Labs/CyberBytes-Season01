#!/usr/bin/env bash
set -euo pipefail

project="dawnstar-test-episode01-health"
compose=(
  docker compose
  -p "$project"
  -f compose.yaml
  -f episodes/compose.episode-01.yaml
)

cleanup() {
  "${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

"${compose[@]}" up -d --build attacker
container_id="$("${compose[@]}" ps -q attacker)"

for _ in $(seq 1 30); do
  status="$(docker inspect --format '{{.State.Health.Status}}' "$container_id")"
  if [[ "$status" == "healthy" ]]; then
    exit 0
  fi
  if [[ "$status" == "unhealthy" ]]; then
    break
  fi
  sleep 1
done

echo "Episode 1 attacker did not become healthy" >&2
docker inspect --format '{{json .State.Health}}' "$container_id" >&2
exit 1
