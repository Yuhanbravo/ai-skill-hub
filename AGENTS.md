# AGENTS.md

## Purpose
This file is the **project-side runtime master entrypoint** for this repository implementation pilot. It is dispatch-oriented and reference-first. It is **not** the canonical source of truth.

Pilot repo: `ai-skill-hub` (single consumer repo implementation pilot; Phase 3D calibration is completed).

## Required Canonical Reading
Before implementation, read canonical guidance from concrete file paths:

1. `skills/workflow-bootstrap/SKILL.md`
2. `skills/chatgpt-handoff-pilot/SKILL.md`

Completed historical task package reference:
- `tasks/copilot-codex-workflow_phase3d_canonical_path_calibration_task_package.md`

Conditional project-local canonical payload path (maintainer-filled only if this repo later defines a distinct project-local canonical payload artifact):
- `<project-local-canonical-skill-path>`

## Field Mapping (after Phase 3D calibration)
### Fixed fields (canonical contract)
- This file is the project-side master entrypoint.
- This file is thin, dispatch-oriented, and reference-first.
- This file is not canonical source-of-truth.
- On conflict, canonical guidance wins.
- Do not expand this file into a second local rulebook.

### Project-fill fields (filled for this repo)
- Project identity: `ai-skill-hub`
- Canonical workflow path: `skills/workflow-bootstrap/SKILL.md`
- Canonical bounded-execution path: `skills/chatgpt-handoff-pilot/SKILL.md`
- Active task package: `NONE`
- Latest completed task package: `tasks/copilot-codex-workflow_phase3d_canonical_path_calibration_task_package.md`

### Placeholder fields (kept intentionally)
- `<project-local-canonical-skill-path>`
  - Status: intentionally unresolved in this pilot because this repo does not define a separate project-local canonical payload artifact beyond the concrete canonical entries listed above.
  - Filled by: project maintainer only.
  - Fill when: only after a distinct repo-local canonical payload file exists and is intended to remain thinner than a second rulebook.
  - Keep unresolved only while no such distinct project-local canonical payload path exists.

## High-Level Working Rules
1. Read required canonical guidance before implementation.
2. Execute in bounded scope from the active task package when one is designated.
3. Record assumptions when ambiguity exists.
4. Report what was changed and what was explicitly not implemented.

## Boundaries
- Keep this file thin and reference-first.
- Do not duplicate full workflow/governance/skill content from canonical guidance.
- Do not expand this file into a second rule library.

## Conflict Resolution
If this file conflicts with canonical guidance, canonical guidance takes precedence.
