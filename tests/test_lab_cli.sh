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

for required_text in \
  './scripts/lab up 1' \
  './scripts/lab reset 1' \
  './scripts/lab down 1' \
  'enclosed Docker lab' \
  'linux/amd64' \
  'linux/arm64' \
  'docs/episodes.md'; do
  if ! grep -Fq "$required_text" README.md; then
    printf 'README.md is missing required text: %s\n' "$required_text" >&2
    exit 1
  fi
done

episode_heading_count="$(grep -c '^## Episode ' docs/episodes.md)"
if [[ "$episode_heading_count" -ne 8 ]]; then
  printf 'Expected 8 episode headings, found %s\n' "$episode_heading_count" >&2
  exit 1
fi

if grep -Fq 'Episode 0' docs/episodes.md; then
  printf '%s\n' 'docs/episodes.md must not mention Episode 0' >&2
  exit 1
fi
