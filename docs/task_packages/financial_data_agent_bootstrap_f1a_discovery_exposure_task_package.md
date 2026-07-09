# Task Package: Financial Data Agent Bootstrap F1a Discovery Exposure

## 1. Task Identity

- task id: `FINANCIAL-DATA-AGENT-BOOTSTRAP-F1A-DISCOVERY-EXPOSURE-V1`
- task name: `ai-skill-hub | Financial Data Agent Bootstrap | F1a Discovery Exposure`
- repository: `ai-skill-hub`
- baseline main HEAD: `80b1568dd64748a649ef5594a63e00677c35da52`
- package authoring branch: `docs/financial-data-agent-bootstrap-f1a-discovery-exposure-package`
- package path: `docs/task_packages/financial_data_agent_bootstrap_f1a_discovery_exposure_task_package.md`
- upstream review report: `docs/reviews/financial_data_agent_bootstrap_f1_adapter_index_review.md`
- canonical skill: `skills/financial-data-agent-bootstrap/SKILL.md`

This package authorizes a future F1a implementation round. It does not implement F1a by itself.

## 2. Background

`financial-data-agent-bootstrap` has completed F0, F0.1, and F1 review. The F1 review selected decision C:

```text
新增 thin adapters + 更新必要 index
```

The F1 review also recommended this implementation order:

1. Add canonical invocation examples / metadata source.
2. Add thin `.agents` and `.github` adapters.
3. Update necessary indexes.
4. Avoid tool/test changes unless implementation reveals a concrete blocker.

The current discoverability gap is that the canonical skill exists under `skills/financial-data-agent-bootstrap/`, but is not yet exposed through the same adapter and index surfaces as comparable hub skills.

## 3. Canonical Source Relationship

F1a must preserve the following source-of-truth boundaries:

| Surface | Role |
| --- | --- |
| `skills/financial-data-agent-bootstrap/SKILL.md` | Canonical source for workflow knowledge, operating modes, safety boundaries, stop conditions, and validation expectations. |
| `skills/financial-data-agent-bootstrap/README.md` | Human-readable thin overview only. It must not replace `SKILL.md`. |
| `skills/financial-data-agent-bootstrap/examples/invocation_examples.md` | Non-sensitive usage examples and metadata source for generated skill metadata. |
| `.agents` / `.github` adapters | Thin pointer / discovery entries only. They must not copy canonical rules, templates, or long workflows. |
| `skills_index.json`, `SKILLS_INDEX.md`, `.agents/skills/skills_index.md` | Discovery metadata and index surfaces only. They must summarize, not duplicate, skill content. |

On conflict, `skills/financial-data-agent-bootstrap/SKILL.md` wins.

## 4. Goal

Implement minimal discovery exposure for `financial-data-agent-bootstrap` so it can be found through established repository discovery surfaces without expanding adapters, indexes, or examples into a second source of truth.

The implementation must keep examples fictional, placeholder-first, and free of real business facts.

## 5. In Scope For Future F1a Implementation

F1a is limited to three implementation areas.

### A. Canonical invocation examples / metadata source

Authorized target:

```text
skills/financial-data-agent-bootstrap/examples/invocation_examples.md
```

The canonical invocation examples should be placed at the path above. F1a should adopt this file because `tools/generate_skill_metadata.py` uses `examples/invocation_examples.md` as the preferred metadata source when generating `skills_index.json`.

Examples should cover only abstract, non-sensitive scenarios, such as:

- initialize an `AGENTS.md` for a financial data script project;
- create `data_contract`, `source_contract`, and `validation` documents for a valuation/NAV data project;
- generate a task package for Wind/API/Excel/CSV source governance;
- establish handoff templates for multi-agent, side-channel, or controller-feedback workflows.

Examples must avoid:

- real Windows paths;
- real product names;
- real project names;
- real database names, schemas, tables, DSNs, URLs, credentials, tokens, or cookies;
- real mailbox rules, email subjects, attachment names, or archive paths;
- real hosted bank or custodian information;
- real business metric definitions or valuation/NAV calculation details;
- raw or reconstructable financial data.

The metadata finding source is:

```text
tools/audit_derivative_surfaces.py
```

After `examples/invocation_examples.md` is added with valid invocation example content, `python tools\audit_derivative_surfaces.py` is expected to eliminate the current report-only missing example finding for `financial-data-agent-bootstrap`. If the finding does not clear through documentation and index changes alone, stop and report the blocker. Do not modify the audit tool during F1a by default.

### B. Thin adapters

F1 review currently recommends adding thin `.agents` and `.github` adapters.

Authorized targets:

```text
.agents/skills/financial-data-agent-bootstrap/SKILL.md
.agents/skills/financial-data-agent-bootstrap.md
.github/skills/financial-data-agent-bootstrap.md
```

The `.agents` adapter is needed because this repository uses `.agents/skills/` as a hub-local discovery layer. The `.github` adapter is needed because this repository uses `.github/skills/` as a Copilot fallback / compatibility layer.

The adapter files must be thin pointers. They may include only:

- skill name;
- short purpose summary;
- canonical path;
- canonical definition path;
- concise usage boundary;
- reminder that `skills/financial-data-agent-bootstrap/SKILL.md` is canonical.

They must not copy:

- full `SKILL.md` content;
- fixed safety rules;
- templates;
- references;
- long workflow explanations;
- stop-condition lists;
- prompt bodies;
- real business facts.

Do not add a `.codex` adapter by default. F1 review observed that `.codex/` in this hub currently contains config only, while `.codex/skills/` is a consumer-project runtime skill-content root. A future implementer may re-check existing repository surfaces before implementation, but should not force a `.codex` adapter unless a concrete current convention requires it.

### C. Necessary index updates

Authorized targets:

```text
skills_index.json
SKILLS_INDEX.md
.agents/skills/skills_index.md
```

Expected maintenance model from F1 review:

- `skills_index.json` is generated by `tools/generate_skill_metadata.py`.
- `.agents/skills/*.md` flat summaries are also generated by `tools/generate_skill_metadata.py`.
- `SKILLS_INDEX.md` appears manually maintained unless a current generator is discovered.
- `.agents/skills/skills_index.md` appears manually maintained unless a current generator is discovered.
- `.agents/skills/<skill>/SKILL.md` directory wrappers and `.github/skills/<skill>.md` entries appear manually maintained.

If a current generator exists for an index surface, prefer the generator over hand editing. Review the full generated diff carefully because metadata generation may refresh more than the new skill entry.

Index entries must remain summary-level. They must not copy canonical skill content, safety rules, templates, or long workflow text.

## 6. Explicitly Out Of Scope For F1a

F1a must not do the following by default:

- modify `tools/**`;
- modify `tests/**`;
- connect to real business projects;
- introduce real financial data;
- write real Windows paths;
- write real product names, project names, database schemas, DSNs, email subjects, attachment names, or hosted bank information;
- write real product code or business system identifiers;
- implement a CLI;
- perform broad catalog / registry refactors;
- fix unrelated adapter/index governance history;
- modify `skills/financial-data-agent-bootstrap/SKILL.md` core content;
- modify `templates/**`;
- modify `references/**`;
- modify business project files.

Do not make opportunistic cleanup changes. If a related issue is found but is not necessary to expose this skill through F1a surfaces, record it in the execution report and leave it for a separate task.

## 7. Authorized Write Scope For F1a

The future F1a implementation may write only the following paths unless a blocker is escalated and explicitly approved in a separate task:

```text
skills/financial-data-agent-bootstrap/examples/invocation_examples.md
.agents/skills/financial-data-agent-bootstrap/SKILL.md
.agents/skills/financial-data-agent-bootstrap.md
.github/skills/financial-data-agent-bootstrap.md
skills_index.json
SKILLS_INDEX.md
.agents/skills/skills_index.md
```

No other files are authorized by this package.

## 8. Tools / Tests Policy

F1a defaults to no tool or test changes.

Only stop and report a blocker if implementation discovers one of these conditions:

- existing tools cannot recognize the new skill;
- existing index generation rules conflict with the current repository state;
- the metadata audit finding cannot be eliminated through examples and index/documentation changes;
- adapter consistency checks require an additional structure not authorized here.

Do not modify `tools/**` or `tests/**` merely to make checks pass.

## 9. Required Implementation Order

The future implementer should proceed in this order:

1. Re-read this task package, `skills/financial-data-agent-bootstrap/SKILL.md`, and the F1 review report.
2. Re-check current repository surfaces before editing so the implementation is based on live state.
3. Add `skills/financial-data-agent-bootstrap/examples/invocation_examples.md` with fictional, placeholder-first examples.
4. Add thin `.agents` and `.github` adapters.
5. Update `skills_index.json`, `SKILLS_INDEX.md`, and `.agents/skills/skills_index.md`, using existing generators where appropriate.
6. Run validation.
7. Report changed files, skipped surfaces, validation results, assumptions, and any remaining report-only findings.

## 10. Required Validation For F1a Implementation

At minimum, run:

```text
git diff --check
python tests\test_skill_structure.py
python tools\check_adapter_consistency.py . --mode hub
python tools\audit_derivative_surfaces.py
```

`tools/audit_derivative_surfaces.py` may be treated as report-only. If it still reports unrelated findings, do not fix unrelated surfaces during F1a. If it still reports `financial-data-agent-bootstrap` missing canonical invocation examples after the examples file is added, stop and report the blocker.

## 11. Acceptance Criteria

F1a is complete only if:

1. `financial-data-agent-bootstrap` has canonical non-sensitive invocation examples.
2. `.agents` and `.github` expose the skill through thin pointer adapters.
3. Necessary index surfaces include the skill at summary level.
4. No adapter or index duplicates canonical `SKILL.md` content.
5. No real business facts, paths, product names, database details, mailbox rules, or financial data are introduced.
6. No tools/tests are changed unless a separately approved blocker task authorizes it.
7. Validation results are reported clearly.

## 12. Execution Report Requirements For F1a

The future F1a execution report must include:

- current branch and baseline HEAD used for implementation;
- files changed;
- confirmation that examples are fictional and non-sensitive;
- whether `.codex` was re-checked and why no `.codex` adapter was added, unless a concrete convention changed;
- whether each index was generated or hand-edited;
- validation commands and results;
- explicit confirmation that tools/tests, real business projects, real financial data, templates, references, and core `SKILL.md` content were not modified;
- remaining risks, report-only findings, and recommended next step.

## 13. This Package-Only Round

This package-only round is limited to creating:

```text
docs/task_packages/financial_data_agent_bootstrap_f1a_discovery_exposure_task_package.md
```

It must not directly modify:

```text
skills/financial-data-agent-bootstrap/examples/invocation_examples.md
.agents/**
.github/**
skills_index.json
SKILLS_INDEX.md
.agents/skills/skills_index.md
tools/**
tests/**
business project files
skills/financial-data-agent-bootstrap/SKILL.md
templates/**
references/**
```

Package-only validation should run at least:

```text
git diff --check
python tests\test_skill_structure.py
```

`python tools\audit_derivative_surfaces.py` may also be run as report-only, but this package-only round must not modify implementation surfaces in response to that audit.
