# Dawnstar Applied Sciences Cyber Range

This repository is the companion lab for the eight-episode Sunset Tech Labs Cyber Bytes Season 1 playlist. It contains a deliberately vulnerable, fictional research environment built for learning introductory red-team techniques. The season follows a single mission involving Dawnstar Applied Sciences and Project Nightglass.

See the [episode guide](docs/episodes.md) for the spoiler-light learning objectives and the starting command for each episode.

## Safety and authorization

Use the techniques in this repository only inside this enclosed Docker lab or on systems where you have explicit authorization. Never scan, probe, exploit, persist on, or access a system merely because it is reachable. The credentials, organization, systems, weaknesses, and research data in this range are fictional training material.

The range uses internal Docker networks and does not publish target ports to the host. It does not require privileged containers, a Docker socket mount, or a host data mount. Those controls reduce accidental exposure, but they do not replace responsible use. Stop the lab when you finish.

## Prerequisites

- Git
- Docker Engine with the Docker Compose v2 plugin, or Docker Desktop
- Enough local disk space for Kali, Debian, Metasploit, and service packages
- A terminal capable of running Bash scripts
- Basic familiarity with Linux, TCP/IP networking, Docker, authorization, and lab safety

The images are designed for both `linux/amd64` and `linux/arm64`, including Intel/AMD Linux systems and Apple Silicon through Docker Desktop. The current release gate cross-builds both platforms under emulation on Apple Silicon. A native Intel/AMD smoke test is still required before a public release. All images build locally; no prebuilt Dawnstar image is required.

## Get started

Clone this repository, enter its root directory, and confirm Docker is available:

```bash
git clone YOUR_REPOSITORY_URL
cd CyberBytes-Season01
docker version
docker compose version
```

Build and start Episode 1:

```bash
./scripts/lab up 1
```

The first build downloads base images and installs Kali, Metasploit, and the target services. It can consume several gigabytes and may take a while depending on the computer, network, and Docker cache. Later starts normally reuse cached layers.

Open a shell in the Episode 1 attacker container:

```bash
docker compose \
  -p dawnstar-e01 \
  -f compose.yaml \
  -f episodes/compose.episode-01.yaml \
  exec attacker bash
```

## Lab commands

Every command accepts one episode number from 1 through 8. Each episode uses a separate Compose project and an immutable starting checkpoint.

Because every episode uses the same fixed lab subnets, stop the current episode with `./scripts/lab down EPISODE_NUMBER` before starting a different one. Running two episodes at once causes a Docker subnet conflict.

```bash
./scripts/lab build 1   # build without starting
./scripts/lab up 1      # build and start in the background
./scripts/lab status 1  # show container status and health
./scripts/lab config 1  # render the effective Compose configuration
./scripts/lab reset 1   # remove state and recreate the checkpoint
./scripts/lab down 1    # stop and remove the episode containers
```

Use `reset` at the start of a video or whenever you want a known-good state. Reset removes the selected episode's container state and anonymous volumes before rebuilding and starting it again.

## Architecture and containment

The range has four containers on three internal bridge networks:

```text
Kali attacker ── DMZ ── Perimeter ── Operations LAN ── Operations ── Research LAN ── Vault
```

- The Kali attacker connects only to the DMZ.
- Perimeter connects the DMZ to the Operations LAN, but not to the Research LAN.
- Operations connects the Operations LAN to the Research LAN.
- Vault connects only to the Research LAN.

This layout makes the internal systems unreachable directly from Kali and gives each pivot in the season a concrete purpose. No target port is exposed to the host.

Inspect the fully merged Episode 1 model before starting it:

```bash
docker compose \
  -p dawnstar-e01 \
  -f compose.yaml \
  -f episodes/compose.episode-01.yaml \
  config
```

In the rendered services, confirm there is no `ports:` mapping, `privileged: true`, `/var/run/docker.sock`, or host bind mount. Docker `EXPOSE` metadata documents an internal service; it does not publish that service to the host.

## Troubleshooting and clean reset

Check health and recent output first:

```bash
./scripts/lab status 1
docker compose \
  -p dawnstar-e01 \
  -f compose.yaml \
  -f episodes/compose.episode-01.yaml \
  logs
```

If a command fails after you changed files or container state, restore the episode checkpoint:

```bash
./scripts/lab reset 1
```

If Docker reports an address conflict, stop other projects using the `172.30.10.0/24`, `172.30.20.0/24`, or `172.30.30.0/24` subnets, then reset the episode. If a build was interrupted, rerun `./scripts/lab build 1`; Docker will reuse completed layers where possible.

When finished, remove the episode environment:

```bash
./scripts/lab down 1
```

Do not add host port mappings as a troubleshooting shortcut. They would weaken the lab's containment model.
