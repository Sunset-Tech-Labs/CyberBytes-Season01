# Cyber Bytes Season 1 Episode Guide

Season 1 follows one continuous fictional mission against Dawnstar Applied Sciences. Each checkpoint is independent, so you can begin any episode without replaying earlier material. Students are responsible for prerequisite Linux, networking, Docker, authorization, and safety research before following the exercises.

All techniques are for the deliberately vulnerable, enclosed Docker range only. Start an episode with its reset command to get the intended clean checkpoint.

## Episode 1 — Finding and Mapping the Hidden Lab

Learn how to orient yourself from the Kali attacker, inspect its network context, discover the reachable Dawnstar system, and turn host and service discovery into a useful first map of the environment.

```bash
./scripts/lab reset 1
```

## Episode 2 — The Perimeter Speaks

Practice service detection and focused enumeration across FTP, SSH, and a small web surface. Correlate ordinary-looking clues and compare careful credential testing with noisier password attacks.

```bash
./scripts/lab reset 2
```

## Episode 3 — Breaking In Without a Password

Explore a custom network service, reason about how its input is handled, and compare a transparent manual technique with a repeatable framework-assisted approach to the same controlled foothold.

```bash
./scripts/lab reset 3
```

## Episode 4 — From Service Account to Root

Turn a limited service account into a structured host investigation. Compare manual and automated enumeration, identify a dangerous maintenance configuration, and use it to demonstrate Linux privilege escalation.

```bash
./scripts/lab reset 4
```

## Episode 5 — Opening the Door to Operations

Examine reversible persistence, find internal network clues, and learn why multi-homed systems matter. Build a controlled tunnel through the perimeter and use it to reach Dawnstar's Operations tier.

```bash
./scripts/lab reset 5
```

## Episode 6 — You've Got Secret Mail

Enumerate the Operations host and interact with an internal mail service. See how credential reuse and sensitive plaintext messages can transform one compromised system into the next lead in an attack chain.

```bash
./scripts/lab reset 6
```

## Episode 7 — Cracking Open the Research Vault

Discover the Research LAN from the correct foothold, investigate an internal file service, and apply information gathered earlier to retrieve and stage the fictional Project Nightglass objective.

```bash
./scripts/lab reset 7
```

## Episode 8 — Getting the Research Out

Complete the mission by moving the staged research archive through the established route and verifying its integrity. Then examine cleanup, limited defense evasion, and the evidence an operation still leaves behind.

```bash
./scripts/lab reset 8
```
