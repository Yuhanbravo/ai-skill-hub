# Task Package: Codex Project Workflow C2 Exposure Plan

## 1. Task Identity

- task id: `CODEX-PROJECT-WORKFLOW-C2-EXPOSURE-PLAN-V1`
- task name: `ai-skill-hub | codex-project-workflow | C2 Adapter/Index Exposure`
- repository: `SYS_ai-skill-hub`
- planning package type: `C2 docs-only / exposure-plan package`
- future implementation type: bounded adapter/index/discovery exposure
- planning baseline: `origin/main` at `629cb9d80c4a6cf54a52b735e32d565eb71214a4`
- package path: `docs/task_packages/codex_project_workflow_c2_exposure_plan_task_package.md`
- canonical skill path: `skills/codex-project-workflow/`
- recommended C2 implementation branch: `codex/codex-project-workflow-c2-exposure`

This package plans C2 only. Creating it does not authorize or perform adapter/index exposure, reopen the remotely frozen C0 or C1 work, or start C3.

## 2. Current State After C1

- C0 design is recorded in `docs/task_packages/codex_project_workflow_c0_design_task_package.md`.
- C1 created the instruction-only canonical skill at `skills/codex-project-workflow/` with `SKILL.md`, `README.md`, and six reusable templates under `references/`.
- The skill covers task classification, compact Task Cards, fixed boundaries, repository preflight, risk-based sub-agent decisions, and concise final reports.
- `skills/` remains the only canonical source of truth.
- The skill has no directory wrapper under `.agents/skills/`, flat `.agents` summary, or `.github` compatibility entry.
- It is absent from `skills_index.json`, `SKILLS_INDEX.md`, and `.agents/skills/skills_index.md`.

At this baseline, `python tools/check_adapter_consistency.py . --mode hub` reports exactly `codex-project-workflow` as missing from directory-style `.agents` and `.github` entries. That pre-C2 gap is the subject of future implementation, not a defect to fix while authoring this package.

The read-only derivative-surface audit also reports that `skills/codex-project-workflow/examples/invocation_examples.md` is absent. This is a non-gating metadata-quality finding. C2 must record it but must not modify the frozen canonical skill to resolve it.

## 3. C2 Objective and Non-Objectives

### Objective

Expose the frozen canonical skill through the repository's established thin adapter and active index surfaces so hub-local agent discovery, Copilot fallback discovery, machine routing, and human index discovery agree that it exists.

### Non-objectives

C2 implementation must not:

- change canonical meaning, triggers, workflow, templates, or boundaries;
- add invocation examples or other canonical C1 content;
- create a runtime pack or copy the skill into a business repository;
- modify tools, tests, validation policy, or generated-artifact policy;
- repair unrelated pre-existing catalog or inventory omissions;
- refresh bridge copies or status/handoff documents;
- start an AMS_Data, Derivative_Data, or other C3 pilot;
- merge, push, bundle, or delete branches without separate instruction.

## 4. Exact Exposure Surfaces to Consider

### Established active C2 surfaces

| Surface | Role | Current state | C2 implementation decision |
| --- | --- | --- | --- |
| `.agents/skills/codex-project-workflow/SKILL.md` | Primary directory-style thin wrapper | Missing | Add. |
| `.agents/skills/codex-project-workflow.md` | Flat quick-discovery summary | Missing | Add. |
| `.github/skills/codex-project-workflow.md` | Copilot fallback compatibility entry | Missing | Add. |
| `skills_index.json` | Machine-readable routing and metadata index | Missing skill entry | Update. |
| `SKILLS_INDEX.md` | Active repository-level cross-AI index | Missing catalog row and per-skill overview | Update. |
| `.agents/skills/skills_index.md` | Adapter-layer mirror index | Missing wrapper row | Update. |

These six surfaces are the established complete exposure set. Change them together in one bounded implementation so discovery mechanisms do not disagree.

### Other repository surfaces considered

| Surface | Assessment | C2 decision |
| --- | --- | --- |
| `README.md` | Convenience skill list, but outside the adapter-consistency contract and already has unrelated omissions. | Do not modify in narrow C2; use a separate inventory-governance task. |
| `docs/SKILL_CATALOG.md` | Human discovery catalog with unrelated omissions; not part of the established minimal exposure pattern. | Do not add a one-off row; reconcile separately. |
| `docs/TEMPLATE_REGISTRY.md` | Reusable-asset registry, not a required per-skill exposure index. | Do not modify. |
| `docs/bridge/SKILLS_INDEX.md` | Intentional bridge-facing copy; active ownership remains at root `SKILLS_INDEX.md`, and the derivative audit skips it. | Do not modify; refresh only under separate authority. |
| `.codex/**` | Hub-local configuration area; `.codex/skills/` is a consumer-project runtime convention. | Not applicable; do not modify. |
| `AI_USAGE.md`, `docs/HANDOFF.md`, `docs/status/**` | Usage or state surfaces, not required per-skill exposure targets. | Do not modify. |

The deferral of `README.md` and `docs/SKILL_CATALOG.md` is a known broader inventory-governance question, not proof that those files are complete.

## 5. Required C2 Implementation Delta and Rationale

1. Add `.agents/skills/codex-project-workflow/SKILL.md` as a thin wrapper with canonical path `../../../skills/codex-project-workflow` and a discovery-only instruction to read canonical `SKILL.md`.
2. Add `.agents/skills/codex-project-workflow.md` as a short flat metadata summary pointing to `skills/codex-project-workflow`.
3. Add `.github/skills/codex-project-workflow.md` as a short Copilot entry pointing to `../../skills/codex-project-workflow` and its canonical definition.
4. Add the skill to `skills_index.json` using canonical frontmatter and the repository's `project` category convention.
5. Add the catalog row and concise per-skill invocation overview to `SKILLS_INDEX.md`.
6. Add the canonical/wrapper mapping to `.agents/skills/skills_index.md`.

`tools/generate_skill_metadata.py` may produce `skills_index.json` and the flat `.agents/skills/*.md` summary, but the implementer must inspect its entire diff. Unrelated generated changes are outside C2. The directory wrapper, Copilot entry, root Markdown index, and adapter mirror index remain manually maintained under current conventions.

Because C1 has no canonical invocation-example file, the generated `invocation_example` may be empty. C2 must not invent canonical example content inside an adapter or index. Disclose the non-gating audit finding and route any fix to a separate canonical-content task.

## 6. Surfaces That Must Not Be Modified Yet

- `skills/codex-project-workflow/**`: remotely frozen C1 content; C2 is exposure-only.
- every other `skills/**` path: unrelated canonical skills are outside scope.
- unrelated `.agents/**` and `.github/**`: no opportunistic normalization.
- `README.md` and `docs/SKILL_CATALOG.md`: broader reconciliation needs separate scope.
- `docs/bridge/**`: derivative/reference surfaces, not active authoring targets here.
- `tools/**` and `tests/**`: existing checks are sufficient.
- generated artifacts other than expressly authorized `skills_index.json` and the generator-owned flat summary.
- business repositories and project-local runtime surfaces: reserved for separately authorized pilots.

If exposure cannot be completed without touching one of these areas, stop and report rather than widening C2.

## 7. Adapter and Index Consistency Rules

- The canonical skill set, directory-style `.agents` entries, and `.github` entries must agree after the hub contract check.
- Adapter names and index keys use the exact canonical name `codex-project-workflow`.
- The `.agents` wrapper contains the expected hub reference prefix `../../../skills/`.
- The `.github` entry contains the expected hub reference prefix `../../skills/`.
- All paths resolve to `skills/codex-project-workflow/` or its `SKILL.md` as appropriate.
- `skills_index.json` metadata comes from canonical frontmatter; adapters are not alternate metadata authorities.
- `SKILLS_INDEX.md` and `.agents/skills/skills_index.md` follow existing ordering and do not rewrite unrelated entries.
- The machine index, two Markdown indexes, and three adapters are reviewed as one consistency unit.
- No adapter includes full workflow steps, templates, safety boundaries, or reference content.

## 8. Copy and Mirror Rules

- `skills/codex-project-workflow/` remains the sole canonical source.
- Adapters are discovery/exposure surfaces only.
- The directory wrapper contains only minimal frontmatter, canonical paths, and a read-canonical instruction.
- The flat summary contains only canonical discovery metadata, canonical path, and a read-canonical instruction in the established format.
- The Copilot entry contains only minimal frontmatter, canonical paths, and a short suggested-use sentence.
- Index summaries may describe when to use the skill but must not reproduce its workflow or templates.
- Semantic changes begin in the canonical skill and flow to adapters only through separately authorized maintenance; they never originate in an adapter.
- `docs/bridge/SKILLS_INDEX.md` remains an intentional derivative copy, not an active source or C2 refresh target.

## 9. Validation Plan

### Required package-only validation for this planning round

```powershell
git diff --check
python tests/test_skill_structure.py
```

Also inspect `git diff --name-only` and confirm that only this package changed.

### Required future C2 implementation validation

Run in this order:

```powershell
git diff --check
python tests/test_skill_structure.py
python tools/check_adapter_consistency.py . --mode hub
python tools/audit_derivative_surfaces.py
```

Then inspect:

```powershell
git diff --name-only
git diff -- .agents/skills/codex-project-workflow/SKILL.md .agents/skills/codex-project-workflow.md .github/skills/codex-project-workflow.md .agents/skills/skills_index.md skills_index.json SKILLS_INDEX.md
```

Acceptance expectations:

- `git diff --check` passes.
- `python tests/test_skill_structure.py` passes.
- The hub adapter check reports no missing, orphan, or wrong-reference entries.
- The derivative audit remains read-only and non-gating. Its known missing invocation-example finding may remain, but no new drift may be introduced.
- `git diff --name-only` contains exactly the six authorized implementation surfaces.

## 10. Explicit Forbidden Boundaries

C2 planning and implementation forbid:

- modifying `.agents/**` or `.github/**` while authoring this package;
- modifying `skills_index.json` or `SKILLS_INDEX.md` while authoring this package;
- modifying any existing skill, including `skills/codex-project-workflow/**`;
- modifying tools, tests, bridge/status/handoff files, or unrelated generated artifacts;
- modifying `README.md`, `docs/SKILL_CATALOG.md`, or other inventory surfaces without a separate reconciliation package;
- copying canonical workflow steps or templates into adapters;
- inventing an invocation example in an index when no canonical source exists;
- exposing the skill in any business repository;
- adding or requiring `NEXT_ACTION.md` in a consumer repository;
- starting C3 pilots;
- merging, pushing, bundling, deleting branches, or publishing externally unless separately instructed.

## 11. Recommended Final Report Format

The future C2 implementation report must include:

- branch and exact baseline;
- task type: `C2 adapter/index/discovery exposure`;
- exact six changed paths;
- package summary: thin adapters added and active indexes aligned to the frozen canonical skill;
- command, exit status, and relevant issue summary for every required validation;
- the pre-existing missing canonical invocation-example finding, if still present, marked non-gating;
- explicit confirmation that canonical skills, unrelated inventories, bridge copies, tools/tests, business repositories, and C3 were not changed;
- confirmation that adapters remain discovery-only and canonical content did not drift;
- recommended next action: C2 implementation review.

Suggested skeleton:

```markdown
## Final Report

- Branch: <branch>
- Baseline: <commit>
- Changed files: <exact paths>
- Package summary: <one paragraph>
- Validation:
  - `git diff --check` — <result>
  - `python tests/test_skill_structure.py` — <result>
  - `python tools/check_adapter_consistency.py . --mode hub` — <result>
  - `python tools/audit_derivative_surfaces.py` — <result and known finding>
- Explicitly not implemented: <boundaries>
- C2 exposure complete: <yes/no>
- C3 started: no
- Recommended next action: C2 implementation review
```

## 12. C3 Pilot Prerequisites

C3 must not start until:

1. This C2 exposure plan is reviewed and accepted.
2. A separate C2 implementation task is explicitly authorized on its own branch.
3. All six active exposure surfaces are present and mutually consistent.
4. Structure validation and hub adapter consistency pass.
5. Reviewers accept or separately route the missing canonical invocation-example finding.
6. Review confirms that C2 did not change `skills/codex-project-workflow/**` or introduce adapter semantic drift.
7. Each proposed business-repository pilot supplies its own instructions, task package, baseline, write boundaries, and validation plan.
8. Pilot repositories explicitly opt in to any local Task Card or optional `NEXT_ACTION.md`; neither is installed by default.
9. Pilot work stays at thin project-local state/entry usage and does not copy the canonical skill or form a second rulebook.
10. Pilot repositories, success measures, stop conditions, and rollback/reporting expectations are approved in separate C3 packages.

## 13. Planning-Round Final Report Requirements

The author of this docs-only package must report:

- branch;
- baseline;
- changed files;
- package summary;
- results of `git diff --check` and `python tests/test_skill_structure.py`;
- confirmation that this round remained package-only;
- confirmation that no exposure surface was modified;
- confirmation that C3 was not started;
- recommended next action: C2 package review.
