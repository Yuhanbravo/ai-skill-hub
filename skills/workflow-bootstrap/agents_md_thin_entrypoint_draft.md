# AGENTS.md Thin Entrypoint Draft (Historical Phase 2 Asset)

Status: maintained historical design asset for project-side thin entries. The Phase 2 label records lineage, not active phase or rollout authorization.

This draft does not create a real `AGENTS.md` in this repository.

Applicability: this draft is for the default `AI_LEVEL_CONFIG_BACK_REFERENCE` mode. Existing, unmigrated Project Runtime Pack consumers continue to use their project manifest, project routers, commit pinning, and pinned/portable validation. Applying this draft to change modes requires a separate migration task; neither mode is an automatic fallback for the other.

## Purpose

Define the future `AGENTS.md` as the unified project-side master entrypoint.

- Positioning: dispatch-oriented, reference-first, thin-entrypoint.
- Responsibility: route users/agents to canonical guidance and enforce top-level boundaries.
- Non-goal: become canonical source-of-truth.

## Canonical Guidance

Future `AGENTS.md` should include an explicit identity statement, project-local authoritative references, and a logical-ID list for shared canonical guidance.

### Recommended fixed identity statement

> This file is the project-side runtime master entrypoint. It is dispatch-oriented and reference-first. It is not canonical source-of-truth.

### Required guidance list (example structure)

Use explicit paths for project-local authority and logical Skill IDs for cross-repository guidance. At minimum include:

1. Workflow bootstrap canonical guidance.
2. Handoff / bounded execution canonical guidance (`chatgpt-handoff-pilot` related).
3. Project-local authoritative documents or contracts.

Recommended logical-ID format:

- `workflow-bootstrap`
- `chatgpt-handoff-pilot`
- `<project-authoritative-doc-path>`

In this draft's default back-reference mode, the consumer resolves logical IDs through its user-level router, neutral locator, and Hub resolver. Only the locator stores the machine Hub checkout path. Do not assume the consumer contains `skills/`, copy canonical payload into it, add a project commit pin, or fall back to a Runtime Pack when routing fails.

## High-Level Working Rules

Future `AGENTS.md` should keep only thin, high-level operating constraints:

1. Read required canonical guidance before implementation.
2. Execute in bounded scope from task package.
3. Report what was changed vs. explicitly not implemented.
4. Record assumptions when ambiguity exists.

Identity requirement (must be explicit in future file):

- it is a project-side runtime entrypoint;
- it is not canonical source-of-truth;
- it dispatches and backreferences canonical guidance first.

## Boundaries

Future `AGENTS.md` should explicitly include all of the following:

- It does not replace canonical skills in `skills/`.
- It does not replace handoff protocol ownership (`chatgpt-handoff-pilot`).
- It must not copy full workflow/governance/skill documentation.
- It must not expand into a second local rulebook.

### Recommended fixed boundary text

> Do not expand this file into a full local rulebook. Keep it thin and reference-first. Full guidance remains in canonical skill documents.

## Conflict Resolution

Future `AGENTS.md` should include an explicit authority rule:

- user/task sources own current authorization;
- project documents own project facts;
- resolved canonical Skills own reusable method;
- an irreconcilable same-subject conflict pauses only the dependent action.

### Recommended fixed conflict text

> Apply each source within its stated ownership. If two applicable sources conflict on the same subject and cannot be reconciled, stop the affected action and report the conflict.

## Suggested Minimal Structure

A future project-side `AGENTS.md` can stay minimal with five sections:

1. Purpose
2. Canonical Guidance
3. High-Level Working Rules
4. Boundaries
5. Conflict Resolution

This keeps the entrypoint stable while preventing drift and duplicate governance text.
