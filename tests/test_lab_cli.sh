#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stub_dir="$(mktemp -d)"
docker_log="$stub_dir/docker.log"
cleanup() { rm -rf "$stub_dir"; }
trap cleanup EXIT

cat >"$stub_dir/docker" <<'EOF'
#!/usr/bin/env bash
printf 'docker' >>"$DOCKER_LOG"
printf ' %q' "$@" >>"$DOCKER_LOG"
printf '\n' >>"$DOCKER_LOG"
EOF
chmod +x "$stub_dir/docker"

export DOCKER_LOG="$docker_log"
export PATH="$stub_dir:$PATH"

cd "$repo_root"
./scripts/lab config 5
expected='docker compose -p dawnstar-e05 -f compose.yaml -f episodes/compose.episode-05.yaml config'
[[ "$(cat "$docker_log")" == "$expected" ]]

assert_rejected_without_docker() {
  : >"$docker_log"
  if ./scripts/lab "$@" >/dev/null 2>&1; then
    printf 'Expected command to fail: ./scripts/lab' >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
    exit 1
  fi
  if [[ -s "$docker_log" ]]; then
    printf 'Rejected command unexpectedly invoked Docker: %s\n' "$(cat "$docker_log")" >&2
    exit 1
  fi
}

assert_rejected_without_docker config 0
assert_rejected_without_docker config 9
assert_rejected_without_docker config
assert_rejected_without_docker destroy 5
