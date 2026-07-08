# Task Package: financial-data-agent-bootstrap F1 Adapter + Index Review

## 1. Task Identity

- Task id: `FINANCIAL-DATA-AGENT-BOOTSTRAP-F1-ADAPTER-INDEX-REVIEW`
- Skill: `financial-data-agent-bootstrap`
- Phase: `F1`
- Package type: review-only task package
- Repository: `D:\dev\ai-skill-hub`
- Expected base: `main` at observed HEAD `24fce06`
- Recommended branch for execution: `docs/financial-data-agent-bootstrap-f1-review`

## 2. Current Baseline

The current `main` baseline is expected to include:

- PR #19: `financial-data-agent-bootstrap` roadmap + F0 task package
- PR #20: F0 docs/templates-only skill skeleton
- PR #21: F0.1 README structure fix
- PR #18: P1 closeout status/handoff refresh

Known validation state before this package:

- `python tests\test_skill_structure.py`: passing
- `git diff --check`: passing
- `python tools\audit_derivative_surfaces.py`: bridge semantic drift `0`
- Report-only metadata finding remains: `financial-data-agent-bootstrap` missing canonical invocation examples

The metadata finding must not be fixed during F1 review. It must be captured as a review finding and routed to F1a, catalog metadata cleanup, or a separate governance task.

## 3. Phase Positioning

F0 solved: "does a canonical skill exist?"

F0.1 solved: "does the canonical skill satisfy the structure validator?"

F1 solves: "should the canonical skill enter discovery surfaces?"

F1a solves: "how should discovery exposure be minimally implemented?"

F1 is not a request to "add a few entry files." F1 is a review gate that protects the canonical skill model before any discovery surface expansion happens.

F1 exists to:

- Prevent canonical source dilution through `.agents`, `.github`, or `.codex` surfaces.
- Prevent unaudited spread of adapters, indexes, catalog entries, and invocation examples.
- Prevent existing governance findings from contaminating the new skill.
- Distinguish thin adapters from index, registry, catalog, and metadata mechanisms.
- Decide whether `financial-data-agent-bootstrap` needs agent-facing discovery exposure.
- Decide whether the existing report-only metadata finding belongs in F1a, catalog metadata cleanup, or a separate governance task.

## 4. Goal

Produce a review-only assessment of the adapter, index, catalog, registry, and invocation discoverability mechanism relevant to `financial-data-agent-bootstrap`.

The review must determine whether this F0 skill should be exposed through `.agents`, `.github`, `.codex`, indexes, catalogs, registries, or invocation examples, and if so what a later F1a implementation package should be allowed to change.

## 5. In Scope For F1 Review

F1 review may inspect repository state and produce one review report. It may:

- Identify existing agent-facing discovery surfaces.
- Classify each surface as thin adapter, mirror, active source, compatibility entry, consumer-mode entry, index, registry, catalog, or metadata surface.
- Assess whether `financial-data-agent-bootstrap` should enter each surface.
- Assess whether canonical invocation examples are a structural requirement, catalog requirement, or report-only metadata requirement.
- Determine whether existing governance findings should block new skill discovery exposure.
- Recommend one of the four required F1 decisions.
- Propose a minimal F1a implementation scope if and only if review evidence supports implementation later.

## 6. Out Of Scope For F1 Review

F1 review must not implement any discovery exposure or metadata cleanup.

Explicitly out of scope:

- adapter implementation
- adapter modification
- index implementation
- index modification
- invocation examples implementation
- catalog metadata cleanup implementation
- tool changes
- test changes
- CLI implementation
- business project onboarding
- real financial data access
- AMS_Data, Pricing_sheet, Derivative_Data, or other business project integration
- F1a implementation

## 7. Authorized Read Scope For F1 Review

F1 review is allowed to read:

```text
skills/financial-data-agent-bootstrap/**
skills/*/README.md
skills/*/SKILL.md
skills/*/examples/**
.agents/skills/**
.github/skills/**
.codex/skills/**
skills_index.json
SKILLS_INDEX.md
tools/**
tests/**
docs/governance/**
docs/status/**
docs/HANDOFF.md
```

The read scope is intentionally broad so the review can understand the actual discovery and governance system. Broad read access does not imply broad write access.

## 8. Authorized Write Scope For F1 Review

F1 review may create or update only:

```text
docs/reviews/financial_data_agent_bootstrap_f1_adapter_index_review.md
```

No other file may be modified during F1 review.

## 9. Forbidden Write Scope For F1 Review

F1 review must not modify:

```text
skills/**
.agents/**
.github/**
.codex/**
tools/**
tests/**
docs/status/**
docs/bridge/**
docs/HANDOFF.md
docs/roadmaps/**
skills_index.json
SKILLS_INDEX.md
```

F1 review must not create adapters, update indexes, add canonical invocation examples, repair metadata audit findings, modify the F0/F0.1 skill content, or connect the skill to any business project.

## 10. Required Review Questions

### Adapter surfaces

1. What agent-facing surfaces actually exist in this repository?
   - `skills/`
   - `.agents/`
   - `.github/`
   - `.codex/`
   - README / index / catalog / registry
2. What is the responsibility of `.agents`, `.github`, and `.codex`?
   - thin adapter?
   - mirror?
   - active source?
   - compatibility entry?
   - consumer-mode entry?
3. Should an adapter only point to the canonical skill, or may it contain a summary?
4. May an adapter copy fixed safety rules or template content?

### Index / catalog

5. Does `skills_index.json` exist? Is it manually maintained?
6. Does `SKILLS_INDEX.md` exist? Is it manually maintained?
7. Are there index generation or validation tools?
8. Must a new skill enter an index to be discoverable by current tools?
9. What is the relationship between index mechanisms and adapter consistency scripts?

### Invocation examples / metadata

10. What is the source of the `financial-data-agent-bootstrap` missing canonical invocation examples finding?
11. Are canonical invocation examples a structure requirement, catalog requirement, or report-only metadata requirement?
12. Should `examples/invocation_examples.md` or an equivalent file be added?
13. Should this finding go into F1a, separate `catalog metadata cleanup`, or a governance task?

### F1a readiness

14. Does `financial-data-agent-bootstrap` need an adapter?
15. If it needs an adapter, which surfaces should be connected?
16. What is the minimal allowed F1a write scope?
17. Should F1a be split into:
   - invocation examples / metadata;
   - adapter;
   - index;
   - consistency tool updates?
18. Should existing adapter/index governance findings be addressed before connecting the new skill?

## 11. Required Review Report

F1 review must produce:

```text
docs/reviews/financial_data_agent_bootstrap_f1_adapter_index_review.md
```

Recommended report structure:

```text
# F1 Adapter + Index Review Report

## 1. Current Repository State
## 2. Existing Adapter Surfaces
## 3. Existing Index / Registry / Catalog Mechanism
## 4. Existing Consistency Checks
## 5. Existing Findings
## 6. financial-data-agent-bootstrap Discoverability Gap
## 7. Invocation Example / Metadata Assessment
## 8. Recommended Decision
## 9. Proposed F1a Scope
## 10. Out-of-Scope
## 11. Risk Assessment
## 12. Next Step
```

The report must separate observed facts from recommendations. Any inferred recommendation must name the supporting evidence.

## 12. Decision Framework

F1 review must end with exactly one of these decisions:

```text
A. No adapter/index needed for now
B. Add only canonical invocation examples / metadata
C. Add thin adapters + update necessary index
D. Pause new skill discovery exposure and fix adapter/index governance first
```

If the conclusion is clear, the review may recommend creating a separate F1a implementation task package. F1 review itself must not implement F1a.

## 13. F1a Scope Guardrails

If the review recommends F1a, it must describe a minimal implementation scope. That scope must specify:

- Which surfaces are allowed to change.
- Whether invocation examples are included or split out.
- Whether index files are included or split out.
- Whether any tool or test update is required, or explicitly deferred.
- Whether existing adapter/index governance findings must be resolved first.

F1a must remain separate from F1 review. F1 review cannot pre-create files for F1a.

## 14. Stop Conditions For F1 Review

Stop and report if any of the following occurs:

- Current `main` does not include PR #19, PR #20, PR #21, and PR #18.
- The working tree is not clean before F1 review begins.
- Continuing would require modifying adapter, index, tools, or tests.
- Continuing would require directly fixing the metadata finding.
- Continuing would require modifying `financial-data-agent-bootstrap` skill content.
- `git pull --ff-only` fails if it is attempted.
- The review needs real financial data, raw workbooks, raw attachments, credentials, DSNs, private URLs, or business project facts.

## 15. Validation Plan For F1 Review

F1 review should run at minimum:

```powershell
git diff --check
git status -sb --untracked-files=all
```

If a docs-only lightweight check exists and is clearly relevant, the reviewer may run the smallest relevant check. F1 review does not need to run adapter consistency or metadata audit, because the review is not implementing adapter or metadata changes.

## 16. Acceptance Criteria

F1 review is complete when:

- The review report exists at the required path.
- All required review questions are answered or explicitly marked as not determinable from authorized inputs.
- The report identifies actual discovery surfaces rather than assuming them.
- The report classifies adapter, index, registry, catalog, and invocation example mechanisms separately.
- The existing `financial-data-agent-bootstrap` missing canonical invocation examples finding is recorded but not fixed.
- The report ends with one of the four required decisions.
- Any proposed F1a scope is minimal, bounded, and separate from the review itself.
- Validation results are recorded.
- No out-of-scope files are modified.

## 17. Recommended Follow-Up Commit

If a later F1 review report is produced and validation passes, use an appropriate docs-only commit message such as:

```text
docs(skill): review financial data agent bootstrap discovery surfaces
```

If the review recommends implementation, create a separate F1a task package before any adapter, index, invocation example, or metadata cleanup work begins.
