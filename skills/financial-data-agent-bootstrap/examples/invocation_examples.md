# Invocation Examples

These examples illustrate how to invoke `financial-data-agent-bootstrap` for common financial data project bootstrap scenarios. All paths, project names, product names, and data references are fictional placeholders.

> Active canonical policy: examples must remain abstract, non-sensitive, and free of real business facts. Do not introduce real paths, real product names, real database details, real credentials, real mailbox rules, or real financial data.

### Input Example

```text
Use financial-data-agent-bootstrap for this task.

task_description:
- Bootstrap a financial data script project with a thin AGENTS.md, data contract, and validation checklist.

constraints:
- Do not read real financial data.
- Do not write real database credentials or DSNs.
- Keep all generated files as placeholder drafts.

expected_output:
- Project-level AGENTS.md (thin entry)
- data_contract draft
- source_contract draft
- validation checklist draft

context_files:
- README.md
- task_package (if available)
```

## Example 1: Initialize AGENTS.md for a financial data script project

Use `financial-data-agent-bootstrap` in Scaffold Mode to create a thin project-level `AGENTS.md` for a desktop automation or data extraction script project.

Example prompt:

```text
Use financial-data-agent-bootstrap in Scaffold Mode.

task_description:
- Generate a thin AGENTS.md for a financial data script project.
- The project runs on a scheduled desktop environment and reads from Wind/API/Excel sources.

constraints:
- Keep AGENTS.md thin and reference-first.
- Do not duplicate canonical skill content.
- Use placeholder values for project name, data domain, source systems, and runtime environment.
- Do not include real paths, real DSNs, or real credentials.

expected_output:
- AGENTS.md with project-fill fields left as <PLACEHOLDER>
- Brief read-only / dry-run boundary statement
```

Expected framing:

- AGENTS.md stays thin; canonical rules remain in `financial-data-agent-bootstrap/SKILL.md`
- Project-fill fields are listed but not finalized
- No real business facts introduced
- Read-only default is stated

## Example 2: Create contracts and validation for a valuation/NAV project

Use `financial-data-agent-bootstrap` in Scaffold Mode to produce `data_contract`, `source_contract`, and `validation` drafts for a valuation or NAV data project.

Example prompt:

```text
Use financial-data-agent-bootstrap in Scaffold Mode.

task_description:
- Create data_contract, source_contract, and validation drafts for a valuation data project.
- The project consumes NAV-related data from an external API, an Excel workbook, and a CSV export.

constraints:
- Use placeholder dataset names, field names, and source descriptions.
- Do not include real valuation figures, real fund codes, real product identifiers, or real NAV calculation details.
- Keep validation checks at the structural level (row count, null check, date range, uniqueness).

expected_output:
- data_contract with placeholder dataset definitions
- source_contract with placeholder source system descriptions
- validation checklist covering structural checks only
```

Expected framing:

- Contracts use placeholder field names and dataset identifiers
- Validation focuses on structural checks, not business-metric accuracy
- No real fund, portfolio, or valuation data introduced
- Maintainer must fill business facts before any real-data run

## Example 3: Generate a task package for data source governance

Use `financial-data-agent-bootstrap` to prepare a task package for governing Wind/API/Excel/CSV data source integration in a financial data project.

Example prompt:

```text
Use financial-data-agent-bootstrap in Scaffold Mode.

task_description:
- Generate a task package for governing data sources in a multi-source financial data project.
- Sources include: a Wind terminal export, a REST API feed, an Excel workbook, and CSV batch files.

constraints:
- Do not specify real API endpoints, real Wind formulas, real file paths, or real workbook names.
- Scope the task package to source registration, contract creation, and validation planning.
- Default to read-only and dry-run for all source access.

expected_output:
- task_package covering source registration, source_contract creation, and validation scope
- Explicit read-only / dry-run authorization
- Out-of-scope list (no production write, no DDL, no scheduler changes)
```

Expected framing:

- Task package enumerates source types generically
- Authorization boundaries (read-only, dry-run) are explicit
- No real endpoint URLs, file paths, or credentials
- Stop conditions are listed in the package

## Example 4: Establish handoff templates for multi-agent workflows

Use `financial-data-agent-bootstrap` to create handoff and context templates for multi-agent, side-channel, or controller-feedback workflows.

Example prompt:

```text
Use financial-data-agent-bootstrap in Scaffold Mode.

task_description:
- Create handoff and context templates for a multi-agent financial data workflow.
- The workflow involves a main agent, a side-channel validation agent, and a controller responsible for feedback and re-injection.

constraints:
- Keep handoff templates thin and boundary-focused.
- Define handoff fields: scope, completed steps, evidence pointers, unresolved risks, next agent, and stop conditions.
- Do not embed real project paths, real agent names, or real control-flow details.

expected_output:
- handoff/context template with structured handoff fields
- Brief description of side-channel and controller-feedback patterns
```

Expected framing:

- Handoff templates use structured fields, not free-form narratives
- Side-channel and controller-feedback patterns are described abstractly
- No real agent identifiers, queue names, or IPC details
- Templates remain reusable across different financial data project types

## Example 5: Review existing project boundaries in Review Mode

Use `financial-data-agent-bootstrap` in Review Mode to assess whether an existing financial data project has adequate agent boundaries, contracts, and safety rules.

Example prompt:

```text
Use financial-data-agent-bootstrap in Review Mode.

task_description:
- Review an existing financial data project to assess whether its AGENTS.md, data contract, source contract, validation, and handoff documents are sufficient.
- Identify gaps in read-only enforcement, production-write authorization, and sensitive-information handling.

constraints:
- Read-only scan; do not modify any files.
- Do not read real financial data files.
- Report findings as a structured review note, not as a rewritten document set.
- Flag any discovered credentials, DSNs, tokens, or real paths as high-severity risks.

expected_output:
- Review notes covering AGENTS.md thinness, contract coverage, validation completeness, and safety boundary gaps
- Risk list ordered by severity
- Suggested next actions (scaffold missing documents, align existing ones, or enforce boundaries)
```

Expected framing:

- Review is read-only and non-destructive
- Findings are structured by category and severity
- Sensitive-information exposure is flagged explicitly
- Recommendations reference canonical skill sections

## Example 6: Align existing project documents to canonical contract fields

Use `financial-data-agent-bootstrap` in Align Mode to converge existing project documents onto a consistent set of contract fields and boundaries.

Example prompt:

```text
Use financial-data-agent-bootstrap in Align Mode.

task_description:
- Align an existing project's data_contract, source_contract, and validation checklist to the canonical field set and boundary definitions.
- The project has drifted: contracts use inconsistent field names, and the validation checklist mixes structural and business-metric checks.

constraints:
- Do not expand the canonical contract field set with project-specific additions.
- Converge naming only; do not rewrite contract content.
- Flag business-metric checks that should move to a separate business-validation document.

expected_output:
- Alignment summary showing before/after field mapping
- List of business-metric checks recommended for extraction
- Updated drafts with consistent field naming
```

Expected framing:

- Alignment converges structure, not content
- Business-metric checks are identified and suggested for extraction
- No new canonical fields introduced
- Maintainer confirms alignment before finalization

## Transition Notes

When invocation examples above produce drafts, the maintainer must:

1. Fill all project-fill fields with real business facts (in the project repo, not in this skill-hub).
2. Confirm read-only / write / production-side-effect authorization before any real-data execution.
3. Review all stop conditions against the actual project environment.
4. Never backfill real business facts into `skills/financial-data-agent-bootstrap/`.

For bounded execution after bootstrap, use `chatgpt-handoff-pilot` as the task package and execution report protocol owner. For workflow shell and role split guidance, use `workflow-bootstrap`.
