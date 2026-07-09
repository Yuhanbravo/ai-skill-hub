# Financial Data Agent Bootstrap F2 Field-Test Report

## 1. Scenario Used

Scenario class: fictional scenario.

Primary scenario:

```text
fictional NAV data project bootstrap
```

Fictional placeholders used:

```text
Project name: Fictional_NAV_Data_Project
Repository path: <fictional-repo-root>
Database: <fictional-readonly-db>
Product universe: <fictional-product-universe>
Data source: <fictional-nav-source>
Output target: <fictional-reporting-layer>
```

This dry-run did not use or infer any real project, real path, real schema, real table, real field, real product, real fund, real client, real broker, real custodian, real mailbox rule, real credential, real financial data, or real business calculation rule.

## 2. Prompt Used To Invoke The Skill

```text
Use financial-data-agent-bootstrap in Scaffold Mode for a docs-only dry-run.

task_description:
- Bootstrap planning artifacts for Fictional_NAV_Data_Project.
- The fictional project reads NAV-like records from <fictional-nav-source>.
- The fictional project treats <fictional-readonly-db> as read-only.
- The fictional project validates coverage for <fictional-product-universe>.
- The fictional project publishes validated summary outputs to <fictional-reporting-layer>.

constraints:
- This is not real project onboarding.
- Do not inspect, connect to, or name any real repository, database, mailbox, workbook, schema, product, fund, client, broker, custodian, credential, or financial dataset.
- Use only placeholders.
- Do not create project files.
- Do not modify financial-data-agent-bootstrap core, templates, references, examples, adapters, indexes, tools, or tests.
- Default to read-only and dry-run.
- Treat all business facts, date semantics, write authorization, sample policy, output policy, and validation baseline as maintainer-confirmation items.

expected_output:
- Expected artifact outline only.
- Boundary observations.
- Usability observations.
- Leakage check.
- Recommendation on whether skill core needs change or a later F2a/F2b package.
```

## 3. Expected Artifact Outline From The Skill

Observed planning shape from the dry-run:

```text
Fictional_NAV_Data_Project bootstrap outline

1. Thin project entrypoint outline
   - Purpose: route agents to project docs, task package, and canonical skill.
   - Canonical reference: financial-data-agent-bootstrap.
   - Project-fill fields remain placeholders.
   - Default execution mode: read-only / dry-run unless a task package authorizes more.

2. Data contract outline
   - Dataset identity: <fictional-dataset-id>
   - Grain: <fictional-record-grain>
   - Primary identifier: <placeholder-primary-key>
   - Date field: <placeholder-date-field>
   - Product universe: <fictional-product-universe>
   - Required fields: <placeholder-required-fields>
   - Null policy: <placeholder-null-policy>
   - Sensitive fields: <placeholder-sensitive-fields>
   - Owner confirmation: maintainer required

3. Source contract outline
   - Source identity: <fictional-nav-source>
   - Access mode: read-only
   - Credential boundary: credentials not included
   - Freshness expectation: <placeholder-freshness-policy>
   - Retry/failure policy: <placeholder-retry-policy>
   - Source-target reconciliation: structural counts and placeholder identifiers only

4. Validation plan outline
   - Row count check
   - Primary key uniqueness check
   - Date min/max check
   - Required field null check
   - Product universe coverage check
   - Illegal value check
   - Source-target reconciliation summary
   - Idempotency check
   - Manifest completeness check
   - Sensitive output check
   - git diff --check for docs-only changes

5. Bounded task package outline
   - Scope: scaffold planning documents only
   - Allowed changes: placeholder docs in the fictional project only after maintainer authorization
   - Forbidden changes: production write, DDL, scheduler changes, full refresh, backfill, real-data inspection, credentials
   - Validation plan: structural checks and leakage review
   - Stop conditions: real facts or external side effects required

6. Execution report outline
   - Files changed
   - Files explicitly not changed
   - Validation results
   - Evidence: counts, schema summary, hashes, manifest paths, redacted samples, validation summaries
   - Sensitive information check
   - Production-write confirmation
   - Risks, assumptions, and next steps

7. Handoff / maintainer confirmation outline
   - Current status
   - Data boundary
   - Environment boundary
   - Project-fill fields pending maintainer confirmation
   - Open questions
   - Recommended next task package
```

The outline is reusable and does not require real project facts to be useful at the planning level.

## 4. Boundary Observations

- The skill is callable from a natural fictional financial-data bootstrap request.
- The four operating modes provide enough structure to select Scaffold Mode for this docs-only dry-run.
- The fixed safety rules clearly default to read-only and block production write, DDL, scheduler changes, full refresh, backfill, credentials, raw workbooks, raw attachments, and private mappings.
- The project-fill field list correctly pushes business purpose, data domain, source systems, target systems, date semantics, validation baseline, write authorization, output policy, and sample policy back to a maintainer or task package.
- The stop conditions are strong enough to stop if the dry-run begins requiring real data, real paths, real schema names, real business rules, or skill core changes.
- The skill relationship notes correctly leave general task package and execution report protocol ownership with `chatgpt-handoff-pilot`, and workflow shell ownership with `workflow-bootstrap`.

## 5. Usability Observations

- The skill gives a reasonable reusable artifact set: thin entrypoint, data contract, source contract, validation, task package, execution report, handoff, review notes, and maintainer checklist.
- The prompt can stay concise because the skill already defines expected outputs, human/agent responsibilities, safety boundaries, and validation expectations.
- The validation expectations are concrete enough for a fictional NAV dry-run without becoming project-specific.
- The skill is usable without modifying templates or reading real project artifacts.
- No optional review file is needed from this dry-run because the observations do not rise to a separate review finding.

## 6. Leakage Check

Result: no leakage observed.

Checked for forbidden content:

- No `AMS_Data`, `Derivative_Data`, or `Pricing_sheet`.
- No real repository, filesystem, network, object-storage, workbook, archive, or mailbox paths.
- No real database, schema, table, column, DSN, URL, host, queue, subject, attachment, credential, token, cookie, or private key.
- No real product, fund, client, broker, custodian, counterparty, issuer, account, portfolio, strategy, registry, or mapping table.
- No raw or reconstructable financial data.
- No real valuation, NAV, pricing, reconciliation, exception-handling, mailbox-routing, lineage, or business calculation rule.

The only domain wording retained is generic and fictional: NAV-like planning placeholders for `Fictional_NAV_Data_Project`.

## 7. Whether Skill Core Needs Change

Decision: no skill core change needed from this dry-run.

Rationale:

- The skill is callable.
- The skill remains bounded.
- The skill produces a reasonable planning artifact outline without real project facts.
- The stop conditions and sensitive information boundary are adequate for this fictional scenario.
- The dry-run did not require changes to `SKILL.md`, templates, references, examples, adapters, indexes, tools, or tests.

## 8. Whether F2a / F2b Follow-Up Is Recommended

Recommendation: no required F2a or F2b follow-up.

Optional future work, only if maintainers want broader evidence, would be another fictional dry-run using a different fictional scenario class. This report does not recommend a skill-change package because it found no reusable skill gap or safety violation.

## 9. Final Decision

Decision: `PASS`

Reason:

`financial-data-agent-bootstrap` is callable, bounded, and produces a reasonable reusable planning shape using only fictional inputs. Completing the dry-run did not require real project facts or prohibited modifications.

## 10. Boundary Confirmations

- No skill core modified.
- No adapters or indexes modified.
- No tools, tests, templates, or references modified.
- No business project files modified.
- No real financial data, paths, products, schemas, mailbox rules, credentials, clients, brokers, custodians, or fund names introduced.
