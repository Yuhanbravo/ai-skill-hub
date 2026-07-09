# SKILLS_INDEX

This file is the cross-AI, repository-level skill index for tools that cannot automatically discover canonical skills or need a quick invocation-oriented overview.

## Naming

- Canonical repository name: `ai-skill-hub`
- Compatibility directories such as `.codex/` remain consumer-side entrypoints and are intentionally preserved.

## Canonical Rule

- Canonical source of truth: `skills/<skill>/`
- Primary adapter layer: `.agents/skills/<skill>/SKILL.md`
- Flat adapter summary: `.agents/skills/<skill>.md`
- Copilot fallback layer: `.github/skills/<skill>.md`
- Unified invocation contract: `skills/_protocol/skill_invocation.md`

## Skill Catalog

| Category | Use scenario classification | Name | Canonical path | Adapter entry | Flat entry | Copilot entry |
| --- | --- | --- | --- | --- | --- | --- |
| template | handoff / bounded execution | `chatgpt-handoff-pilot` | `skills/chatgpt-handoff-pilot/` | `.agents/skills/chatgpt-handoff-pilot/SKILL.md` | `.agents/skills/chatgpt-handoff-pilot.md` | `.github/skills/chatgpt-handoff-pilot.md` |
| audit | documentation audit / README governance | `documentation-governance` | `skills/documentation-governance/` | `.agents/skills/documentation-governance/SKILL.md` | `.agents/skills/documentation-governance.md` | `.github/skills/documentation-governance.md` |
| audit | folder structure audit / misplaced files | `file-structure-check` | `skills/file-structure-check/` | `.agents/skills/file-structure-check/SKILL.md` | `.agents/skills/file-structure-check.md` | `.github/skills/file-structure-check.md` |
| project | financial data agent bootstrap / contracts / safety boundaries | `financial-data-agent-bootstrap` | `skills/financial-data-agent-bootstrap/` | `.agents/skills/financial-data-agent-bootstrap/SKILL.md` | `.agents/skills/financial-data-agent-bootstrap.md` | `.github/skills/financial-data-agent-bootstrap.md` |
| project | financial-data migration advisory | `financial-data-project-migration` | `skills/financial-data-project-migration/` | `.agents/skills/financial-data-project-migration/SKILL.md` | `.agents/skills/financial-data-project-migration.md` | `.github/skills/financial-data-project-migration.md` |
| project | repository onboarding / takeover packet | `project-takeover` | `skills/project-takeover/` | `.agents/skills/project-takeover/SKILL.md` | `.agents/skills/project-takeover.md` | `.github/skills/project-takeover.md` |
| governance | single-skill evaluation / controlled rewrite | `skill-governance` | `skills/skill-governance/` | `.agents/skills/skill-governance/SKILL.md` | `.agents/skills/skill-governance.md` | `.github/skills/skill-governance.md` |
| system | skill-hub handoff / section-aware system merge | `system-handoff` | `skills/system-handoff/` | `.agents/skills/system-handoff/SKILL.md` | `.agents/skills/system-handoff.md` | `.github/skills/system-handoff.md` |
| system | system-layer status refresh / phase summary | `system-status-update` | `skills/system-status-update/` | `.agents/skills/system-status-update/SKILL.md` | `.agents/skills/system-status-update.md` | `.github/skills/system-status-update.md` |
| system | capability-system takeover / architecture assessment | `system-takeover` | `skills/system-takeover/` | `.agents/skills/system-takeover/SKILL.md` | `.agents/skills/system-takeover.md` | `.github/skills/system-takeover.md` |
| project | Git-based status refresh / weekly summary | `update-project-status` | `skills/update-project-status/` | `.agents/skills/update-project-status/SKILL.md` | `.agents/skills/update-project-status.md` | `.github/skills/update-project-status.md` |
| project | workflow bootstrap / role split / runtime-pack mapping | `workflow-bootstrap` | `skills/workflow-bootstrap/` | `.agents/skills/workflow-bootstrap/SKILL.md` | `.agents/skills/workflow-bootstrap.md` | `.github/skills/workflow-bootstrap.md` |

## Per-Skill Invocation Overview

### chatgpt-handoff-pilot

- Use scenario classification: `handoff`, `task package`, `bounded execution`, `execution report`
- Triggers: `prepare a handoff task package`; `bounded execution with execution report`; `split planning and implementation across AI agents`; `update the project handoff manual`; `enforce task boundaries for another agent`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use chatgpt-handoff-pilot for this task. task_description: Prepare a bounded handoff package for updating docs/HANDOFF.md.`
- Inputs: task package, local handoff rules, target files or directories
- Outputs: bounded implementation result, execution report, optional handoff document update

### documentation-governance

- Use scenario classification: `docs audit`, `duplicate detection`, `README governance`, `docs_readable boundary control`
- Triggers: `audit repository documentation structure`; `detect duplicate markdown documents`; `fix README governance issues`; `classify docs and docs_readable layers`; `archive or merge outdated documentation`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use documentation-governance for this task. task_description: Audit the repository documentation structure and detect duplicate markdown topics.`
- Inputs: repository root, markdown tree, governance config, optional style guide
- Outputs: audit report, duplicate/conflict findings, optional explicit doc fixes

### file-structure-check

- Use scenario classification: `folder audit`, `required path validation`, `misplaced file detection`
- Triggers: `audit repository folder structure`; `check required directories and paths`; `detect misplaced files in a repo`; `validate project layout against a profile`; `generate a structure audit report`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use file-structure-check for this task. task_description: Validate the repository layout against the data-project profile.`
- Inputs: target directory, rules, profile, strictness, optional local overrides
- Outputs: structure audit report, missing paths, misplaced files, repair suggestions

### financial-data-agent-bootstrap

- Use scenario classification: `agent bootstrap`, `data contract`, `source contract`, `safety boundary`, `task package`
- Triggers: `bootstrap a financial data agent project`; `create financial data project AGENTS template`; `define data contract and source contract`; `prepare financial data task package`; `enforce read-only and production-write boundaries`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use financial-data-agent-bootstrap for this task. task_description: Bootstrap a financial data script project with a thin AGENTS.md, data contract, and validation checklist.`
- Inputs: project root, task package (if available), project type classification, data domain and source system descriptions
- Outputs: AGENTS.md draft, data_contract draft, source_contract draft, validation checklist, task_package draft, execution_report draft, handoff template
- Boundary: operates in Review / Scaffold / Align / Enforce modes; defaults to read-only; do not use for investment advice, trading strategies, alpha research, or provider-specific API manuals

### financial-data-project-migration

- Use scenario classification: `migration advisory`, `Excel-heavy project assessment`, `boundary-first planning`
- Triggers: `assess financial data project migration readiness`; `classify Excel and Python script sprawl`; `recommend a safe target structure for a data project`; `evaluate Wind or desktop Excel coupling`; `draft a minimal migration todo`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use financial-data-project-migration for this task. task_description: Assess whether this financial-data Python repository is ready for structure migration.`
- Inputs: project root, Python scripts, Excel assets, coupling signals, document entrypoints
- Outputs: migration advisory, project-type judgment, risk summary, target-structure recommendation, minimal todo

### project-takeover

- Use scenario classification: `repository onboarding`, `takeover packet`, `first-repo scan`
- Triggers: `prepare a repository takeover packet`; `onboard a new maintainer or AI agent`; `scan docs config and task sources`; `generate an onboarding summary for a project`; `analyze an unfamiliar repository before maintenance`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use project-takeover for this task. task_description: Prepare a takeover packet for this unfamiliar repository.`
- Inputs: project root, optional config, optional script overrides, runtime parameters
- Outputs: takeover report, onboarding summary, environment findings, follow-up actions

### skill-governance

- Use scenario classification: `skill evaluation`, `diagnosis`, `controlled refactor gating`
- Triggers: `evaluate a skill against the template`; `diagnose skill maturity and structure`; `score a skill and decide rewrite level`; `govern a single skill before refactor`; `perform a controlled skill rewrite`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use skill-governance on <skill-path> rewrite=false`
- Inputs: one target skill path, current structure, rewrite authorization
- Outputs: scorecard, diagnosis, maturity decision, optional controlled rewrite result

### system-handoff

- Use scenario classification: `system handoff`, `section-aware merge`, `skill-hub handoff maintenance`
- Triggers: `update ai-skill-hub system handoff`; `maintain skill-hub handoff sections`; `refresh system boundaries in docs HANDOFF md`; `capture next phase direction for ai capability system`; `merge system-level handoff updates without full rewrite`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use system-handoff for this task. task_description: Update ai-skill-hub handoff as a system document without rewriting the whole file.`
- Inputs: `docs/HANDOFF.md`, current phase and capability facts, system boundaries, current design decisions
- Outputs: section-aware handoff update, system-oriented section content, bounded execution report
- Boundary: reuse `chatgpt-handoff-pilot`; do not rewrite the full handoff document or degrade into diff-oriented reporting

### system-status-update

- Use scenario classification: `system status`, `layer status refresh`, `phase summary`
- Triggers: `refresh ai-skill-hub system status`; `update skill-hub layer status and phase`; `generate a capability-system status summary`; `produce layer-oriented status for ai-skill-hub`; `summarize canonical distribution governance and tooling layers`
- Side effects: `read_only`, `write_files`, `requires_git`
- Invocation example: `Use system-status-update for this task. task_description: Refresh ai-skill-hub as a capability system and report the current layer status.`
- Inputs: system root, Git history, `skills/`, distribution surfaces, tooling and governance docs
- Outputs: `Layer Status`, `Current Phase`, `Capabilities`, `Stability`
- Boundary: reuse `update-project-status`; do not output file-by-file change lists or project-style construction summaries

### system-takeover

- Use scenario classification: `capability system takeover`, `system architecture assessment`, `multi-agent system analysis`
- Triggers: `analyze system architecture`; `analyze skill hub`; `analyze ai capability system`; `multi agent system analysis`; `analyze orchestration system`; `capability os assessment`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use system-takeover for this task. task_description: Analyze this skill-hub system and evaluate its capability architecture.`
- Inputs: system root, canonical skills, protocol docs, router and pipeline implementation, adapter entries, tooling, governance docs
- Outputs: system structure, capability map, layered maturity assessment, top bottlenecks, evolution plan
- Boundary: use `system-takeover` for capability systems and orchestration stacks; use `project-takeover` for ordinary repository onboarding and takeover packets

### update-project-status

- Use scenario classification: `status refresh`, `weekly summary`, `handoff-ready status update`
- Triggers: `refresh project status from Git history`; `generate a weekly project summary`; `merge commits and task sources into a status report`; `sync project status to a shared document`; `produce a handoff status update`
- Side effects: `read_only`, `write_files`, `requires_git`
- Invocation example: `Use update-project-status for this task. task_description: Refresh the project status report from recent Git history and current task sources.`
- Inputs: project root, recent Git history, optional task sources, config, output overrides
- Outputs: status markdown, status log, optional sync result, handoff-ready status summary

### workflow-bootstrap

- Use scenario classification: `workflow bootstrap`, `role split`, `role-optional orchestration`, `runtime-pack mapping`
- Triggers: `bootstrap a role-based workflow`; `define drafter reviewer implementer reporter final reviewer boundaries`; `select a role chain segment before bounded execution`; `map canonical guidance to a future runtime pack`; `explain thin entry versus full canonical guidance`; `document workflow shell boundaries without replacing handoff protocols`
- Side effects: `read_only`, `write_files`
- Invocation example: `Use workflow-bootstrap for this task. task_description: Select the needed Drafter -> Reviewer -> Implementer -> Reporter -> Final Reviewer role segment for this repository task, keeping chatgpt-handoff-pilot as the task package and execution report protocol owner.`
- Inputs: repository workflow goal, task boundaries, local collaboration rules, related canonical skills
- Outputs: workflow-shell guidance, role split, role-optional invocation guidance, canonical-to-runtime-pack mapping, thin-entry usage guidance
- Boundary: reuse `chatgpt-handoff-pilot` for task packages and execution reports; do not implement the future runtime pack inside the hub

## Interpretation Rules For Other AI Tools

1. Always treat `skills/` as the canonical source.
2. Use `.agents/skills/*.md` for the fastest flat discovery pass.
3. Use `.agents/skills/<skill>/SKILL.md` when a skill-aware agent expects a directory-based entry.
4. Use `.github/skills/` as the Copilot-oriented fallback discovery layer.
5. If adapter files and canonical files differ, prefer `skills/<skill>/SKILL.md`.
6. When invoking a skill, follow `skills/_protocol/skill_invocation.md` before applying any skill-specific steps.
