# Repository Consumption Guide

This document is the human-facing companion to the AI-facing discovery guide.

## What this repository is

`ai-skill-hub` is a local multi-agent skill platform. Its maintained outputs are canonical skills, thin adapters, invocation contracts, indexes, tests, and automation utilities.

## How to read the repository

- Start with the root `README.md` for repository orientation.
- Use `docs/HANDOFF.md` and `docs/status/skill-hub-status.md` when you need current system context.
- Read `skills/<skill>/README.md` for human-facing skill intent.
- Read `skills/<skill>/SKILL.md` only when you need the execution-facing contract.

## New maintainer quick-start

1. Run local checks first:
   - `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke`
2. For adapter consistency checks, pick the correct contract mode:
   - consumer project: `python tools/check_adapter_consistency.py --mode consumer`
   - `ai-skill-hub` repository: `repo-python tools/check_adapter_consistency.py --mode hub`
3. Treat `skills/` as source of truth; adapter layers are discovery surfaces.

## Compatibility note

The legacy root files remain in place. This human-layer guide exists so explanatory content has an explicit home without changing runtime or adapter behavior.
