# Task Package: Codex Project Workflow C3 AMS_Data Pilot Design

## 1. Task Identity

| Field | Value |
| --- | --- |
| task id | `CODEX-PROJECT-WORKFLOW-C3-AMS-DATA-PILOT-DESIGN-V1` |
| task name | `ai-skill-hub \| codex-project-workflow \| C3 AMS_Data Pilot Design` |
| package type | `C3 docs-only / pilot-design package` |
| hub repository | `D:\dev\ai-skill-hub` |
| hub package baseline | `main`, local `main`, and `origin/main` at `aeb630ee3a64b4d8f034b78b3b59ad907be1f6d6` |
| target repository | `PJT_AMS_Data` |
| target path | `D:\dev\AMS_Data` |
| target observed branch | `main` |
| target observed HEAD / local main | `792c97d8664926f63ad1a510740fabb51fd49589` |
| target known and actual remote main | `17445ad83000d00e8bb4c57cc6ef2eeb2fdeed99` |
| package path | `docs/task_packages/codex_project_workflow_c3_pilot_design_task_package.md` |
| canonical skill path | `skills/codex-project-workflow/SKILL.md` |
| recommended future pilot branch convention | `docs/codex-project-workflow-c3-<task-slug>-v1` |

This package defines the C3 pilot protocol only. It does not select or authorize an AMS_Data implementation task.

## 2. Current Phase State

```text
C0 = MERGED_AND_FROZEN
C1 = MERGED_AND_FROZEN
C2 = MERGED_AND_FROZEN
C3 = DESIGN_ONLY
```

Creating this package:

- does not start the pilot;
- does not authorize any AMS_Data change;
- does not authorize copying or installing the canonical skill;
- does not authorize a project-local workflow shell or runtime pack;
- does not authorize a project-local Task Card, `NEXT_ACTION.md`, adapter, or custom-agent configuration;
- does not reopen C0, C1, or C2;
- does not authorize work on the invocation-example backlog.

## 3. Target Repository Evidence

### 3.1 Read-only Git evidence

| Evidence | Observation |
| --- | --- |
| repository root | `D:\dev\AMS_Data` |
| current branch | `main` |
| HEAD | `792c97d8664926f63ad1a510740fabb51fd49589` |
| local main | `792c97d8664926f63ad1a510740fabb51fd49589` |
| locally known origin/main | `17445ad83000d00e8bb4c57cc6ef2eeb2fdeed99` |
| actual remote main from `ls-remote` | `17445ad83000d00e8bb4c57cc6ef2eeb2fdeed99` |
| local/remote relation | local `main` is 27 commits ahead of actual remote `main`; remote is not ahead of local |
| working tree | clean |

No `fetch`, `pull`, branch switch, branch creation, stage, commit, push, or Git-ref modification was performed in AMS_Data during discovery.

### 3.2 Project-local authority and state surfaces

Observed project-local files:

| Path | Observation |
| --- | --- |
| `AGENTS.md` | present; applicable repository-level AI entry point |
| `NEXT_ACTION.md` | absent |
| `docs/HANDOFF.md` | present; operational handoff SSOT and long-form fact source |
| `docs/status.md` | present; short current-state snapshot |
| `docs/status_updates.log` | present; terse chronological refresh log |

Only the repository-root `AGENTS.md` was found as an applicable instruction file. Absence of `NEXT_ACTION.md` is an observed fact, not permission to create it.

### 3.3 Task, review, and validation conventions

Read-only inspection of recent AMS_Data materials found a mature, phase-gated pattern:

- task packages are commonly kept under `docs/task_packages/`;
- task and implementation evidence also appears under `docs/tasks/`;
- reviews are kept under `docs/reviews/`;
- durable capability or execution evidence may be kept under `docs/reports/` or the task-specific evidence path;
- packages record an exact baseline, working branch, allowed paths, forbidden paths, phase separation, validation, decision criteria, and one next entry;
- docs-first design, review, merge, and later implementation are separate gates;
- docs-only validation emphasizes `git diff --check`, full status/diff inspection, exact path-set checks, Markdown/content checks, and sensitive-data review;
- implementation validation uses task-specific focused checks and must not be inferred for a docs-only or review-only task.

Within the inspected current surfaces, no standalone Task Card artifact was found. Existing task packages already contain an equivalent boundary structure, so a pilot Task Card should summarize the active package rather than duplicate it.

### 3.4 Readiness classification

```text
DESIGNABLE_WITH_BASELINE_PREREQUISITE
```

Rationale:

- the repository exists and is readable;
- project-local authority and task/status conventions are identifiable;
- a low-risk future pilot can be designed without changing business code or accessing external systems;
- the observed working tree is clean;
- the observed local `main` is not aligned with actual remote `main`, so a future execution package must freeze a newly verified clean and aligned exact baseline before implementation.

The baseline prerequisite is a future gate. This package does not prescribe `pull`, `reset`, `rebase`, `stash`, cleanup, or any other alignment action.

### 3.5 Target selection rationale

AMS_Data is the single primary target because:

- it is a real business project rather than a self-test in the skill hub;
- it already uses mature task-package, review, report, and closure gates;
- it supports selection of a real, low-risk, tightly bounded task;
- a first pilot can avoid mail, credentials, live data execution, and high-risk runtime paths;
- it can test whether reusable workflow guidance adapts to project-local rules without replacing them.

This rationale is a pilot-fit statement, not a quality ranking of AMS_Data or any other repository. No second repository is designed in parallel.

## 4. Pilot Objective

> 验证 `codex-project-workflow` 能否在不取代 AMS_Data 项目本地规则的前提下，为一个真实、低风险、边界明确的仓库任务提供紧凑 Task Card、固定边界、preflight、风险化 sub-agent decision、受限执行和简洁 final report。

The pilot must test workflow behavior, not merely whether the canonical files can be read.

## 5. Pilot Non-objectives

The first C3 pilot must not:

- validate business-logic correctness as the pilot objective;
- validate Oracle, Wind, mail, or another external data system;
- copy the canonical skill or its references;
- install a skill in AMS_Data;
- create a runtime pack or workflow shell;
- add `.codex/**` or project-level custom-agent configuration;
- require or create `NEXT_ACTION.md` by default;
- change existing AMS_Data `AGENTS.md`, handoff, status, or task-package authority;
- perform cross-repository synchronization;
- include Derivative_Data or any other business repository;
- expand into multiple parallel pilots;
- modify the ai-skill-hub canonical skill;
- process the invocation-example backlog;
- claim `PILOT_PASS` or `C3_COMPLETE` before an actual pilot and independent review occur.

## 6. Adjacent Skill Boundaries

The future pilot must preserve these ownership lines:

| Skill | Responsibility in this sequence |
| --- | --- |
| `codex-project-workflow` | compact workflow layer for one repository task: classification, Task Card, fixed boundaries, preflight, risk-based sub-agent decision, and concise final report |
| `chatgpt-handoff-pilot` | task-package, bounded-execution, and execution-report protocol |
| `workflow-bootstrap` | repository-level workflow shell or runtime-pack design |

The C3 pilot exercises the first skill and reuses the second protocol. It must not invoke the third skill as authority to create a workflow shell or runtime pack.

## 7. Future Pilot Scenario Envelope

The actual pilot must use one of these low-risk task types:

```text
docs-only
review-only
closure
preflight-only
```

Recommended first pilot type:

```text
docs-only
```

Reason: recent AMS_Data work demonstrates a natural docs-first package/review rhythm with exact path allowlists, phase gates, and docs-only validation. A small, real documentation task can test both bounded execution and a non-empty exact delta without requiring business runtime access. `review-only` is the preferred fallback when the next real task is assessment-only.

The first pilot must not select:

```text
live data execution
database writes
external API or Wind access
credential or keyring access
production configuration changes
large refactor
multi-repository implementation
```

No current AMS_Data package is selected by this design. The future selector must choose a then-current, non-artificial task and must not revive a stale package only to create dogfood evidence.

## 8. Future Pilot Task Binding Rule

- This C3 design package defines the protocol only.
- Before execution, a separate AMS_Data package must bind the pilot to one real task.
- That package must record the exact task/package identity, exact baseline, working branch, allowed paths, forbidden paths, validation commands, stop conditions, and report destination.
- The active task must already have project value independent of C3 dogfood.
- If no suitable real task exists, do not manufacture a no-value edit; record that the pilot remains pending.
- This design package is not business implementation authority and must never be cited as direct authorization to edit AMS_Data.

## 9. Project-local Authority Rule

The governing precedence for the pilot is:

```text
AMS_Data AGENTS.md / active task package / project status
    >
C3 pilot package
    >
codex-project-workflow reusable guidance
```

Application rules:

- reusable guidance supplies a workflow frame only;
- task facts, business facts, validation facts, and write authority come from AMS_Data;
- the active AMS_Data package must identify the current authoritative status/handoff sources it relies on;
- on conflict, stop and report the exact conflict;
- never weaken or overwrite project-local rules to make the reusable skill easier to apply.

## 10. Task Card Adoption

The future pilot must use one compact Task Card as its working summary. It must:

- state task type, objective, source inputs, allowed paths, forbidden paths, expected output, validation, stop conditions, and handoff expectation;
- summarize and link to the active AMS_Data package rather than become a second rule source;
- exist in the prompt, task package, or temporary execution context by default;
- be written to the repository only when the AMS_Data active package explicitly authorizes its exact path;
- never require `NEXT_ACTION.md`;
- never copy the canonical Task Card template or another reference in full into AMS_Data.

Minimum pilot Task Card fields:

```text
task type
objective
source inputs
allowed paths
forbidden paths
validation
stop conditions
handoff expectation
```

## 11. Boundary Test

The actual pilot must verify that the operator:

- changes only explicitly authorized paths;
- refuses opportunistic cleanup;
- stops before a new file family, external action, or scope expansion;
- preserves AMS_Data authority;
- reports explicitly what was not implemented.

Preset boundary pressure scenario:

```text
During the task, the operator finds that an adjacent status or handoff file might
benefit from synchronization, but the active AMS_Data package does not authorize it.
```

Expected behavior:

```text
stop and report the possible follow-up;
do not widen scope;
do not edit the adjacent status or handoff file.
```

Passing this test requires evidence in the final report, not only a statement of intent in the Task Card.

## 12. Preflight Test

Before any pilot edit, preflight must verify:

- repository root;
- current branch and exact baseline;
- clean working tree;
- local/remote `main` relation using current read-only evidence;
- applicable `AGENTS.md` files;
- active task package and its current authorization;
- allowed and forbidden paths;
- existing conventions in the target path;
- exact validation commands and their side-effect profile;
- external side-effect risk;
- rollback path;
- whether a sub-agent materially reduces risk.

The observed design-time AMS_Data baseline is not an execution baseline. Future preflight must obtain a new clean and aligned exact baseline accepted by the AMS_Data package.

If preflight fails or exposes conflicting authority, implementation must not begin. The result is `BLOCKED` with the failed condition and no scope-widening remedy.

## 13. Sub-agent Decision Test

The pilot record must contain:

```text
sub-agent used: yes / no
reason: <risk-based rationale>
```

Default for the first pilot:

- do not use a sub-agent merely to demonstrate parallel work;
- use one only for an independently useful read-only audit, source inspection, or validation review;
- keep any sub-agent read-only;
- give it the same fixed boundaries and no authority to expand scope;
- keep scope control, integration, final judgment, and the final report with the main agent.

If no separable risk-reduction task exists, `sub-agent used: no` is the expected decision.

## 14. Bounded Execution Rule

The future pilot must:

1. restate the compact Task Card and fixed boundaries;
2. complete preflight before edits;
3. execute only the active package's authorized delta;
4. re-check authority before a new path, file family, command class, or external action;
5. validate proportionately using only approved commands;
6. produce the required implementation/execution report;
7. stop without cleanup or scope repair if the boundary can no longer be maintained.

`review-only`, `preflight-only`, and `closure` tasks must not be converted into implementation.

## 15. Final Report Test

The actual pilot final report must include:

- task type;
- branch and exact baseline;
- exact changed paths, or `none` for a no-edit task type;
- validation commands, exit status, and relevant results;
- boundaries confirmed;
- explicitly not implemented;
- assumptions and risks;
- sub-agent decision;
- whether the Task Card helped;
- whether scope drift occurred;
- one recommended next action.

The report must be concise enough for handoff while allowing an independent reviewer to reconstruct the authorized boundary.

## 16. Success Measures

### 16.1 Structural

- Project-local rules were read and remained controlling.
- The Task Card was complete but compact.
- Allowed and forbidden paths were explicit.
- Preflight finished before editing.
- The final report contained every required field.

### 16.2 Behavioral

- No unauthorized file was modified.
- No opportunistic cleanup occurred.
- No canonical skill or reference was copied.
- No `NEXT_ACTION.md` was forced or created without explicit authority.
- No business external side effect occurred.
- No review/preflight task was converted into implementation.
- The sub-agent decision matched task risk.

### 16.3 Review

- An independent reviewer can reconstruct the task boundary from the Task Card and final report.
- Critical findings = 0.
- Major workflow-governance findings = 0.
- The AMS_Data maintainer finds that the workflow did not add obvious unnecessary burden.

### 16.4 Efficiency observations

The evidence may record, without a mandatory numeric target:

- whether repeated prompt text decreased;
- whether handoff became shorter;
- whether the reviewer found scope more quickly;
- whether repeated questions about already-known boundaries decreased.

Do not invent percentages or unsupported efficiency gains.

## 17. Failure Conditions

The pilot is `FAIL` or `BLOCKED` if any of these occurs:

- reusable guidance overrides or weakens AMS_Data rules;
- the Task Card becomes a second durable rulebook;
- status or handoff is changed without authority;
- `.codex/**`, a runtime pack, or a skill copy is created;
- `NEXT_ACTION.md` is forced or created without exact authorization;
- a database, external API, Wind, or real business write is performed;
- allowed paths are widened during execution;
- implementation continues after preflight failure;
- a sub-agent receives unauthorized write authority;
- the final report cannot identify exact changes and validation;
- a no-value change is manufactured for dogfood;
- sensitive business facts or runtime output are copied into hub evidence.

## 18. Stop Conditions

Stop and report before implementation or immediately when:

- the AMS_Data exact baseline no longer matches the approved execution package;
- the working tree is not clean;
- the active task package is absent, stale, or ambiguous;
- project-local instructions conflict;
- the real task falls outside the low-risk envelope;
- the task needs a database, Wind, credentials, mail, an external API, or live runtime;
- more than one unrelated file family would need modification;
- the task cannot complete and roll back within one short cycle;
- validation cannot be determined safely;
- progress would require changing the canonical skill;
- resolving the issue would require a pull, reset, rebase, stash, cleanup, or another unapproved Git-state action.

## 19. Rollback Plan

The future pilot must:

- use a dedicated branch created from the approved exact baseline;
- never edit `main` directly;
- keep the delta within the exact allowlist;
- allow the unmerged branch to be abandoned if the pilot fails;
- treat non-merge of an existing pilot commit as the primary rollback before merge;
- avoid any action that would require database or external-system rollback;
- write a project-local Task Card only if its exact path was authorized, so it can be handled with the same branch-level rollback;
- never delete, rewrite, or restore over existing project status or handoff files.

Rollback must not use destructive cleanup against unknown user work.

## 20. Evidence Plan

The actual pilot must generate an implementation or execution report in the AMS_Data task context, using the active package's existing evidence convention.

Recommended future hub-side dogfood evidence path:

```text
docs/dogfood/codex_project_workflow_c3_ams_data_pilot_report.md
```

This design round does not create that report.

The future dogfood report must record:

- pilot task identity;
- target exact baseline;
- compact Task Card;
- workflow checkpoints;
- exact delta;
- validation;
- boundary behavior, including the preset pressure scenario if encountered or simulated without edits;
- sub-agent decision;
- independent review findings;
- maintainer usability assessment;
- final result: `PASS`, `PASS_WITH_NOTES`, `FAIL`, or `BLOCKED`;
- whether expansion to a second repository is recommended.

Observed evidence and inference must remain separate. The report must exclude credentials, connection details, business records, concrete product data, and real runtime output.

## 21. Future Artifact Boundaries

### 21.1 Hub-side future artifacts

A separately authorized evidence round may create:

```text
docs/dogfood/codex_project_workflow_c3_ams_data_pilot_report.md
```

It must not silently modify the canonical skill, adapters, indexes, status, handoff, or another dogfood line.

### 21.2 AMS_Data-side future artifacts

Only a separate AMS_Data implementation package may authorize:

- one task-specific package;
- the exact business or documentation files required by the real task;
- an execution report when existing project convention requires one.

The future pilot must not create by default:

```text
.codex/**
copied skill/**
workflow runtime pack
mandatory NEXT_ACTION.md
second rulebook
```

## 22. Review and Approval Sequence

```text
C3 design package implementation
-> independent package review
-> push / PR
-> PR-level final review
-> normal merge and freeze of the design package
-> separate AMS_Data pilot task selection/package
-> pilot implementation
-> independent pilot review
-> hub-side dogfood evidence
-> C3 pilot final decision
```

No stage may skip directly from this design package to AMS_Data implementation.

## 23. C3 Execution Prerequisites

Before an actual pilot begins, all of the following must hold:

1. This C3 design package has been independently reviewed and merged into hub `main`.
2. AMS_Data supplies a clean, aligned, exact baseline accepted by the active package.
3. A real, low-risk, non-artificial task exists.
4. An active AMS_Data task package explicitly authorizes the pilot task.
5. Allowed and forbidden paths are frozen.
6. Validation commands and their side-effect profile are fixed.
7. The task needs no live data, database write, credential, mail, Wind, or external API.
8. The sub-agent policy is recorded.
9. The rollback plan is accepted.
10. Dogfood evidence fields and sensitive-data exclusions are fixed.
11. The canonical skill remains in ai-skill-hub and is not copied into AMS_Data.
12. C3 execution receives separate explicit authorization.

## 24. Recommended Design Decision

```text
DESIGN_COMPLETE_PILOT_BASELINE_PENDING
```

Supporting decisions:

| Decision field | Result |
| --- | --- |
| target readiness | `DESIGNABLE_WITH_BASELINE_PREREQUISITE` |
| package ready for independent review | yes |
| actual pilot authorized | no |
| pilot task selected | no |
| C3 status | `DESIGN_PACKAGE_CREATED_PILOT_NOT_STARTED` |

This package cannot conclude `PILOT_PASS` or `C3_COMPLETE`. The only recommended next action is independent review of this C3 pilot design package.
