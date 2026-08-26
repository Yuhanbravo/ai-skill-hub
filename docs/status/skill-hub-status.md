# Skill Hub Status

- Updated at: `2026-08-26`
- Scope: `ai-skill-hub`
- Method: `system-status-update` wrapper over `update-project-status`
- Config: `.codex/skill-config/update-project-status.json`
- Data sources: Git history through current observed local `main` HEAD `240f74d1d00c39cb2a6485a3e1af9197e77802b9` (local `main` carries the frozen universal-routing line, ahead of `origin/main`), working tree, `skills/`, `.agents/`, `.github/`, `tools/`, `docs/status/`, `docs/HANDOFF.md`, historical Consumer Adoption Pilot evidence, and the Project Runtime Pack MVP V1 closure records.
- Note: the `2026-08-25` refresh froze the concrete `AI_LEVEL_CONFIG_BACK_REFERENCE_V1` contract under the already-frozen Consumer Adoption Architecture V1 and recorded the universal-routing remediation state; it did not reopen or rewrite any historical pilot evidence.
- Note: this refresh (`2026-08-26`) records the `ASH_STALE_ROUTER_RECONCILIATION_V1` closure (docs + tests only; frozen resolver semantics unchanged) and meets the 14-day freshness gate against the `2026-08-25` baseline.

## Project Runtime Pack MVP V1

- Work item: `ASH-PROJECT-RUNTIME-PACK-MVP-V1`.
- Status: `CLOSED_REMOTE_PUBLISHED_WITH_NOTES`.
- Decision: `PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_REMOTE_PUBLICATION_AND_FINAL_CLOSURE`.
- Design: `FROZEN`; Implementation: `COMPLETE`; Remediation: `COMPLETE`; Heterogeneous Validation: `PASS_WITH_NOTES`; Local Closure: `PASS_WITH_NOTES`; Remote Publication: `PASS`.
- Commit chain: design `d4d735e0`, implementation `7c8e54c`, remediation `1f01ab2`; current implementation HEAD `1f01ab256401d72cf23214c99688dc1d17ae9bb7`.
- Published commit: `4e3366c3d2e605fb64cfcf31f2cad3d780ecbfd1`; post-push local `main` == `origin/main` == actual remote `4e3366c3...` with ahead/behind `0 0`; no force push.
- Local `origin/main` ahead/behind at closure baseline: `0 3` (local remote-tracking ref; no fetch performed).
- Core evidence: initializer suite `112 passed x 3`; submodule-failure `20/20`; concurrency `20/20`; real-index pre-swap unchanged; rollback exact restoration PASS; current-HEAD fixture PASS; Codex E2E PASS; Kimi E2E PASS.
- Findings: F-01 ~ F-07, F-09 `CLOSED`; F-08 `CLOSED_TEST_HARDENED`; F-10 ~ F-15 `DEFERRED_NONBLOCKING_V1_NOTE` (substance preserved in the final closure report).
- Known notes (not hidden): pre-existing `codex-user-skills-bootstrap` MAX_PATH baseline (`smoke` 7/8, `all` 9/10; not introduced or expanded by this work item); Copilot workspace-root authenticated fresh-conversation E2E not literally verified (routing chain verified by real-artifact walkthrough plus Codex/Kimi cross-check; native Skill picker registration non-blocking); Claude Code authenticated E2E not performed (non-blocking); `file://` local fixture requires `protocol.file.allow=always` under current Git security defaults (local test fixture limitation only).
- Artifacts: `tools/init_project_runtime_pack.ps1`, `tools/project_runtime_pack_schema_v1.json`, `tests/test_init_project_runtime_pack.py`, and the task records in `tasks/`.
- Deferred next actions (future independent work items only): optional authenticated Copilot workspace-root verification; optional Claude Code authenticated E2E; separate MAX_PATH baseline remediation; deferred minor hardening for F-10 ~ F-15. The former consumer-project-pilot action is superseded by Consumer Adoption Architecture V1.

```text
Project_Runtime_Pack_MVP_V1=
CLOSED_REMOTE_PUBLISHED_WITH_NOTES

Decision=
PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_REMOTE_PUBLICATION_AND_FINAL_CLOSURE

Design=
FROZEN

Implementation=
COMPLETE

Remediation=
COMPLETE

Heterogeneous_Validation=
PASS_WITH_NOTES

Remote_Publication=
PASS

Published_Commit=
4e3366c3d2e605fb64cfcf31f2cad3d780ecbfd1

Current_Implementation_HEAD=
1f01ab256401d72cf23214c99688dc1d17ae9bb7
```

## Codex User Skills Bootstrap V1 Closure

## Codex User Skills Bootstrap V1 Closure

- Bootstrap V1 status: `FULLY_CLOSED`.
- Implementation: `MERGED_AND_PUBLISHED` at baseline commit `f57ae3e9d89fb3432fbb8b7c572042b69f6fcc58`.
- Real installation: `COMPLETE`; current Check returned `NO_CHANGE_CODEX_USER_SKILLS_ALREADY_CURRENT` with exit code `0`.
- CLI E2E: `PASS`.
- Codex App E2E: `PASS`.
- Host E2E: `FULLY_CLOSED`.
- Idempotency, shared protocol use, `.system` protection, ownership-manifest validity, and repository integrity: `PASS`.
- Bulk consumer-repository migration: `NOT_AUTHORIZED`; bounded migration-on-demand is governed by Consumer Adoption Architecture V1 below.
- Closure evidence: `docs/dogfood/codex_user_skills_bootstrap_v1_real_installation_and_host_e2e_report.md`.

## Consumer Adoption Architecture V1

- Architecture: `FROZEN`; primary adoption mode: `AI_LEVEL_CONFIG_BACK_REFERENCE`.
- `ai-skill-hub`: `CANONICAL_CAPABILITY_SSOT` for generic canonical capability, skill implementation, tests, version, and publication.
- AI-level project configuration: primary Consumer -> Hub discovery and back-reference entry.
- Consumer repositories: do not copy generic canonical skill payload; continue to own project-specific AGENTS, governance, business rules, task packages, validation, status, handoff, and evidence.
- Future onboarding: one `LIGHTWEIGHT_PREFLIGHT`; default validation is one minimal routing smoke.
- Repository migration: `ON_DEMAND_ONLY`, limited to observed project-local legacy debt.
- Bulk consumer migration: `NOT_AUTHORIZED`; Hub product remediation: `DEFECT_DRIVEN_ONLY`.
- Standalone Consumer Repository Discovery Program: `CLOSED_AS_STANDALONE_PROGRAM`.
- Consumer adoption is not a standalone large governance program for each repository.
- User Installed Bundle V1 remains `workflow-bootstrap`, `chatgpt-handoff-pilot`, `_protocol`; system wrapper user installation remains `NOT_INCLUDED_IN_BUNDLE_V1`.

### Historical `Derivative_Data` Pilot Evidence

- Legacy pilot status: `CLOSED_SUPERSEDED_BY_AI_LEVEL_BACK_REFERENCE_ADOPTION_ARCHITECTURE`, not failed.
- A1R: `PRESERVED_HISTORICAL_PASS`.
- A2 CLI: `PRESERVED_HISTORICAL_PASS_WITH_NOTES`.
- Observed compatibility debt: stale or absent project-relative `.codex/skills` references in project guidance / wrapper surfaces.
- Historical provisional direction: `MIGRATE_PROJECT_RELATIVE_REFERENCES`, applicable only to the observed `Derivative_Data` debt; not a universal requirement, default migration policy, or rollout authorization.
- A2 App: `NOT_COMPLETED_AND_NO_LONGER_REQUIRED_FOR_ARCHITECTURE_CLOSURE`.

### Lightweight Adoption Preflight

1. Confirm the AI-level config exists and correctly points back to the Hub.
2. Confirm the Consumer Repository does not copy generic canonical skill payload.
3. Check for concrete legacy debt: `.codex/skills/**`, a repo-local generic skill copy, a broken wrapper, or an absolute host path.
4. Confirm project-specific governance and business rules remain project-local.
5. Run one minimal routing smoke.

Allowed outputs only:

- `ADOPT_AS_IS`: no Consumer Repository change is required; close onboarding directly.
- `MIGRATION_REQUIRED`: create a minimal project-local migration only for observed legacy debt.
- `BLOCKED`: a reproducible technical issue requires ASH assessment for a possible common Hub product defect.

Any migration must be `PROJECT_LOCAL`, `BOUNDED`, `CHANGED_PATH_ALLOWLIST`, and `INDEPENDENTLY_REVIEWED`. It may address only broken project-relative skill references, a legacy wrapper, the AI-level config / project-governance entry, and directly related explanation. It must not copy canonical skill payload, create a repo-local generic skill fork, hard-code a host installation path, modify business code or data logic, or touch other Consumer Repositories.

```text
Consumer_Adoption_Architecture_V1=
FROZEN

Primary_Adoption_Mode=
AI_LEVEL_CONFIG_BACK_REFERENCE

ai-skill-hub=
CANONICAL_CAPABILITY_SSOT

AI_Level_Project_Config=
PRIMARY_CONSUMER_TO_HUB_DISCOVERY_AND_BACK_REFERENCE_ENTRY

Consumer_Repository=
PROJECT_SPECIFIC_GOVERNANCE_BUSINESS_RULES_TASK_PACKAGES_VALIDATION_STATUS_HANDOFF_EVIDENCE

Derivative_Data_Legacy_Consumer_Pilot=
CLOSED_SUPERSEDED_BY_AI_LEVEL_BACK_REFERENCE_ADOPTION_ARCHITECTURE

A1R=
PRESERVED_HISTORICAL_PASS

A2_CLI=
PRESERVED_HISTORICAL_PASS_WITH_NOTES

A2_APP=
NOT_COMPLETED_AND_NO_LONGER_REQUIRED_FOR_ARCHITECTURE_CLOSURE

Consumer_Repository_Discovery_Program=
CLOSED_AS_STANDALONE_PROGRAM

Future_Consumer_Onboarding=
LIGHTWEIGHT_PREFLIGHT

Repository_Migration=
ON_DEMAND_ONLY

Bulk_Consumer_Migration=
NOT_AUTHORIZED

Hub_Product_Remediation=
DEFECT_DRIVEN_ONLY
```

### AI-Level Config Back-Reference Contract V1 (`AI_LEVEL_CONFIG_BACK_REFERENCE_V1`)

- Contract status: `FROZEN` (this refresh freezes the contract; the matching remediation of the routing implementation is recorded below).
- Relationship: Consumer Adoption Architecture V1 (`AI_LEVEL_CONFIG_BACK_REFERENCE`) remains the frozen architecture; this contract freezes its concrete V1 routing semantics without rewriting any historical contract.
- Core contract:
  1. The canonical Skill resolution core is agent-agnostic.
  2. After full Project Runtime Pack retirement, every currently supported local-development AI consumer must still have a verified canonical Hub discovery path.
  3. Agent discovery adapters may use each agent's native user-level Skill directory; physical paths are not required to be uniform.
  4. A Consumer Project does not store canonical Skill payload.
  5. A Consumer Project does not store machine-specific Hub absolute paths.
  6. The User Bundle is not expanded into a full canonical Skill mirror.
- Frozen V1 supported consumers: `CODEX`, `CLAUDE_CODE`, `GITHUB_COPILOT`, `KIMI_CODE`.
- Hub locator V1: one agent-neutral machine/user configuration at `~/.ai-skill-hub/locator.json` (the current user's home on this machine), with an explicit config-home override reserved for tests and isolated environments. The locator is the only component allowed to store the machine-local Hub checkout path; its schema remains fail closed; no canonical Skill copy is created by it. The pre-merge candidate's Codex-bound locator location carries no backward-compatibility obligation.
- Agent adapters V1: thin user-level Skill entries only — Codex (`$CODEX_HOME/skills/ai-skill-hub-router/SKILL.md`), Claude Code (`~/.claude/skills/ai-skill-hub-router/SKILL.md`), and one generic Agent Skills entry (`~/.agents/skills/ai-skill-hub-router/SKILL.md`) that serves GitHub Copilot and Kimi Code. All adapters share the same neutral locator, contain no canonical payload, and contain no machine-specific Hub absolute path.
- `configure` safety: all target destinations (locator plus every adapter) pass a read-only preflight before the first write; any unknown or conflicting existing content yields `Mutation=NONE`; single-file writes remain temp-file + atomic replace.
- Empty-requirement safety: `smoke` / `doctor` with zero declared required skills fail closed with `INSUFFICIENT_REQUIREMENTS` unless the caller explicitly confirms that zero skills is intentional; an empty requirement set is never evidence of migration safety.
- Runtime Pack compatibility: Runtime Pack pinning semantics, manifest schema, initializer, project-local router behavior, and the supported pinned/portable modes are unchanged; this contract only supplies the equivalent discovery for the preferred local-development adoption mode.

```text
AI_Level_Config_Back_Reference_Contract_V1=
FROZEN

Canonical_Resolution_Core=
AGENT_AGNOSTIC

Supported_Consumers_V1=
CODEX
CLAUDE_CODE
GITHUB_COPILOT
KIMI_CODE

Hub_Locator_V1=
AGENT_NEUTRAL_USER_CONFIG

Consumer_Project_Canonical_Payload=
NOT_STORED

Consumer_Project_Hub_Absolute_Path=
NOT_STORED

User_Bundle_Full_Mirror=
NOT_EXPANDED

Universal_Routing_V1_Remediation=
LOCAL_REMEDIATION_COMPLETE_PENDING_INDEPENDENT_REVIEW

Remediation_Base_Commit=
9231e5fb511d50069f93247720444cce8a13cb1f

Remediation_Branch=
codex/ai-level-universal-routing-v1
```

### Stale Router Reconciliation V1 (`ASH_STALE_ROUTER_RECONCILIATION_V1`)

- Work item: `ASH_STALE_ROUTER_RECONCILIATION_V1`; accepted baseline `main @ 240f74d1d00c39cb2a6485a3e1af9197e77802b9`.
- Product remediation: `DOCS_AND_TESTS_ONLY` — no resolver / router code change; frozen `configure` semantics unchanged (unknown or conflicting existing content still yields `Mutation=NONE`).
- Sanctioned mechanism: `docs/governance/stale_router_reconciliation_v1.md` is the only authorized machine-level stale-router transition — exact SHA-256 identification of the two known pre-remediation artifacts (stale router adapter SHA-256 `80272ffa…3979aa`, 1171 bytes; legacy Codex-bound locator SHA-256 `ac5665bf…369c90`, 113 bytes), maintainer removal of hash-verified files only, then frozen `configure` rebuild. No `--force`, no generic migration framework, no arbitrary legacy adoption.
- Focused tests: `tests/test_ai_skill_hub_resolver.py` 20/20 PASS, including the new coverage: the exact known stale shape is still `BLOCKED_ROUTER_CONFLICT` with `Mutation=NONE`; the documented removal → configure transition converges and is idempotent; a one-character near-miss still fails closed.
- Regression: `skill-router`, `universal-skill-routing`, `adapter-consistency-smoke`, `commit-convention`, `hub-adapter-contract`, `dryrun-no-side-effects`, `reseed-audit`, `sync-smoke`, `skill-structure`, and `codex-user-skills-bootstrap` 71/71 all PASS under `D:\miniforge3\envs\dev-core-py312` (the previously recorded MAX_PATH baseline failure did not reproduce under the workspace-local TEMP used this round). `project-runtime-pack` could not execute in this session: the confined sandbox blocks msys2 `sh.exe` signal pipes (standalone `sh -c` exits `0xC0000142`), which every fixture `git clone` requires; no runtime-pack file changed in this work item, so the accepted-baseline evidence (124 passed) stands. This is an environment limitation, not a product gap.
- Machine reconciliation on this host: `PARTIAL_SANCTIONED_STATE` — the two hash-verified stale artifacts were removed through the sanctioned mechanism on `2026-08-26`; the frozen `configure` write itself is pending an external execution gate (`READY_FOR_EXTERNAL_MACHINE_GATE`) because the executing session sandbox may not write user-home routing directories. Recorded machine state: no neutral locator and no current adapters exist yet; unknown-state fail-closed posture is unchanged.

## Layer Status

### Canonical Skill Layer (`skills/`)

- Status: `stable`
- `skills/` remains the sole canonical source of truth.
- PR #12 is merged into `main` at `981fdb94d0bad2eaec58addf717effdac1b2ec40`.
- PR #12 completes the P0 first batch of canonical skill prompt / template / example entrypoint cleanup for `workflow-bootstrap`, `financial-data-project-migration`, `system-status-update`, and `system-handoff`.
- DeepSeek review configuration closeout is complete.
- P1 examples coverage is complete after PR #15, PR #16, and PR #17 merged into `main`.
- Later current-main facts after P1 closeout are recorded without reopening P1: PR #19 merged the `financial-data-agent-bootstrap` roadmap plus F0 task package, PR #20 merged the F0 skill skeleton, and PR #21 merged the README structure fix with skill structure validation passing.
- This status records the merged state only; it does not reopen P0, DeepSeek configuration, or P1 examples coverage.

### Prompt / Template / Example Asset Layer

- Status: `stable-to-evolving`
- Reusable prompt entrypoints are clearer after PR #12.
- Heavy generated-output structures are easier to discover from `templates/` instead of being embedded as prompt prose.
- `workflow-bootstrap` now has a project-level post-dev dual-refresh prompt and a GitHub PR bootstrap prompt.
- `financial-data-project-migration` now separates the first executable migration task package template from the first executable migration task package prompt.
- `system-status-update` now owns the system-level status-first linked refresh prompt.
- `system-handoff` now has clearer receiver-side examples and entry references for status-baseline-driven handoff refreshes.
- P1-A expanded `chatgpt-handoff-pilot` invocation examples in PR #15 at commit `8a734ff`.
- P1-B expanded `project-takeover` invocation examples in PR #16 at commit `ae97ab4` and tightened limited-scope / scoped-reuse wording before merge.
- P1-C expanded `skill-governance` invocation examples in PR #17 at commit `fd6cf10`, including the post-review Skill Refactor boundary tightening.
- PR #21 subsequently confirmed that the `financial-data-agent-bootstrap` README structure fix was merged and skill structure validation passes on current main.

### Workflow Bootstrap Layer

- Status: `stable-to-evolving`
- `workflow-bootstrap` remains the project-level orchestration owner for role-chain and thin project-side workflow guidance.
- The GitHub PR bootstrap prompt is aligned with the canonical orchestration contract after Copilot review corrections to authorization flags: `commit`, `push`, `pr`, and `comment`.
- This layer continues to route implementation evidence and closeout through `chatgpt-handoff-pilot`, `update-project-status`, `system-status-update`, and `system-handoff` instead of replacing those owners.

### System Status / Handoff Layer

- Status: `stable`
- `system-status-update` owns system-level status-first linked refresh and produces the concise status baseline for handoff.
- `system-handoff` is the handoff receiver and handoff output boundary owner.
- This refresh records the `2026-07-27` closure baseline at current observed `origin/main` HEAD `3919677`, preserving phase consistency with the handoff document.
- Current-state SSOT remains the `docs/status/skill-hub-status.md` plus `docs/HANDOFF.md` pair unless a maintainer explicitly declares another current-state SSOT.

### Review Tooling Layer

- Status: `stable-to-evolving`
- Review tooling remains outside this closeout's write scope.
- DeepSeek review configuration has completed its closeout path before this P1 status refresh.
- P1-A and P1-C DeepSeek reviews returned `[]`; P1-B received a low-severity note that was addressed before merge.
- Codex review feedback for P1-C was addressed by tightening the Skill Refactor example boundary; Codex re-review found no major issues before PR #17 merge.
- This closeout does not modify `.github/workflows/`, review actions, adapter logic, index logic, sync/export/import/check tools, or tests.

## Current Phase

- System phase: `Phase 3 - Controlled System`.
- Closeout state: P0 asset entrypoint cleanup, DeepSeek review configuration, and P1 examples coverage are merged and complete.
- Current observed main HEAD after the latest governance documentation update: `3919677`.
- Completed P1 rounds:
  - P1-A: `chatgpt-handoff-pilot` invocation examples, PR #15, commit `8a734ff`.
  - P1-B: `project-takeover` invocation examples, PR #16, commit `ae97ab4`.
  - P1-C: `skill-governance` invocation examples, PR #17, commit `fd6cf10`.
- Later mainline facts:
  - PR #19: `financial-data-agent-bootstrap` roadmap plus F0 task package.
  - PR #20: `financial-data-agent-bootstrap` F0 skill skeleton.
  - PR #21: README structure fix; skill structure validation passes.
- Phase judgment: the system is no longer in P1 examples coverage construction.
- Direction: the current program direction is the read-only Consumer Adoption Pilot above; keep the separate P1 line closed, and start any future P2 work only through a separate planning / backlog-selection round.
- Freshness gate: this refresh on `2026-07-27` meets the 14-day freshness threshold.

## Capabilities

- Reusable prompt entrypoints are clearer and easier to invoke.
- Heavy task-package template structure can be discovered from `templates/`.
- Project-level dual-refresh prompting belongs to `workflow-bootstrap`.
- System-level status-first linked refresh belongs to `system-status-update`.
- `system-handoff` is explicitly the receiver for a status baseline and the owner of handoff output boundaries.
- GitHub PR bootstrap authorization flags now align with the canonical orchestration contract: `commit`, `push`, `pr`, and `comment`.
- P1 examples now cover `chatgpt-handoff-pilot`, `project-takeover`, and `skill-governance` invocation surfaces.
- `skill-governance` batch evaluator wording is now explicit as read-only sequential evaluation, not batch rewrite.
- The Skill Refactor example boundary now keeps scripts, tests, registry/index files, workflow configuration, `.agents`, tools, prompt bodies, templates, and other skills outside the refactor entry.

## Stability

- Overall maturity: `evolving`
- Stable: canonical ownership in `skills/`, thin adapter / wrapper discipline, status-first linked refresh ordering, and handoff phase consistency.
- Stable boundary: this round is a docs-only Consumer Adoption Architecture V1 freeze; it does not authorize implementation or change runtime tools.
- Stable boundary: this round does not modify adapters, `.agents/skills/*`, GitHub entrypoints, `.github/workflows/*`, tools, tests, skill examples, prompt bodies, templates, protocols, registry/index files, or other skills.
- Stable boundary: `workflow-bootstrap` owns project-level orchestration; `system-status-update` owns system-level status-first linked refresh; `system-handoff` owns handoff receiver / output boundary; `financial-data-project-migration` keeps assessment and execution separated, with templates representing generated-output structure rather than skill behavior.
- Stable: Consumer Adoption Architecture V1 is frozen around AI-level config back-reference, lightweight preflight, migration-on-demand, and defect-driven Hub remediation.

## Risks / Gaps

- Preserve the historical A1R / A2 CLI / A2 App facts; do not recast the superseded pilot as failed or manufacture a complete historical pass.
- Do not retain A2 App rerun as an architecture-closure requirement.
- Do not generalize `MIGRATE_PROJECT_RELATIVE_REFERENCES` beyond the compatibility debt observed in `Derivative_Data`.
- Do not authorize bulk migration, preventive repository migration, or speculative Hub remediation.
- Do not drift into `.agents` wrapper changes, workflow changes, registry/index/tools changes, prompt body / protocol changes, or large skill restructuring.
- Bridge mirror files, if updated in this closeout, must remain semantic mirrors of the active HANDOFF/status facts and must not become current-state SSOT.

## Recommended Next Steps

1. For the next formal consumer onboarding, run only the five-check lightweight preflight.
2. Close as `ADOPT_AS_IS`, or create a bounded project-local migration only when concrete legacy debt is observed.
3. Return `BLOCKED` to ASH only for a reproducible technical issue that may be a common Hub product defect.
4. Keep bulk migration, preventive rollout, and speculative Hub capability work unauthorized.
