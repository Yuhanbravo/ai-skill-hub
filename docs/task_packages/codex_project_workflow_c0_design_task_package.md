# Task Package: Codex Project Workflow C0 Design

## 1. Task Identity

- task id: `CODEX-PROJECT-WORKFLOW-C0-DESIGN-V1`
- task name: `ai-skill-hub | codex-project-workflow | C0 Design Package`
- repository: `ai-skill-hub`
- package type: docs-only / task-package-only
- proposed skill name: `codex-project-workflow`
- package path: `docs/task_packages/codex_project_workflow_c0_design_task_package.md`
- intended future canonical skill path: `skills/codex-project-workflow/`

This package authorizes a future design and implementation sequence for a reusable Codex workflow skill. It does not implement the skill by itself.

## 2. Problem Statement

Repeated Codex implementation rounds across projects often require the same coordination scaffolding: a compact task summary, a clear boundary statement, repository preflight, controlled sub-agent usage, and a concise final handoff report. Without a reusable workflow skill, each project can drift into local one-off instructions, uneven task boundaries, or overly large handoff messages.

The target projects include business repositories such as AMS_Data, Derivative_Data, Pricing_sheet, and pricing-parser, plus `ai-skill-hub` itself. Those repositories should not each become a canonical source for the workflow. The reusable workflow should live in `ai-skill-hub` as a canonical skill, while business repositories keep only thin project-local entry points or task-specific state files.

## 3. Goals

The future `codex-project-workflow` skill should provide a small, reusable workflow layer that helps Codex consistently use:

- short Task Cards that summarize objective, scope, files, validation, and handoff expectations;
- fixed boundary templates that separate in-scope work, forbidden work, assumptions, and stop conditions;
- `NEXT_ACTION.md` as a one-page project state entry when a project chooses to adopt it;
- repository preflight before editing;
- readonly audit / validation sub-agents when they add value without expanding write scope;
- compact final reports suitable for ChatGPT handoff and review.

The future skill should reduce repeated prompt-writing while preserving project-local rules and existing canonical skills.

## 4. Non-Goals

C0 is not an implementation round. It must not:

- create `skills/codex-project-workflow/`;
- add `.agents` or `.github` adapters;
- update `skills_index.json`, `SKILLS_INDEX.md`, or adapter indexes;
- modify `financial-data-agent-bootstrap` behavior;
- modify business repositories;
- introduce project-specific business facts, schemas, credentials, paths, or operational details;
- create runtime automation, CLIs, tests, or generated artifacts;
- turn `NEXT_ACTION.md` into a mandatory file for every project;
- replace `chatgpt-handoff-pilot`, `workflow-bootstrap`, `project-takeover`, `update-project-status`, `file-structure-check`, or existing project-local instructions.

## 5. Proposed Skill Name

The proposed reusable skill name is:

```text
codex-project-workflow
```

The name is intentionally Codex-facing because the skill is meant to standardize implementation-session behavior, repo preflight, bounded edits, sub-agent usage, and compact handoff reporting during Codex work.

## 6. Proposed Directory Structure

A future C1 implementation round may create the canonical skill under:

```text
skills/codex-project-workflow/
├── SKILL.md
├── README.md
├── references/
│   ├── task_card_template.md
│   ├── boundary_template_guide.md
│   ├── next_action_template.md
│   ├── subagent_roles.md
│   ├── preflight_checklist.md
│   └── final_report_template.md
└── examples/
    └── invocation_examples.md
```

Directory intent:

| Path | Intended role |
| --- | --- |
| `SKILL.md` | Canonical executable guidance for when and how to use the workflow. |
| `README.md` | Human-readable overview and relationship to adjacent skills. |
| `references/` | Reusable templates and short guides referenced by `SKILL.md`. |
| `examples/invocation_examples.md` | Fictional examples for discovery metadata and safe invocation patterns. |

C1 should keep the skill instruction-only unless a later task package explicitly authorizes scripts or tooling.

## 7. Proposed References

The future skill should include these proposed reference files:

### `task_card_template.md`

Defines a short Task Card format for each Codex round. Recommended fields:

- task name;
- objective;
- authorized paths;
- forbidden paths;
- expected output;
- validation commands;
- final report requirements;
- known risks or assumptions.

### `boundary_template_guide.md`

Defines fixed language for implementation boundaries, including:

- in-scope changes;
- explicit non-goals;
- no-touch paths;
- stop-and-report conditions;
- assumptions to record before editing;
- rules for avoiding opportunistic cleanup.

### `next_action_template.md`

Defines a one-page `NEXT_ACTION.md` template for repositories that opt in. It should capture only current state needed to resume work, such as:

- current branch or working context;
- immediate next action;
- active task package or Task Card;
- latest validation status;
- blockers;
- handoff notes.

The template must state that `NEXT_ACTION.md` is a project-local state entry, not canonical skill content.

### `subagent_roles.md`

Defines recommended readonly sub-agent roles, such as:

- repository preflight auditor;
- docs consistency reviewer;
- validation planner;
- diff boundary reviewer;
- final report reviewer.

It should distinguish readonly audit / validation roles from implementation workers and require explicit write-scope ownership before any implementation sub-agent is used.

### `preflight_checklist.md`

Defines a compact repository preflight checklist, including:

- read local instructions such as `AGENTS.md`;
- inspect branch and working tree status;
- identify authorized paths;
- locate relevant task packages or project state files;
- check existing conventions before adding files;
- decide whether sub-agents are useful and safe;
- select validation commands appropriate for the task.

### `final_report_template.md`

Defines a compact final report for ChatGPT handoff, including:

- branch;
- changed files;
- summary;
- validation results;
- explicitly not implemented;
- assumptions and risks;
- recommended next action.

The template should remain concise and compatible with project-specific final-answer requirements.

## 8. Rules For What Belongs In ai-skill-hub Versus Business Repos

### Belongs in `ai-skill-hub`

- canonical `codex-project-workflow` skill instructions;
- reusable templates and reference guides;
- fictional invocation examples;
- adapter/index exposure after a later task package authorizes it;
- governance notes explaining the boundary between canonical skill content and project-local state.

### Belongs in business repos

- project-specific `NEXT_ACTION.md` files when the project opts in;
- local task cards or task packages for actual project work;
- project-specific validation commands;
- project-specific no-touch paths, environment constraints, and business context;
- local `AGENTS.md` or Copilot instructions that point back to canonical skills without copying them.

### Must not be copied into business repos by default

- full canonical `SKILL.md` content;
- full reference guides unless a controlled runtime pack later authorizes it;
- hub adapter/index maintenance files;
- unrelated templates for other business projects.

## 9. Rules For When To Use Sub-Agents

The future skill should recommend sub-agents only when they materially improve bounded execution.

Use readonly audit / validation sub-agents when:

- the repository has enough surface area that a focused parallel review can find risks faster;
- the sub-agent can inspect a distinct concern, such as docs consistency, no-touch paths, or validation planning;
- the main implementer can continue non-overlapping work without waiting;
- the sub-agent does not need write access.

Use implementation sub-agents only when:

- the task package explicitly allows delegation;
- write scopes are disjoint and named;
- each sub-agent is told that other agents may be editing the repository;
- the main implementer can review and integrate the result safely.

Do not use sub-agents when:

- the task is small enough for one pass;
- the next step is blocked on the sub-agent's result;
- the sub-agent would need ambiguous write access;
- the task involves sensitive business facts that should not be spread into extra context;
- local instructions or the task package prohibit delegation.

## 10. Recommended Phased Rollout

### C0 design package

Create this task package only. Do not implement the skill, adapters, indexes, or business repo files.

### C1 instruction-only skill

Create `skills/codex-project-workflow/` with `SKILL.md`, `README.md`, reference templates, and fictional invocation examples. Keep the skill instruction-only and avoid tools, tests, generated artifacts, or adapter exposure unless separately authorized.

### C2 adapter/index exposure

After C1 review, add thin `.agents` and `.github` discovery surfaces plus required index updates. Adapters must point to the canonical skill and must not copy full workflow content.

### C3 pilot in AMS_Data and Derivative_Data

Pilot the workflow in selected business repos by adding or updating only project-local state and thin entry files authorized by those repos. The pilot should validate whether Task Cards, boundary templates, `NEXT_ACTION.md`, preflight, sub-agent guidance, and compact final reports improve repeatability without creating local rulebooks.

## 11. Validation Plan

C0 validation should confirm that the round stayed package-only:

```text
git diff --check
```

If safe and available, also run a repository structure check, such as:

```text
python tests/test_skill_structure.py
```

The future implementer should also inspect `git diff --name-only` and confirm that only this task package changed.

C1 validation should add skill-structure and metadata checks appropriate to a new canonical skill. C2 validation should add adapter consistency and index checks. C3 validation should be defined inside each business repository's own task package.

## 12. Explicit Forbidden Boundaries

This C0 package forbids:

- creating or modifying `skills/codex-project-workflow/**`;
- modifying `.agents/**`, `.github/**`, `examples/**`, `tools/**`, `tests/**`, or generated artifacts;
- modifying `skills/financial-data-agent-bootstrap/**` or its adapter/index behavior;
- modifying AMS_Data, Derivative_Data, Pricing_sheet, pricing-parser, or any other business repository;
- adding adapters, indexes, runtime packs, scripts, or validation tooling;
- editing existing skill behavior as part of this package-only round;
- copying canonical skill content into project-local instructions;
- declaring the workflow generally rolled out before C1, C2, and C3 are separately completed.

## 13. Required Future C0 Execution Report

The C0 implementer should report:

- branch;
- changed files;
- validation commands and results;
- confirmation that this was package-only;
- confirmation that no business repositories were modified;
- confirmation that no adapters, generated artifacts, tools, tests, or existing skills were modified;
- recommended next action.

Recommended next action after C0 is accepted: author a separate C1 task package or implementation branch for the instruction-only `skills/codex-project-workflow/` canonical skill.
