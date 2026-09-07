# CLAUDE.md

## Purpose

Claude Code dispatch entrypoint for `ai-skill-hub`.

This file is thin, dispatch-oriented, and reference-first. It is **not** the canonical source of truth.

## Repository Identity

`ai-skill-hub` is a multi-agent skill platform / AI capability system.

Its maintained assets are canonical skills, thin adapters, invocation contracts, indexes, tests, and automation utilities — not ordinary business application code.

## Required Canonical Reading

Before any implementation in this repository, read:

1. `README.md` — repository orientation and layout
2. `AGENTS.md` — project-side runtime master entrypoint
3. `SKILLS_INDEX.md` — cross-AI skill catalog with invocation overviews
4. `docs/ai/DISCOVERY_AND_INVOCATION.md` — AI discovery and invocation rules
5. `docs/ai/INVOCATION_PROTOCOL.md` — unified skill input/output contract
6. `docs/ai/EXECUTION_PROTOCOL.md` — SKILL.md execution and authoring reference
7. `docs/human/REPOSITORY_CONSUMPTION_GUIDE.md` — human-facing quick-start

## Optional Discovery Helpers

- `AI_USAGE.md` — compatibility entry and quick discovery guide; not canonical

## Layering

Critical repository layers:

- `skills/` — canonical source of truth; all real skill content lives here
- `.agents/skills/` — thin adapter layer; points back to `skills/`
- `.github/skills/` — Copilot fallback adapter layer; thin entries only
- `.codex/` — legacy compatibility surface; preserved, not canonical

Adapter files are discovery surfaces, not duplicate content.

If adapter guidance and canonical skill content conflict, `skills/<skill>/SKILL.md` wins.

## Operational Boundaries

- Default to read-only scanning and analysis.
- Do not modify router, pipeline, protocol, or existing skills without explicit authorization.
- Do not expand thin entry files such as `.agents/`, `.github/`, `AGENTS.md`, or this file into second rule libraries.
- Do not create hooks, automation, refactoring tasks, or skill rewrites without explicit authorization.
- Do not create project-side runtime pack files inside this hub unless explicitly requested.
- Do not treat this repository as an ordinary business code project.

## Local Validation

Follow the Python runtime contract in `AGENTS.md`. Use `repo-python` for direct repository Python workloads; `tools/run_local_checks.ps1` remains the aggregate validation entry and delegates its Python workloads to that broker.

```powershell
# Default smoke check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke

# Adapter consistency, hub mode
repo-python tools/check_adapter_consistency.py --mode hub

# Full validation
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks all
```

## Skill Invocation Quick Reference

- Discover: use `SKILLS_INDEX.md` or `.agents/skills/<skill>/SKILL.md`
- Invoke: follow `skills/_protocol/skill_invocation.md` and `docs/ai/INVOCATION_PROTOCOL.md`
- Execute: follow the target skill's `SKILL.md` execution steps, constraints, and risks
- Output: follow the target skill's required output contract and any shared protocol fields

## Conflict Resolution

If this file conflicts with any canonical document, the canonical document takes precedence.
