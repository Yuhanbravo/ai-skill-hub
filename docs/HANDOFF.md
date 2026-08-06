# HANDOFF

This file is the single source of truth for project handoff.

## Update Log

- 2026-03-30: Initialized the system handoff document for `ai-skill-hub` and captured the current phase, hard boundaries, design decisions, intentional gaps, and next-phase direction.
- 2026-03-31: Merged the current system-state refresh, selective rollout control, DryRun contract hardening, and system-wrapper invocation surfaces into the handoff brief without rewriting the document.
- 2026-04-01: Merged the new re-seed preflight audit capability and conservative hub self-detection into the system handoff, while preserving the existing phase model and wrapper-only boundaries.
- 2026-04-02: Merged a `system-takeover` pass into the handoff, capturing the explicit AI/Human/Bridge documentation split, the current system capability map, the router mismatch around `system-takeover`, and the hub-vs-consumer governance boundary.
- 2026-04-02: Refreshed the system status and merged the latest bridge-reference audit into the handoff, confirming that current bridge-layer references remained documentation-facing and identifying the direct compatibility link in AI_USAGE.md before this cleanup.
- 2026-04-02: Merged the repository-wide bridge audit result into the handoff, confirming that direct bridge-path dependency has now been cleared from active docs and that remaining bridge references are semantic, historical, or bridge-layer self-description rather than runtime dependency.
- 2026-04-03: Merged the landed commit-governance capability into the handoff, capturing `docs/governance/` as the repository-governance documentation home, the moved commit convention, the `skill-governance` validator asset, the versioned `.githooks/commit-msg` plus `tools/install_git_hooks.ps1` local activation path, the `export_bundle.ps1` auto-commit reuse of the same validator, and the current choice to observe real usage before tightening body rules further.
- 2026-04-07: Merged the explicit `system-takeover` routing fix, the new `hub|consumer` adapter-governance mode split, and the default local validation entrypoint `tools/run_local_checks.ps1` into the handoff without changing phase or hard boundaries.
- 2026-04-07: Merged the new human-oriented quick commands docs for `system-takeover` plus the lightweight cross-link from `SYSTEM_SKILL_QUICK_COMMANDS.md`, treating them as maintainer-facing documentation-surface additions rather than protocol, governance, or boundary changes.
- 2026-04-20: Merged the workspace-aware status refresh upgrade, the new derivative-surface drift audit, invocation-metadata extraction hardening, bridge semantic mirror refresh, and the minimum coordination note between `documentation-governance` and `update-project-status` into the handoff while preserving `Phase 3 - Controlled System` and read-only governance boundaries.
- 2026-04-20: Applied minimal wrapper-coordination hardening for `system-status-update` and `system-handoff`; refreshed status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-20`), then completed handoff merge with phase consistency check (`Phase 3 - Controlled System`) and recorded this status baseline.
- 2026-04-21: Merged the completed Phase 1 `workflow-bootstrap` canonical workflow asset into the handoff after refreshing status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-21`); recorded the new minimal `Copilot-led / Codex-implemented` workflow-shell expression, kept `chatgpt-handoff-pilot` as the handoff protocol layer, preserved all existing hard boundaries, and noted that project-side runtime-pack decisions remain deferred to Phase 2.
- 2026-04-22: Merged Phase 2 `workflow-bootstrap` canonical drafts into system status/handoff context after refreshing status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-22`): landed only thin-entry canonical drafts (`AGENTS.md` master-entry draft, `.github/copilot-instructions.md` Copilot-specific thin-adapter draft, and canonical backreference rules draft), preserved `Phase 3 - Controlled System`, and retained hard boundaries that real project-side runtime pack files are still not implemented and rollout has not started. Phase 2 含一次 bounded re-run，用于修正 cloud snapshot 缺少 task package 时的输入不完整问题；最终以当前 draft assets 与最新 execution report 为准。
- 2026-04-23: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-23`) and then merged the completed Phase 3A `workflow-bootstrap` canonical template sketches into handoff context. This update records that the repository has moved from Phase 2 thin-entry drafts to Phase 3A project-side runtime pack template sketch assets, while preserving `Phase 3 - Controlled System`, keeping all runtime-pack surfaces non-implemented, and explicitly distinguishing completed canonical sketch work from the still-not-started single consumer repo pilot implementation stage.
- 2026-04-23: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-23`) and then merged the completed Phase 3B `workflow-bootstrap` canonical pilot-validation sketches into handoff context. This update records that the repository has moved from Phase 3A template sketches to Phase 3B validation sketches for one abstract single consumer repo profile, while preserving `Phase 3 - Controlled System`, keeping all runtime-pack surfaces non-implemented, and explicitly stating that this round does not correspond to any selected real consumer repo.
- 2026-04-24: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-24`) and then merged the completed Phase 3C single consumer repo implementation pilot into handoff context. This update records that `ai-skill-hub` moved from Phase 3B pilot-validation sketching to a real single consumer repo implementation pilot in the current repository, landed the minimal `AGENTS.md` plus `.github/copilot-instructions.md` entrypoint pair, validated concrete canonical backreference paths plus anti-second-rulebook behavior, and still did not start rollout, distribution, adoption, or toolchain expansion.
- 2026-04-24: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-24`) and then merged the completed Phase 3D canonical path calibration into handoff context. This update records that the repository kept the existing single-repo entrypoint pair but added bounded calibration assets, concluded that `<project-local-canonical-skill-path>` should remain a controlled placeholder rather than be hard-materialized in the current repo, applied only minimal backreference wording tightening to `AGENTS.md` and `.github/copilot-instructions.md`, and still did not start rollout, distribution, adoption, tooling changes, or project-side surface expansion.
- 2026-04-29: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-04-29`) and then merged the current `workflow-bootstrap` Phase 0-3 baseline into handoff context. This records non-git / low-git runtime profile absorption, role split canonicalization, review tier guidance, and runtime pack minimal manifest guidance as complete while preserving `Phase 3 - Controlled System`; Phase 4 multi-project pilot remains pending and must start with a separate task package.
- 2026-04-30: Merged the completed `workflow-bootstrap` Phase 4 Round 1 read-only multi-project pilot review into handoff context after confirming the review memo and execution report were committed. This records `docs/reviews/workflow-bootstrap_phase4_multi_project_pilot_review.md` and `tasks/workflow-bootstrap_phase4_multi_project_pilot_execution_report.md` as Round 1 evidence, preserves `Phase 3 - Controlled System`, and keeps Git-first validation explicitly limited by a dubious-ownership evidence gap.
- 2026-05-11: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-05-11`) and then merged the completed `workflow-bootstrap` orchestration snippets consistency run into handoff context. This records that the snippets completed a first repository-internal Step 1 -> Step 5 run with a final `Go` decision, validated same-tool multi-role execution when guarded by explicit phase-switch text and gate decisions, aligned README wording to role-chain-first language, and introduced no validator / CI / automation / tool adapter expansion.
- 2026-05-12: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-05-12`) and then merged the completed P0 shared assessment output protocol closure into handoff context. This records `skills/_protocol/skill_assessment_output.md` as the shared assessment output vocabulary, confirms minimal core / related skill integration, preserves `Phase 3 - Controlled System`, keeps `workflow-bootstrap` and `chatgpt-handoff-pilot` ownership boundaries unchanged, and introduces no automation, validator, CI, router / pipeline integration, or mandatory `maturity_score` rollout.
- 2026-05-12: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-05-12`) and then merged the P1/P1.5 shared assessment protocol adoption and dogfood closure into handoff context. This records that P1 adoption accepted the protocol with light follow-up, P1 light follow-up added mini examples and a `system-takeover` invocation snippet, and P1.5 system-takeover dogfood concluded `Pass: protocol works for system-level takeover`, while preserving `Phase 3 - Controlled System` and keeping validator / CI / automation / router-pipeline integration deferred.
- 2026-05-15: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-05-15`) and then merged the documentation-governance mutable-status SSOT boundary into handoff context. This records that current phase, next-phase direction, latest validation, blocker, and pending-merge facts must stay in declared HANDOFF/status surfaces unless a maintainer declares another current-state SSOT, while preserving `Phase 3 - Controlled System` and adding no automation, validator, CI, or controller behavior.

- 2026-05-26: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-05-26`) and then applied a minimal Phase 1.5 closure merge into handoff context. This records that Skill Catalog / Template Registry Phase 1 is complete with centralized index entrypoints in `docs/SKILL_CATALOG.md` and `docs/TEMPLATE_REGISTRY.md`, preserves `skills/` as canonical with thin adapter discovery and bridge-reference boundaries unchanged, and explicitly leaves template migration, adapter sync, bridge refresh, canonical promotion, validator, and automation work deferred.

- 2026-06-02: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-06-02`) and then applied a lightweight post-merge handoff refresh after PR #10 and PR #11. This records that PR #10 merged Post-Dev Dual Refresh v2 governance gates, PR #11 merged the workflow-bootstrap orchestration split, and PR #11 merge commit `7eb65c9f1860c07925292fb438354b84b422819a` is the narrow merge evidence pointer, while preserving `Phase 3 - Controlled System`, delegated protocol ownership, and no skill-behavior / adapter / metadata changes.
- 2026-06-08: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-06-08`) and then applied the PR #12 post-merge closeout. This records PR #12 merged at `981fdb94d0bad2eaec58addf717effdac1b2ec40`, closes the P0 first batch canonical skill prompt / template / example entrypoint cleanup, and sets the next direction as a small independent DeepSeek workflow fix followed by P1 examples coverage rather than continued P0 expansion.
- 2026-06-11: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-06-11`) and then applied the P1 examples coverage closeout. This records P1-A / PR #15 at `8a734ff`, P1-B / PR #16 at `ae97ab4`, and P1-C / PR #17 at `fd6cf10` as merged, closes P1 examples coverage, and keeps P2 as a separate future planning / task-package round rather than starting it here.
- 2026-07-08: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-07-08`) and then refreshed the P1 closeout handoff against current main. This records current observed `origin/main` HEAD `014c007` after PR #21, preserves the P1-A / P1-B / P1-C closeout facts, and adds brief later current-main facts for PR #19, PR #20, and PR #21 without entering F1 adapter/index work.
- 2026-07-27: Recorded the docs-only Stage D closure for Codex User Skills Bootstrap V1 after refreshing the real-host installation Check. The implementation baseline is merged and published, real installation is current, CLI/App discovery E2E passed, idempotency and `.system` protection were verified, and consumer-repository migration remains out of scope.
- 2026-07-27: Recorded the transition from the closed Codex User Skills Bootstrap V1 to the consumer-repository adoption pilot. `PJT_Derivative_Data` is the first pilot and is authorized only for read-only adoption audit and governance planning; implementation and broader rollout remain unauthorized. This also records the actual user-level Bundle V1 boundary and that `system-handoff` is not included in Bundle V1.
- 2026-08-06: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-08-06`) and then merged the completed Project Runtime Pack MVP V1 local final closure into handoff context. This records `ASH-PROJECT-RUNTIME-PACK-MVP-V1` as `CLOSED_LOCAL_ONLY_WITH_NOTES` with decision `PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_LOCAL_FINAL_CLOSURE`; preserves the commit chain (`d4d735e0` design / `7c8e54c` implementation / `1f01ab2` remediation) and the remediation and heterogeneous revalidation evidence (112 passed x 3, 20/20 submodule rollback, 20/20 concurrency, Codex/Kimi E2E PASS); preserves the pre-existing `codex-user-skills-bootstrap` MAX_PATH baseline note, the Copilot workspace-root and Claude authenticated E2E non-verified notes, the deferred F-10 ~ F-15 notes with substance, and the `file://` fixture restriction; and leaves remote publication for separate authorization while preserving `Phase 3 - Controlled System` and all existing hard boundaries.
- 2026-08-06: Refreshed system status first (`docs/status/skill-hub-status.md`, Updated at `2026-08-06`) and then merged the completed Project Runtime Pack MVP V1 remote publication into handoff context. This records `ASH-PROJECT-RUNTIME-PACK-MVP-V1` as `CLOSED_REMOTE_PUBLISHED_WITH_NOTES` with decision `PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_REMOTE_PUBLICATION_AND_FINAL_CLOSURE`; the local closure commit `4e3366c3...` was safely published to the authoritative remote `gitea-nas:yuhanbravo/ai-skill-hub.git` with no force push, and post-push local `main` == `origin/main` == actual remote `4e3366c3...` with ahead/behind `0 0`; all preserved notes (MAX_PATH baseline, Copilot workspace-root and Claude authenticated E2E, deferred F-10 ~ F-15 with substance, `file://` fixture restriction) remain in force, recorded in `tasks/project_runtime_pack_mvp_v1_remote_publication_report.md`; the next action is the consumer-project pilot, while preserving `Phase 3 - Controlled System` and all existing hard boundaries.

## Current Status

`ai-skill-hub` is currently in `Phase 3 - Controlled System`.

The repository continues to operate as a layered AI capability system rather than a normal business-project codebase. `skills/` remains the stable canonical source, `.agents/skills/` and `.github/skills/` remain derivative discoverability surfaces, governance and tooling remain read-only / local-first, and `docs/HANDOFF.md` plus `docs/status/skill-hub-status.md` remain the active-source coordination documents for system state.

As of the `2026-07-27` status baseline, current observed `origin/main` HEAD is `3919677`. P0 asset entrypoint cleanup is closed, DeepSeek review configuration closeout is closed, and P1 examples coverage is closed. The current system phase remains `Phase 3 - Controlled System`; the current program stage is recorded below.

As of `2026-07-27`, Codex User Skills Bootstrap V1 is closed through a real-installation and host E2E evidence pass. The implementation baseline is `f57ae3e9d89fb3432fbb8b7c572042b69f6fcc58`; the installed `workflow-bootstrap`, `chatgpt-handoff-pilot`, and `_protocol` entries are current and fingerprint-consistent; CLI and Codex App discovery passed; and the closure evidence is recorded in `docs/dogfood/codex_user_skills_bootstrap_v1_real_installation_and_host_e2e_report.md`. This is a local installation closure, not consumer-repository migration, distribution readiness, or authorization to merge the docs branch to `main`.

Current program stage is `CONSUMER_REPOSITORY_ADOPTION_PILOT`. The first consumer adoption pilot is `PJT_Derivative_Data`, targeting `D:\dev\Derivative_Data`. The current authorized stage is `READ_ONLY_ADOPTION_AUDIT_AND_GOVERNANCE_PLANNING`; pilot implementation is `NOT_AUTHORIZED`, and rollout to other consumer repositories is `NOT_AUTHORIZED`. The pilot is authorized but not completed, and the consumer adoption pattern remains unvalidated.

User-level Bundle V1 currently consists only of `workflow-bootstrap`, `chatgpt-handoff-pilot`, and `_protocol`. The hub still contains system-wrapper capabilities such as `system-handoff`, `system-status-update`, and `system-takeover`, but there is no evidence that they were installed as user-level Bundle V1 skills; `system-handoff` is `NOT_INCLUDED_IN_BUNDLE_V1`. Any user-level bundle adjustment is separate future governance and is not part of the `Derivative_Data` pilot.

Project Runtime Pack MVP V1 (`ASH-PROJECT-RUNTIME-PACK-MVP-V1`) is closed and remotely published at `4e3366c3...` (design `d4d735e0`, implementation `7c8e54c`, remediation `1f01ab2`). The initializer, schema, and focused test suite landed locally; remediation and heterogeneous revalidation passed with notes; the local closure commit was safely published to the authoritative remote `gitea-nas:yuhanbravo/ai-skill-hub.git` without force push, and the work item is recorded as `CLOSED_REMOTE_PUBLISHED_WITH_NOTES` with decision `PASS_WITH_NOTES_PROJECT_RUNTIME_PACK_MVP_V1_REMOTE_PUBLICATION_AND_FINAL_CLOSURE`. Known notes are preserved and not hidden: the pre-existing `codex-user-skills-bootstrap` MAX_PATH baseline issue, Copilot workspace-root authenticated E2E not literally verified, Claude Code authenticated E2E not performed, deferred F-10 ~ F-15 with substance, and the `file://` local fixture restriction — all recorded in `tasks/project_runtime_pack_mvp_v1_final_closure_report.md` and `tasks/project_runtime_pack_mvp_v1_remote_publication_report.md`. This closure adds no rollout, distribution, adoption, or consumer-repository authorization; the next action is the consumer-project pilot.

```text
Current_Program_Stage=
CONSUMER_REPOSITORY_ADOPTION_PILOT

Bootstrap_V1=
FULLY_CLOSED

First_Consumer_Adoption_Pilot=
PJT_Derivative_Data

Pilot_Repository=
D:\dev\Derivative_Data

Pilot_Current_Status=
AUTHORIZED_FOR_READ_ONLY_ADOPTION_AUDIT_AND_GOVERNANCE_PLANNING

Pilot_Implementation=
NOT_AUTHORIZED

Other_Consumer_Repository_Rollout=
NOT_AUTHORIZED

User_Installed_Bundle_V1=
workflow-bootstrap
chatgpt-handoff-pilot
_protocol

System_Wrapper_User_Installation=
NOT_INCLUDED_IN_BUNDLE_V1

System_Handoff_User_Bundle_State=
NOT_INCLUDED_IN_BUNDLE_V1
```

P1 examples coverage completed in three merged rounds: P1-A expanded `chatgpt-handoff-pilot` invocation examples in PR #15 at `8a734ff`; P1-B expanded `project-takeover` invocation examples in PR #16 at `ae97ab4` and tightened limited-scope / scoped-reuse wording before merge; P1-C expanded `skill-governance` invocation examples in PR #17 at `fd6cf10`, including the follow-up Skill Refactor boundary tightening after Codex review. P1-C also clarified the batch evaluator as read-only sequential evaluation, not batch rewrite.

Later current-main facts are recorded separately from the P1 closeout: PR #19 merged the `financial-data-agent-bootstrap` roadmap plus F0 task package, PR #20 merged the `financial-data-agent-bootstrap` F0 skill skeleton, and PR #21 merged the README structure fix with skill structure validation passing. These facts keep the handoff current without expanding this closeout into F1 adapter/index work or a detailed `financial-data-agent-bootstrap` report.

Skill Catalog / Template Registry Phase 1 is now complete as a documentation indexing closure: `docs/SKILL_CATALOG.md` centralizes skill selection and source-surface boundaries, and `docs/TEMPLATE_REGISTRY.md` centralizes reusable templates, snippets, prompts, examples, and historical candidates. These are index surfaces only; they do not replace canonical `skills/`, they do not promote `tasks/` historical artifacts into canonical templates, and they do not change thin adapter or bridge-reference boundaries.

The `workflow-bootstrap` line has now reached its Phase 0-3 baseline without changing system phase. Phase 0 absorbed non-git / low-git runtime profile guidance; Phase 1 canonicalized the tool-agnostic role chain; Phase 2 added advisory review tier guidance; and Phase 3 completed runtime pack minimal manifest guidance. This baseline defines workflow shell, role split, runtime profile, review tiers, and minimal runtime-pack surface guidance only.

`chatgpt-handoff-pilot` remains the protocol layer for task packages, bounded execution, and execution reports. `workflow-bootstrap` explains how roles and thin project-side surfaces should coordinate, but it does not replace the handoff protocol or authorize a second local rulebook. `tasks/` may be a preferred project-local evidence path for non-git / low-git work, but it is not a mandatory global path for every project.

The `workflow-bootstrap` line has completed Phase 4 Round 1 as a read-only multi-project pilot review. The evidence lives in `docs/reviews/workflow-bootstrap_phase4_multi_project_pilot_review.md` and `tasks/workflow-bootstrap_phase4_multi_project_pilot_execution_report.md`. Round 1 observed a Git-first candidate, a non-git / low-git candidate, and the `ai-skill-hub` self case; however, Git-first validation remains incomplete because external candidate Git commands were blocked by dubious ownership.

Round 1 supports only limited generalized findings: `task package + execution report` pairing is useful when Git evidence is weak or unavailable; `docs/HANDOFF.md` and status surfaces should remain minimal closure rather than per-task trace logs; and no single project layout should be promoted into canonical guidance. It does not authorize canonical guidance changes, rollout, distribution, validators, CI, automation, tool adapters, `.github/instructions`, or `.github/agents`.

The `workflow-bootstrap` orchestration line has now moved from one oversized snippet surface to a focused-asset structure. PR #10 merged Post-Dev Dual Refresh v2 governance gates into orchestration guidance, and PR #11 merged the snippet split at `7eb65c9f1860c07925292fb438354b84b422819a`. The lightweight `skills/workflow-bootstrap/orchestration_snippets.md` asset now serves as a role-chain entry and navigation index that points to `skills/workflow-bootstrap/orchestration/post_dev_dual_refresh.md` and `skills/workflow-bootstrap/orchestration/github_pr_bootstrap.md`; the PR #11 execution evidence remains in `tasks/workflow_bootstrap_orchestration_snippets_split_execution_report.md`.

This current structure preserves the earlier repository-internal Step 1 -> Step 5 consistency result and keeps orchestration as thin workflow glue rather than a duplicate of `chatgpt-handoff-pilot` protocols. No delegated skill behavior changed, no `chatgpt-handoff-pilot` files were modified, and no validators, scripts, hooks, CI, automation, tests, tool adapters, adapters, or additional distribution surfaces were added by the post-merge refresh.

The P0 shared assessment output protocol closure has now added `skills/_protocol/skill_assessment_output.md` as a shared output-vocabulary layer for assessment / review / takeover style results. It defines `capability_fit`, optional `maturity_score`, `evidence`, `inference`, `open_questions`, `risk_priority`, `impact_scope`, and `next_action`, while explicitly separating task priority `P0` from `risk_priority` `P0/P1/P2`.

Core takeover / governance skills now reference that shared vocabulary, and audit / migration / status / handoff / workflow skills use thin or scenario-specific references. This moves the system from "assessment output vocabulary is inconsistent across skills" toward "a shared protocol exists for controlled adoption," without changing phase or turning the protocol into automation, validator, CI, router / pipeline logic, or execution control.

P1 adoption validation has now accepted the shared assessment protocol with light follow-up, and the P1 light follow-up has added protocol mini examples plus a `system-takeover` invocation snippet. The P1.5 `system-takeover` dogfood review concluded `Pass: protocol works for system-level takeover`, confirming that the fields can support system-level assessment output, separate `confirmed` / `inferred` / `pending` evidence, keep `risk_priority` distinct from phase / freshness vocabulary, and keep `maturity_score` optional / where applicable.

The June system status refresh kept the repository in `Phase 3 - Controlled System` and added a workflow-bootstrap capability signal: PR #10 and PR #11 are merged evidence, not branch-only or pre-merge work. `documentation-governance` still states that mutable project-status facts belong in declared current-state SSOT surfaces, so `docs/HANDOFF.md` and `docs/status/skill-hub-status.md` remain the active places for current phase, next-phase direction, latest validation, blocker, and pending-merge facts unless a maintainer deliberately declares another current-state SSOT.

The P1 closeout records PR #15, PR #16, and PR #17 as merged evidence for P1 examples coverage. It records invocation examples coverage for `chatgpt-handoff-pilot`, `project-takeover`, and `skill-governance`; it does not change prompt bodies, protocols, workflows, `.agents`, tools, registry/index files, docs/status ownership rules, or other skills.

## Hard Boundaries

- `skills/<skill>/` remains the only canonical source of truth inside the hub. No adapter layer may become a second authoritative source.
- `system-status-update` and `system-handoff` must remain wrapper skills. They may reuse canonical skills and add system-level output constraints, but they must not fork canonical logic.
- Workspace-aware or no-git status refresh extends evidence collection only. It must not promote workspace signals, bridge copies, readable derivatives, or other convenience surfaces into new authoritative system sources.
- `system-status-update` and `system-handoff` coordination must remain minimal: refresh status first, then merge handoff; keep a `14`-day freshness gate and phase consistency check, but do not introduce auto-trigger orchestration.
- In distributed business-project contexts, `.codex/skills/` is the runtime SSOT for local skill content. Project-local adapters must point to `.codex/skills/`, not back to hub `skills/` paths.
- `workflow-bootstrap` Phase 0-3 baseline guidance must remain canonical guidance only. It must not be presented as completed Phase 4 multi-project pilot work, distribution readiness, or authorization to expand the project-side file family by default.
- The `PJT_Derivative_Data` consumer adoption pilot is limited to read-only adoption audit and governance planning. No pilot implementation, user-level Bundle V1 change, Consumer Adoption Pattern V1 freeze, or rollout to another consumer repository is authorized.
- `workflow-bootstrap` owns workflow shell, role split, runtime profile, review tier guidance, and runtime pack manifest guidance. `chatgpt-handoff-pilot` owns task package, bounded execution, and execution report protocols.
- `workflow-bootstrap` is the project-level orchestration owner for dual-refresh and GitHub PR bootstrap prompting. It must not absorb `system-status-update`, `system-handoff`, or `chatgpt-handoff-pilot` protocol ownership.
- `system-status-update` owns system-level status-first linked refresh and the concise status baseline used by handoff.
- `system-handoff` owns the handoff receiver role and handoff output boundary; it consumes the status baseline but does not become a status engine.
- `financial-data-project-migration` keeps assessment and execution separated. Its templates describe generated task-package structure; they must not become embedded prompt rulebooks or a second execution protocol.
- `.agents/skills/*` remains thin wrapper / discovery surface and must not carry prompt bodies or canonical payload text.
- The PR #12 closeout remains documentation / prompt asset governance only. It does not authorize runtime tool changes, adapter changes, `.github/workflows/*` changes, tests, or additional P0 expansion.
- The P1 examples coverage work itself closed at PR #17 / `fd6cf10`. That closeout does not authorize more P1 example expansion, P2 implementation, workflow changes, `.agents` changes, tools / registry / index changes, prompt body changes, protocol changes, docs/status ownership changes, or broad skill restructuring.
- `skills/_protocol/skill_assessment_output.md` is a shared output vocabulary / assessment protocol. It is not an execution controller, validator, CI mechanism, router / pipeline integration, or auto-remediation path.
- `maturity_score` remains optional / where applicable and must not be forced onto status / handoff skills.
- `risk_priority` remains assessment output vocabulary. It must not be treated as a project phase gate or as a freshness / staleness label; `phase_risk` and `freshness_risk` remain status / handoff scenario vocabulary where applicable.
- P1.5 dogfood validates protocol usability only. It does not authorize protocol-field changes, validator / CI / automation work, router / pipeline integration, or mandatory scoring expansion.
- Mutable project-status facts must remain in declared current-state SSOT surfaces. README, docs index, technical onboarding, agent wrapper, and blueprint docs may point to HANDOFF/status, but they must not copy active phase status, next-phase decisions, latest validation results, blocker status, or pending-merge state into parallel durable summaries.
- Project-side runtime surfaces may be thin entries, adapters, or evidence indexes; they must not become a second rulebook or copy canonical skill bodies.
- `tasks/` may be a preferred project-local evidence path in non-git / low-git contexts, but it must not be written as a mandatory global path for all projects.
- Governance at the current stage is read-only. Consistency checks may detect drift, but they must not auto-fix, auto-delete, or silently rewrite adapters.
- Derivative-surface auditing and documentation-status coordination remain advisory/read-only. They may clarify drift, ownership, or operating order, but they must not auto-remediate, auto-sync, or redefine canonical skill contracts.
- Re-seed auditing remains preflight-only. Audit tooling may classify rollout readiness and identify hub repositories, but it must not silently execute reseed, sync, delete, or project mutation.
- Adapter layers exist for discoverability, not authorship. `.agents/skills/` and `.github/skills/` must remain derivative surfaces.
- AI / Human / Bridge documentation ownership must stay explicit. `docs/ai/` owns execution-facing protocol, `docs/human/` owns explanation-oriented repository guidance, and the bridge layer remains a mirror/exchange layer rather than a new active source.
- Existing bridge-layer references may serve navigation, mirror, or exchange semantics, but they must not become script, config, or runtime activation dependencies.
- Hub-local adapter wrappers and project-local adapters use different reference contracts. The hub may point thin wrappers back to `skills/`, while project-local governance checks must continue to validate adapters against `.codex/skills/` in distributed consumer repositories.
- Sync-back semantics stay constrained to canonical content recovery. Project-local adapters are not treated as editable upstream sources.
- Selective rollout control may narrow where distribution lands, but it must not redefine canonical ownership or promote adapter layers into authoring surfaces.
- `ai-skill-hub` itself is not a normal clean re-seed target. Hub self-detection is allowed as a protective boundary so the system repository is not misclassified as a consumer project.
- System evolution must preserve layer clarity: canonical definition, distribution surfaces, governance checks, and orchestration tooling cannot be collapsed into a single mutable layer.
- Repository-governance docs now belong under `docs/governance/`; compatibility or historical paths must not be treated as the active commit-policy source.
- Local commit governance is versioned through `.githooks/` plus `tools/install_git_hooks.ps1`, not through checked-in `.git/hooks/` content; each clone or worktree must opt in locally once.

## Key Design Decisions

- The hub keeps `skills/` as the sole canonical layer because duplicated skill content across adapters would create metadata drift and blur ownership.
- The system uses thin adapter surfaces instead of full adapter copies because discoverability is needed across AI entrypoints, but content duplication would weaken governance.
- System-level status and handoff are implemented as wrapper skills over canonical capabilities because the system needs standardized invocation semantics without introducing a second status engine or handoff framework.
- Workspace-aware/no-git refresh was added inside canonical `update-project-status` because status generation needed graceful degradation when Git is unavailable, but the repository still needed one canonical status engine rather than a parallel workspace-only wrapper path.
- Project distribution keeps `.codex/skills/` as the local runtime SSOT because business projects need a stable local skill-content root without becoming a second canonical hub.
- Project-local `.agents/.github` adapters are generated around `.codex/skills/` instead of copied from the hub because copied hub adapters would carry broken references and violate project-local path correctness.
- Governance starts with read-only drift detection because the current system priority is visibility and boundary control, not automatic mutation or destructive cleanup.
- Derivative-surface auditing was introduced as a read-only tool because bridge and metadata drift need visibility before the repository decides whether any stronger enforcement or sync policy is justified.
- Selective rollout was added at the sync layer because distribution control was needed, but the default path was preserved to avoid creating a second distribution policy surface.
- Re-seed readiness was added as a separate audit tool instead of being folded into the sync path because rollout preflight needs a read-only decision surface, not a hidden execution side effect.
- Hub self-detection stays conservative because boundary protection matters more than aggressive classification; it is better to miss some hubs than to misclassify ordinary projects as system repositories.
- Documentation was split into `docs/ai`, `docs/human`, and a bridge layer because protocol, explanation, and handoff/exchange assets serve different audiences and should not compete for ownership in the same file.
- Documentation-status coordination was documented as a minimum governance note because `documentation-governance` and `update-project-status` now intersect on artifact roles, but that intersection should clarify lanes rather than introduce a pipeline or controller layer.
- The mutable-status SSOT rule belongs in `documentation-governance` because document audits need to detect when durable overview or blueprint docs copy active state out of HANDOFF/status; the rule strengthens fact-source discipline without creating a new status engine.
- Bridge-reference cleanup remains audit-first because the current explicit bridge-layer references are documentation-facing; path switches should happen deliberately and only where the active source is clearer than the bridge-facing copy.
- Repository-wide bridge auditing now distinguishes direct path dependency from bridge semantics, mirror ownership, and historical context so later cleanup can stay evidence-driven instead of trying to erase every bridge mention.
- Adapter governance remains project-local by design because the distribution contract in consumer repositories is `.codex/skills` -> `.agents/.github`, while the hub itself still uses thin wrappers that point back to canonical `skills/`.
- The system remains phase-based because capability maturity is uneven across layers; canonical definition is already stable, while governance enforcement and orchestration still need controlled progression.
- For Phase 2 runtime-pack entry planning, canonical guidance now treats `AGENTS.md` as the preferred thinnest project-side primary-entry draft and `.github/copilot-instructions.md` as a Copilot-specific thin adapter draft, with explicit canonical-backreference/no-second-rulebook constraints kept at draft level only.
- A single-profile validation sketch was added before any real implementation pilot because the repository needed one more bounded check that the thin entrypoint pair and placeholder/backreference model remain workable in a plausible consumer-repo shape without prematurely binding to a real target repository.
- Phase 3B kept field / placeholder mapping inside the main pilot validation sketch because the current design was still readable in one document; avoiding an extra split helps preserve the anti-second-rulebook goal even at sketch level.
- The new workflow-bootstrap baseline uses role names rather than tool names as canonical guidance because tools are replaceable adapter examples, while the role chain is the portable workflow shell.
- Review tiers are advisory Reviewer guidance because risk-based task-package review needs a shared vocabulary without becoming CI, validator, or hard-gate enforcement.
- Runtime pack minimal manifest guidance is project-aware and optional because Git-first and non-git / low-git projects need different evidence paths while still preserving the same canonical ownership boundary.
- Repository-governance docs were split into `docs/governance/` because commit policy and similar cross-repository rules now deserve an explicit canonical home instead of remaining mixed into the human explanation layer.
- Local commit validation is installed via a versioned `.githooks/commit-msg` plus `tools/install_git_hooks.ps1` path because Git hook activation is clone-local by design; shipping the hook definition in-repo preserves consistency, while per-clone installation keeps the mechanism aligned with Git's local-hook model.
- `export_bundle.ps1` reuses the same validator as the local `commit-msg` hook because auto-commit paths should obey the same commit convention instead of creating a second commit-policy surface.
- The shared assessment protocol remains an output vocabulary rather than an execution controller because P1/P1.5 evidence shows examples and review discipline are currently enough to support system-level assessment without enforcement.
- PR #12 keeps prompt / template / example entrypoints inside their owning canonical skill assets so discovery improves without creating new runtime ownership. The first-batch P0 cleanup is complete, and any further example coverage belongs to P1 rather than an expanded P0.

## Intentional Gaps

- No auto-fix for adapter drift.
- No CI-backed enforcement for adapter consistency yet.
- No expansion of governance into destructive sync, delete, or rewrite behavior.
- No orchestration or controller layer around `system-status-update` and `system-handoff`.
- No auto-remediation path for derivative-surface drift; the new audit remains inspect-first and read-only.
- No auto-reseed or auto-remediation path inside the re-seed audit tool.
- No aggressive hub fingerprinting beyond a conservative strong-signal guard.
- No redesign of metadata generation or adapter schema in this phase.
- No promotion of project-local adapters into upstream authoring surfaces.
- No attempt to turn heuristic routing and sequencing into a fully deterministic orchestration stack in the current phase.
- No automatic mode detection in `check_adapter_consistency.py`; hub and consumer validation are now explicitly separated, but the operator still has to choose the correct mode.
- No attempt to make routing deterministic beyond the explicit-name/system-intent fix; `system-takeover` misrouting is corrected, but the router is still intentionally heuristic rather than controller-like.
- No broader bridge-path migration plan beyond the compatibility-entry cleanup completed in this pass; any further bridge copy cleanup should still be deliberate rather than automatic.
- No repository-level mirror consistency checker yet; bridge mirrors remain manually maintained even though current repo-wide auditing shows no runtime/config dependency on them.
- No enforced runtime schema or automation layer for documentation-status coordination; the current note is guidance for operators, not a new system controller.
- No automatic hook enablement across fresh clones or worktrees; `tools/install_git_hooks.ps1` must still be run locally once per clone/worktree.
- No decision yet to tighten commit body rules beyond the current lightweight descriptive check; that boundary should continue to follow real usage feedback rather than speculative policy growth.
- No CI-backed default validation flow yet; `tools/run_local_checks.ps1` is now the default local entrypoint, but it remains a local wrapper rather than repository-level enforcement.
- Phase 4 Round 1 read-only multi-project pilot review has completed, but full Git-first validation remains incomplete because the external Git-first candidate's Git metadata was blocked by dubious ownership.
- No broader project-side runtime-pack family rollout beyond thin-entry guidance; `.github/instructions/*.instructions.md` and `.github/agents/*.agent.md` remain unimplemented and out of default scope.
- No distinct project-local canonical payload artifact exists yet in the current repo; the controlled placeholder remains intentionally unresolved until a maintainer-confirmed artifact actually appears.
- No complete validation yet across multiple project types; Round 1 covered Git-first and non-git / low-git candidates as read-only evidence, but a follow-up should specifically close the Git-first evidence gap before any broader portability claim.
- The consumer adoption pilot is authorized only for read-only audit and governance planning; no implementation, broader rollout, or frozen Consumer Adoption Pattern V1 exists yet.
- No refresh of `skills_index.json` in this workflow-bootstrap pass; that deferral is intentional because the current generation chain would also rewrite `.agents/skills/*.md` flat summaries and widen the bounded-execution scope.
- No expansion of local validation and check tooling into an automated distribution, rollout, or execution framework; the repository still treats those tools as repeatable local support surfaces rather than a stronger controller layer.
- No `tool_adapters/`, validators / automation / CI, `.github/instructions/`, `.github/agents/`, Phase 5 tool adapter candidates, or Phase 6 validator / automation preflight work has started.
- No consumer-repository implementation or broader distribution / rollout has started; the current `Derivative_Data` pilot remains limited to read-only adoption audit and governance planning.
- No automation, validators, CI, router / pipeline integration, broader scoring rollout, or auto-remediation was added for the shared assessment output protocol.
- No mandatory `maturity_score` policy exists for status / handoff skills; scoring remains optional / where applicable.
- No validator / CI / automation escalation is justified by the P1.5 dogfood alone; cross-executor consistency should be observed through future real outputs first.
- No handoff/status requirement exists to mirror every assessment finding; status and handoff remain minimal closure surfaces rather than per-task evidence logs.
- No automated mutable-status fact checker has been added. The new documentation-governance rule clarifies the boundary, but detection and remediation remain audit/report driven unless a future task explicitly authorizes stronger validation.
- No additional P1 examples coverage remains open in this line.
- No P2 planning / backlog-selection task package has started yet.
- No P2 implementation, workflow changes, `.agents` changes, tools / registry / index changes, prompt body changes, protocol changes, or broad skill restructuring has started.

These gaps are intentional to keep the system legible while distribution and governance semantics are still being stabilized.

## Next Phase Direction

The immediate program direction is the `CONSUMER_REPOSITORY_ADOPTION_PILOT`, beginning with the `PJT_Derivative_Data` read-only adoption audit and governance planning. The expected output is a `CONSUMER_ADOPTION_DECISION` and, only if a change is required, a bounded task package. Pilot implementation, broader rollout, and a frozen Consumer Adoption Pattern V1 remain unauthorized or pending validation.

The workflow-bootstrap line's separate next direction remains Phase 4 Round 2 planning focused on the Git-first evidence gap from Round 1. It should use a separately reviewed task package or explicit maintainer-provided Git evidence, not direct implementation.

Round 1 findings should remain validation evidence only. Any future feedback loop must return only generalized guidance to canonical assets and must not import project-specific paths, business facts, secrets, or environment commands into the hub.

Tool adapters, validators / automation / CI, `.github/instructions/`, `.github/agents/`, Phase 5 tool adapter candidates, and Phase 6 validator / automation preflight remain deferred. Phase 4 Round 2 remains pending until it has a separately reviewed task package or explicit maintainer-provided Git evidence.

The orchestration snippets consistency closure and PR #11 focused-asset split do not require every future workflow-bootstrap task to use the full Step 1 -> Step 5 chain. The focused orchestration assets should remain available thin orchestration patterns, with `chatgpt-handoff-pilot` continuing to own task package, bounded execution, and execution report protocol details.

The shared assessment output protocol should next be treated as controlled adoption and repeatability improvement. Future work may observe how consistently skills use `evidence`, `inference`, `open_questions`, `risk_priority`, `impact_scope`, and `next_action`, but that follow-up should not be framed as enforcement, automation, or a requirement to force `maturity_score` onto every skill.

Future system-level reviews may reuse the P1.5 finding template to compare executor consistency across `confirmed` / `inferred` / `pending`, `risk_priority`, `impact_scope`, and `next_action`. Any later move toward validator / CI / automation should require multiple real outputs showing repeatable drift that examples and review discipline cannot absorb.

Documentation maintenance should treat HANDOFF/status as the current-state SSOT pair for mutable system facts. Future docs work may add links or short pointers from README, technical onboarding, agent wrappers, and blueprint docs, but should avoid copying active phase, next-phase, validation, blocker, or pending-merge state unless a maintainer first declares a new current-state SSOT.

Documentation follow-up should prioritize dogfooding and maintenance discipline for the new catalog/registry indexes (for example, using them during the next real skill change and observing upkeep friction) before considering candidate-promotion protocol work, validators, or automation.

The separate workflow-bootstrap line remains closed after P1 and must not expand P1; any P2 work should begin as a separate planning / backlog-selection round with its own reviewed task package, starting from read-only inventory and explicit scope boundaries. The current program direction is the read-only Consumer Adoption Pilot recorded above.

## Recommended Next Actions

1. Execute the authorized read-only adoption audit and governance planning for `PJT_Derivative_Data`.
2. Return a `CONSUMER_ADOPTION_DECISION` and create a bounded task package only if a change is required.
3. Keep pilot implementation and other consumer-repository rollout unauthorized until separately approved.
4. Keep Consumer Adoption Pattern V1 unfrozen and preserve the actual Bundle V1 installation boundary.

## System Takeover Snapshot (2026-04-02)

### System Structure

- Canonical source: `skills/` remains the only authoritative layer for skill content and execution contracts.
- Invocation protocol: `docs/ai/` now explicitly owns execution, invocation, and discovery rules for AI agents.
- Discovery adapters: `.agents/skills/` and `.github/skills/` expose thin entrypoints back to canonical skills for multi-AI discoverability.
- Orchestration helpers: `tools/skill_router.py` and `tools/skill_pipeline.py` provide lightweight routing and sequencing based on metadata, aliases, and heuristic follow-up rules.
- Distribution and maintenance tools: sync, bundle, metadata, governance check, and re-seed audit tools sit in `tools/`.
- Governance and regression evidence: repository tests cover structure, routing, sync DryRun semantics, adapter consistency smoke, and re-seed audit behavior.
- Human/bridge surfaces: `docs/human/` explains the repository to maintainers, while the bridge layer mirrors key exchange assets without taking ownership from the active sources.

### Capability Map

- `template`: `chatgpt-handoff-pilot`
- `audit`: `documentation-governance`, `file-structure-check`
- `project`: `financial-data-project-migration`, `project-takeover`, `update-project-status`
- `governance`: `skill-governance`
- `system`: `system-handoff`, `system-status-update`, `system-takeover`

The current map is strong on takeover, status, documentation, structure, and distribution-governance workflows. It is still comparatively thin on deterministic orchestration, CI-backed enforcement, and hub-specific governance diagnostics.

### Maturity Assessment

- Capability Map: `stable-to-evolving`. The hub has ten named skills with clear categories and system wrappers, and the canonical/adaptor split is deliberate.
- Invocation Readiness: `stable`. Explicit AI-facing protocol docs and thin wrapper entrypoints make invocation rules legible and reusable.
- Routing Layer: `evolving`. A direct runtime check on `请使用system-takeover接管该项目` still selected `project-takeover`, which shows system-intent matching is not yet robust enough.
- Pipeline Layer: `evolving`. Sequencing exists and can attach follow-up skills, but it remains a lightweight ordered helper rather than a dependency-aware orchestration engine.
- Adapter Layer: `stable` for discoverability, `context-sensitive` for governance. Hub wrappers correctly point to canonical `skills/`, while consumer-project governance expects `.codex/skills` references.
- Tooling / Governance: `evolving`. The toolchain is broad and repeatable, but governance remains local and read-only rather than CI-enforced or hub-aware by default.
- Documentation / Handoff: `stable-to-evolving`. Ownership is much clearer after the AI/Human/Bridge split, and repo-wide auditing shows active docs no longer depend on bridge paths directly, but bridge continuity still depends on disciplined manual upkeep.

### Top Bottlenecks

- System-skill routing is underweighted. Explicit `system-takeover` intent can still collapse into generic `project-takeover`.
- Governance tooling is split by context but not yet explicit in interface. The same repository can look healthy as a hub and unhealthy under consumer-project adapter rules unless the operator already knows the difference.
- Validation is still mostly local. `pytest` was not available in the current interpreter, and the system still relies heavily on local scripts and human context rather than enforced repository-level checks.
- The compatibility entry in `AI_USAGE.md` now points to root `SKILLS_INDEX.md`, reducing bridge-path coupling while preserving the same navigation outcome.
- Remaining bridge references are mostly semantic or historical. That is lower risk than direct path dependency, but it also means future mirror shrink should happen through deliberate refreshes instead of cleanup-only rewrites.

### Evolution Plan

- Add a hub-aware governance mode or a separate hub-health checker so hub-local wrappers and project-local adapters are not assessed through the same reference contract.
- Strengthen router aliases, trigger weighting, or explicit-name matching so system wrappers win when the task explicitly names them.
- Continue to switch or preserve bridge-facing compatibility links intentionally instead of treating bridge copy cleanup as a blind documentation move.
- Promote the most important routing, governance, and documentation ownership checks into a standard repeatable validation path, ideally without turning the system into an auto-mutating controller.
