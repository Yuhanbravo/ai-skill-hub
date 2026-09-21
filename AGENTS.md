# AGENTS.md

## Repository Role

`ai-skill-hub` is the canonical capability repository for shared AI skills. It maintains canonical skill definitions, thin discovery adapters, invocation protocols, indexes, validation tests, and bounded maintenance tools; it is not a business application repository.

This file is the repository-level agent entrypoint. Keep it stable, dispatch-oriented, and reference-first. Mutable phase, validation, blocker, and next-step facts belong in `docs/status/skill-hub-status.md` and `docs/HANDOFF.md`, not here.

## Read First

Before implementation, read the entries relevant to the task:

1. `README.md` and `SKILLS_INDEX.md` for repository orientation and catalog navigation.
2. `docs/ai/DISCOVERY_AND_INVOCATION.md`, `docs/ai/INVOCATION_PROTOCOL.md`, and `docs/ai/EXECUTION_PROTOCOL.md` for discovery, invocation, and authoring ownership.
3. `skills/_protocol/skill_invocation.md` before invoking a skill.
4. The selected `skills/<skill-id>/SKILL.md` in full, followed by every supporting resource required for that execution.
5. `docs/status/skill-hub-status.md` and `docs/HANDOFF.md` when current system state, closure, or next-phase direction matters.
6. The active task package and its referenced evidence when bounded implementation is authorized.

Historical task packages and reports are evidence only. Do not treat an old “current task,” phase, or pilot field as present authorization.

## Authority and Layering

- User instructions and the applicable task package define the current goal and write authorization.
- `skills/` is the sole canonical source for reusable skill behavior and supporting assets.
- `docs/ai/` owns repository invocation, discovery, and execution-authoring protocols.
- `.agents/skills/` and `.github/skills/` are derivative discovery surfaces. They must remain thin and must not become authoring sources.
- `docs/status/skill-hub-status.md` plus `docs/HANDOFF.md` are the declared current-state SSOT pair for mutable system facts.
- Consumer repositories own their project-specific governance, business rules, task packages, validation, status, handoff, and evidence.
- Bridge or mirror documents remain derivative exchange surfaces; verify their stated owner before relying on them.

Apply authority by subject. Canonical skill guidance owns reusable method; project and task sources own project facts and authorization. If two applicable sources make an irreconcilable claim about the same subject, pause only the dependent action and report the conflict.

## Working Boundaries

- Default to read-only inspection until the current task explicitly authorizes writes.
- Keep adapters and agent entrypoints thin; do not copy canonical skill bodies or create a second rule library.
- Do not modify routers, resolvers, shared protocols, skill behavior, distribution surfaces, automation, or CI unless the task explicitly includes them.
- Do not turn historical Runtime Pack assets into the default consumer model. Preserve their existing compatibility contract unless a separate task changes it.
- Do not infer rollout, deployment, or consumer-repository write authority from Hub documentation work.
- Reusable guidance belongs in canonical Hub assets; consumer-specific facts must stay in the consumer repository.

## Python Runtime and Validation

ASH owns what repository workload to run; AI_Workbench owns which Python executes it.

- Use `repo-python` for every repository Python workload.
- Do not select Python through `PATH`, `py`, Conda activation or environment names, or an absolute interpreter path.
- If the Runtime Broker cannot resolve this repository, fail closed; do not guess or repair an environment.
- Do not install, upgrade, or remove dependencies during ordinary work.

`tools/run_local_checks.ps1` is the aggregate local validation entrypoint and delegates Python workloads to `repo-python`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke
```

Choose the smallest existing check set that covers the change. Direct Python checks must also use `repo-python`. Validation proves only the checks actually run; it is not deployment, publication, or independent acceptance.

## Hub Routing and Task Closure

- Inside this Hub checkout, repository-relative `skills/<skill-id>/...` paths are valid canonical references.
- For consumers using the default `AI_LEVEL_CONFIG_BACK_REFERENCE` mode, entries declare logical Skill IDs only. They discover the user-level `ai-skill-hub-router`, read the neutral locator, use the resolver, and accept only `RESOLVED` before reading the returned canonical entry. These entries must not store a machine-specific Hub checkout path, canonical payload copy, or project commit pin.
- Existing consumers that have not migrated from the frozen Project Runtime Pack contract keep their project `.ai/runtime-pack.json`, project routers, commit pinning, and pinned/portable validation. Do not replace those surfaces through ordinary entrypoint maintenance; a mode change requires a separately authorized migration and evidence.
- The two modes are not fallbacks for one another. A back-reference routing failure stops that Skill invocation and is not repaired by using a Runtime Pack, copied text, or model memory.
- A Required-Skills list is an availability requirement for real workflows, not an automatic invocation list, selector, or write allowlist.
- Record per-task facts in the designated task package and execution report. Update the status/handoff SSOT only when the task explicitly requires a current-state refresh.
- Distinguish implementation, self-validation, independent review, publication, deployment, rollback, and final closure; do not collapse them into one status.
