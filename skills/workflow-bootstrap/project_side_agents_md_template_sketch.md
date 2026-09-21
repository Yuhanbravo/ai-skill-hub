# Project-Side AGENTS.md Template Sketch (Historical Phase 3A Asset)

Status: maintained historical design asset for project-side thin entries. Use the current routing and ownership notes below; the Phase 3A label records lineage, not active phase or rollout authorization.

This document does **not** create a real `AGENTS.md` in this repository.

Applicability: this sketch targets new or maintained consumers using the default `AI_LEVEL_CONFIG_BACK_REFERENCE` mode. Do not apply it over an existing, unmigrated Project Runtime Pack entry; that mode keeps its project manifest, project routers, commit pinning, and pinned/portable validation. A mode change requires a separately authorized migration, and neither mode is a fallback for the other.

## Purpose

Refine the Phase 2 thin-entrypoint draft into a v1 template sketch for a future project-side `AGENTS.md`.

The future file remains:

- the unified project-side master entrypoint;
- dispatch-oriented and reference-first;
- intentionally thin;
- non-canonical.

## Fixed vs Project-Fill Fields

### Fixed Fields

The following parts should stay fixed across future project-side uses because they express the canonical contract:

1. Identity statement:
   - `AGENTS.md` is the project-side master entrypoint.
   - It is dispatch-oriented and reference-first.
   - It is not canonical source-of-truth.
2. Required canonical reading requirement:
   - consumers list logical Skill IDs and project-local authoritative documents;
   - resolve Skill IDs through the consumer's router / locator / resolver before reading the returned canonical paths.
3. Conflict rule:
   - authority is applied by subject: reusable method comes from the resolved canonical Skill, while project facts and current authorization remain project/task-owned;
   - an irreconcilable same-subject conflict pauses only the dependent action.
4. Anti-expansion boundary:
   - do not expand the file into a second local rulebook.
5. Execution orientation:
   - read canonical guidance first;
   - execute in bounded scope from task package;
   - report what changed vs. what was not implemented.

### Project-Fill Fields

The following parts should stay project-supplied:

1. Project name or repository identity.
2. Concrete project-local authoritative documents and any logical Skill IDs the workflow actually requires.
3. Project-specific local boundaries that are not reusable across repos.
4. Optional local working constraints that are truly high-level and do not duplicate canonical guidance.

## Suggested Minimal Structure

A future project-side `AGENTS.md` should stay minimal with five sections:

1. Purpose
2. Canonical Guidance
3. High-Level Working Rules
4. Boundaries
5. Conflict Resolution

## Template Sketch

```md
# AGENTS.md

## Purpose
This file is the project-side runtime master entrypoint. It is dispatch-oriented and reference-first. It is not canonical source-of-truth.

Project: `<project-name>`

## Required Guidance
Read project-local authority and resolve the required shared guidance before implementation:

- Project docs: `<project-authoritative-doc-path>`
- Logical Skill ID: `workflow-bootstrap`
- Logical Skill ID: `chatgpt-handoff-pilot` (when bounded execution applies)

This template assumes the default `AI_LEVEL_CONFIG_BACK_REFERENCE` mode. Use the consumer's user-level router, neutral locator, and resolver. Accept only a resolved canonical entry, then read its required supporting resources. Do not store a machine Hub path, copied Skill payload, or project commit pin here. If this project instead has an unmigrated Project Runtime Pack, do not use this template to replace its manifest/router/pinning entry; mode migration is separate work and routing failure does not authorize fallback.

## High-Level Working Rules
1. Read required canonical guidance before implementation.
2. Execute in bounded scope from the active task package.
3. Record assumptions when project-local ambiguity exists.
4. Report what was changed and what was explicitly not implemented.

## Boundaries
- Keep this file thin and reference-first.
- Do not copy full workflow, governance, or skill guidance here.
- Keep project-specific local notes high-level only.
- If a reusable rule is missing, add it to canonical guidance rather than expanding this file.

## Conflict Resolution
Apply each source within its ownership: task/user input controls current authorization, project docs control project facts, and resolved canonical Skills control reusable method. If applicable sources conflict on the same subject and the conflict cannot be reconciled, stop only the affected action and report it.
```

## Field Notes

### Purpose

Fixed:

- the identity statement;
- the non-canonical declaration.

Project-fill:

- optional one-line project descriptor.

### Canonical Guidance

Fixed:

- explicit requirement to read canonical guidance first;
- logical-ID routing plus explicit project-local document references.

Project-fill:

- logical Skill IDs required by the workflow;
- project-local authoritative document paths.

### High-Level Working Rules

Fixed:

- bounded execution orientation;
- assumption logging;
- changed vs. not-implemented reporting.

Project-fill:

- at most a few local high-level constraints that do not duplicate canonical guidance.

### Boundaries

Fixed:

- no full workflow duplication;
- no governance duplication;
- no second rulebook.

Project-fill:

- small project-local constraints about scope or repo shape, if truly necessary.

### Conflict Resolution

Fixed:

- authority is subject-specific rather than a blanket “canonical wins” rule;
- unresolved same-subject conflicts fail closed for the dependent action.

Project-fill:

- none required.

## Anti-Bloat Guardrail

The future `AGENTS.md` should be reviewed for drift if any of the following happens:

1. It starts adding topic-by-topic rules that belong in canonical skills.
2. It becomes longer than a thin entrypoint needs to be.
3. It repeats content already present in `.github/copilot-instructions.md`.
4. It carries detailed role-specific playbooks.

When that happens, the reusable content should move back to canonical guidance instead of staying only in the project-side file.
