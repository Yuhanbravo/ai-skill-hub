# Task Package: Heterogeneous Review and Work Item Roadmap v1

## 1. Task Identity

- Task id: `HETEROGENEOUS-REVIEW-WORK-ITEM-ROADMAP-V1`
- Repository: `ai-skill-hub`
- Task type: `DOCS_ONLY_ROADMAP`
- Current authorization: `ROADMAP_DOCUMENTATION_ONLY`
- Recommended branch: `docs/heterogeneous-review-work-item-roadmap-v1`
- Package status: ready for independent review after this bounded round

This package authorizes the two documentation artifacts listed below. It does not authorize implementation of any future phase described by the Roadmap.

## 2. Exact Baseline

```text
Repository= D:\dev\ai-skill-hub
Starting_Branch= main
Starting_HEAD= 6707cb345d4422844a7b601bf7253634b3b9f92b
Starting_Local_Main= 6707cb345d4422844a7b601bf7253634b3b9f92b
Starting_Origin_Main= 6707cb345d4422844a7b601bf7253634b3b9f92b
Starting_Actual_Remote_Main= 6707cb345d4422844a7b601bf7253634b3b9f92b
Starting_Ahead_Behind= 0 0
Working_Tree= clean
Staging= empty
Git_Operation= none
Active_Task_Package= NONE
```

The working branch for implementation is `docs/heterogeneous-review-work-item-roadmap-v1`. The baseline facts above were rechecked immediately before branch creation; they are not inherited from the earlier blocked round.

## 3. Goal

Create a version-controlled, reviewable Roadmap for:

- heterogeneous model review with Codex as the usual implementer;
- evidence-based external review and frozen-commit provenance;
- lightweight Work Item and Session management;
- future automation gates that do not manage every conversation.

Create the Roadmap and its bounded docs-only task package in the same round, following the repository precedent that a direction-setting Roadmap and its implementation package may land together while remaining separate in responsibility.

## 4. In Scope

Only:

1. Create `docs/design/heterogeneous-review-and-work-item-roadmap.md`.
2. Create `docs/task_packages/heterogeneous_review_and_work_item_roadmap_v1_task_package.md`.
3. State current capabilities, ownership boundaries, target layering, management levels, C3–C7 gates, stop conditions, non-goals, future references, and a decision log.
4. Record the exact baseline and validation plan in this package.
5. Perform read-only consistency checks after writing.

The Roadmap must distinguish current facts, future candidates, and authorization. Future candidate artifacts must be labeled `FUTURE_CANDIDATE_NOT_AUTHORIZED` where applicable.

## 5. Out of Scope

Do not:

- create or modify any Skill;
- implement a Work Item registry, JSONL store, database, Web UI, script, state machine, validator, hook, CI, or automation;
- run or integrate multi-model Review;
- collect private sessions or all chat transcripts;
- change ChatGPT, Kimi, VS Code, Codex, or other terminal titles;
- modify `AGENTS.md`, `docs/HANDOFF.md`, `docs/status/**`, `skills/**`, `tools/**`, tests, scripts, adapters, indexes, or bridge copies;
- modify any business repository;
- create a project-side runtime pack;
- copy an external Skill implementation;
- merge, push, or create a PR;
- declare `ROADMAP_FROZEN`, `C3_COMPLETE`, `C4_AUTHORIZED`, `C5_AUTHORIZED`, or implementation completion.

## 6. Authorized Paths

```text
docs/design/heterogeneous-review-and-work-item-roadmap.md
docs/task_packages/heterogeneous_review_and_work_item_roadmap_v1_task_package.md
```

No other paths are authorized for writing. The source branch may be created for this round, but no merge or remote publication is authorized.

## 7. Required Inputs

Read before implementation:

- `AGENTS.md`.
- `docs/HANDOFF.md`.
- `docs/status/skill-hub-status.md`.
- `skills/workflow-bootstrap/SKILL.md`.
- `skills/chatgpt-handoff-pilot/SKILL.md`.
- `skills/codex-project-workflow/SKILL.md`.
- `skills/update-project-status/SKILL.md`.
- `docs/task_packages/codex_project_workflow_c3_pilot_design_task_package.md`.

Also inspect existing Roadmap/design/task-package conventions and search for equivalent heterogeneous-review, Work Item, Session, provenance, transcript, or conversation-management entries before adding files.

## 8. Acceptance Criteria

### Roadmap coverage

The Roadmap must include:

- Problem Statement.
- Design Principles.
- Existing Capability Map.
- Target Architecture and data ownership.
- L0/L1/L2 Management Levels.
- C3, C4, C5, C6, and C7 phases.
- Per-phase entry evidence, approval, pause/cancel conditions, and completion evidence where meaningful.
- Global stop conditions.
- Explicit Non-goals.
- External References as future research candidates only.
- Decision Log with C3 priority and deferred C4–C7 implementation.

### Boundary and truthfulness

- `workflow-bootstrap`, `chatgpt-handoff-pilot`, `codex-project-workflow`, `update-project-status`, business repositories, AI terminals, and future `ai-workbench` ownership remain distinct.
- `ai-workbench` is not described as an implemented capability.
- C4–C7 are not presented as authorized or completed.
- Formal Review is tied to a frozen reviewed commit; finding decisions are evidence-based rather than vote-based.
- The Roadmap does not create a second handoff protocol or imply that conversations are the project SSOT.
- External references are not copied or claimed as comprehensively verified.

### Scope

- The exact changed paths are the two authorized docs paths only.
- No prohibited path is modified or created.
- No sensitive information, credentials, private session data, or unnecessary environment detail is included.

## 9. Validation Commands

Run after writing:

```powershell
git diff --check
git status --short
git diff --stat
git diff --name-only
git diff -- docs/design/heterogeneous-review-and-work-item-roadmap.md
git diff -- docs/task_packages/heterogeneous_review_and_work_item_roadmap_v1_task_package.md
```

Also perform read-only content checks:

```powershell
rg -n "FUTURE_CANDIDATE_NOT_AUTHORIZED|C3_PRIORITY|C4|C5|C6|C7|Explicit Non-goals|Decision Log" docs/design/heterogeneous-review-and-work-item-roadmap.md docs/task_packages/heterogeneous_review_and_work_item_roadmap_v1_task_package.md
rg -n -i "password|secret|token|cookie|credential|private session|api key" docs/design/heterogeneous-review-and-work-item-roadmap.md docs/task_packages/heterogeneous_review_and_work_item_roadmap_v1_task_package.md
```

The sensitive-term check is an inspection aid. Expected matches must be boundary language only; no secret value or private data may be present.

## 10. Stop Conditions

Stop before writing if:

- the baseline, branch, remote, or working-tree facts no longer match the recorded preflight;
- a duplicate Roadmap or equivalent canonical entry is found;
- a local rule requires a separate package-only round;
- the two-file allowlist is insufficient to satisfy acceptance without touching another path;
- a claim would require unverified external research or private platform access;
- the work would authorize implementation, automation, registry storage, or business-repository changes;
- any unrelated file changes appear during the round.

If stopped, report `BLOCKED_HETEROGENEOUS_REVIEW_AND_WORK_ITEM_ROADMAP_PREFLIGHT` and do not widen scope.

## 11. Expected Report

The final report must state:

- decision and exact baseline;
- working branch;
- created and modified paths;
- same-round Roadmap/task-package stage-gate rationale;
- validation commands and results;
- ownership and scope checks;
- explicit non-implementation list;
- risks and assumptions;
- recommended independent review next step.

The report must not claim Roadmap freeze, C3 completion, C4/C5 authorization, merge, push, or PR creation.

## 12. Next Gate

```text
INDEPENDENT_DOCS_REVIEW
```

After independent review, a separate task package is required before implementing C4 heterogeneous-review protocol work, C5 registry mechanics, C6 transcript adapters, or C7 reviewer harness automation.
