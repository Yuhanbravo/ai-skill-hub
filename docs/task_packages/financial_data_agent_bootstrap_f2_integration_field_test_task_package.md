# Financial Data Agent Bootstrap F2 Integration / Field-Test Task Package

## 1. Purpose

This task package authorizes only a future field-test design, integration dry-run, and dogfood evidence round for `financial-data-agent-bootstrap`.

F2 is intended to validate whether the skill can be invoked naturally in realistic but non-sensitive financial-data bootstrap workflows, and whether its outputs are bounded, useful, and safe. This package does not authorize direct field-testing, real project onboarding, skill core changes, adapter/index changes, tool changes, test changes, template changes, reference changes, or connection to any business project.

## 2. Baseline

- Repository: `ai-skill-hub`
- Target skill: `skills/financial-data-agent-bootstrap/`
- Baseline main HEAD for this package: `502a5d6`
- F1a status: merged via PR #25 into `main`
- Known completed stages:
  - F0: canonical skill skeleton
  - F0.1: README structure fix
  - F1: adapter/index review
  - F1a: Discovery Exposure Package, implementation, and PR merge closeout
- Current discovery state: `financial-data-agent-bootstrap` is discoverable through canonical and adapter surfaces.
- Previous audit finding resolved: `financial-data-agent-bootstrap` missing canonical invocation examples.

Current discovery surfaces include:

```text
skills_index.json
SKILLS_INDEX.md
.agents/skills/skills_index.md
.agents/skills/financial-data-agent-bootstrap/SKILL.md
.agents/skills/financial-data-agent-bootstrap.md
.github/skills/financial-data-agent-bootstrap.md
skills/financial-data-agent-bootstrap/examples/invocation_examples.md
```

F1a validation passed with:

```text
git diff --check main...HEAD
python tests/test_skill_structure.py
python tools/check_adapter_consistency.py . --mode hub
python tools/audit_derivative_surfaces.py
```

Observed F1a results:

```text
12 canonical skills = 12 agents = 12 github
0 bridge drift
0 metadata drift
```

## 3. F2 Positioning

F2 validates the skill in a realistic but fictional or fully sanitized invocation context. It is field-test design, integration dry-run, and dogfood evidence only.

F2 should validate:

- Whether the skill can be invoked naturally from a realistic project-bootstrap request.
- Whether the expected outputs are clear and bounded.
- Whether the skill's safety boundaries prevent leakage of project-specific facts.
- Whether generated handoff, contract, and validation planning artifacts are useful.
- Whether future improvements are needed.

F2 must not:

- Add another discovery surface.
- Expand adapters or indexes.
- Modify canonical skill content.
- Add tools or tests.
- Add templates or references.
- Encode real business project rules.
- Connect any real business repository, data pipeline, mailbox archive, workbook, data service, or production system.
- Introduce real financial data, real paths, product names, schema names, mailbox rules, credentials, client names, fund names, broker names, custodian names, database details, or business-specific calculation rules.

## 4. Field-Test Scenario Policy

F2 recognizes three scenario classes:

| Scenario class | Definition | F2 decision |
| --- | --- | --- |
| Fictional scenario | A fully invented project shape using placeholders, invented dataset names, invented source names, invented paths, and no real business facts. | Use by default. |
| Sanitized real-project-shaped scenario | A scenario inspired only by general workflow shape, where all names, paths, schemas, products, counterparties, data, business rules, and operational details are fictionalized. | Allowed only if every identifying or reconstructable detail is replaced with fictional placeholders. |
| Real project scenario | A scenario that uses real project names, real paths, real schemas, real source systems, real counterparties, real products, real clients, real funds, real data, or real business rules. | Not allowed in `ai-skill-hub`. |

The future F2 implementer should use a fictional scenario by default. A sanitized real-project-shaped scenario is allowed only when it is impossible to infer the original project, data, path, schema, product universe, counterparty set, or business rule from the test inputs or outputs.

## 5. Recommended Scenario

Primary recommended scenario:

```text
fictional NAV data project bootstrap
```

The fictional scenario may describe a placeholder team asking the skill to bootstrap a financial data project that needs:

- a thin agent entrypoint outline;
- a data contract outline;
- a source contract outline;
- a validation plan;
- a bounded task package outline;
- an execution report outline;
- handoff and maintainer-confirmation notes.

All names, paths, schemas, data samples, product labels, source systems, and rules must be fictional placeholders.

Acceptable alternative scenarios:

```text
fictional derivative data archive bootstrap
fictional valuation workbook migration bootstrap
multi-agent handoff / controller-feedback dry-run
```

The future implementer may choose one primary scenario and optionally compare one secondary scenario. Any comparison must remain fictional or fully sanitized.

## 6. Allowed Deliverables for the Future F2 Implementation Round

Future F2 implementation should produce docs-only dogfood evidence. Recommended deliverables:

```text
docs/dogfood/financial_data_agent_bootstrap_f2_field_test_report.md
docs/reviews/financial_data_agent_bootstrap_f2_field_test_review.md
```

If existing repository conventions later prefer another docs location, the future implementer should follow the closest current convention and explain the path choice in the final report.

Future F2 implementation may quote or summarize generated outlines only when they contain fictional placeholders and no real business facts.

## 7. Explicit Non-Goals

F2 implementation must not:

- modify `skills/financial-data-agent-bootstrap/SKILL.md`;
- modify `skills/financial-data-agent-bootstrap/templates/**`;
- modify `skills/financial-data-agent-bootstrap/references/**`;
- modify `skills/financial-data-agent-bootstrap/examples/**`;
- modify `.agents/**`;
- modify `.github/**`;
- modify `skills_index.json`;
- modify `SKILLS_INDEX.md`;
- modify `tools/**`;
- modify `tests/**`;
- modify `templates/**`;
- modify `references/**`;
- modify real business project files;
- add adapters, indexes, registries, catalog entries, or discovery surfaces;
- add or regenerate tool output;
- add real financial data or real operational details.

## 8. Data / Privacy / Business Boundary

F2 must preserve the open skill-hub boundary. The future field-test may use only fictional placeholders or fully sanitized descriptions that cannot reconstruct a real business environment.

Forbidden content includes:

- real Windows, Unix, network, object-storage, workbook, archive, or repository paths;
- real schema, table, column, database, DSN, URL, host, queue, mailbox, subject, attachment, or credential details;
- real client, fund, broker, custodian, counterparty, issuer, account, portfolio, strategy, product, or registry names;
- real valuation, NAV, pricing, reconciliation, exception-handling, mailbox-routing, or data-lineage rules;
- raw or reconstructable financial data;
- private mapping tables or samples that could reveal identities or business processes.

Evidence should use only fictional counts, placeholder schema summaries, placeholder manifest paths, and synthetic validation summaries.

## 9. Execution Design for Future Field-Test

The future F2 implementation should proceed as a dry-run:

1. Re-read this package, `skills/financial-data-agent-bootstrap/SKILL.md`, and any directly relevant existing F0/F1/F1a package or report.
2. Confirm the selected scenario class and explain why it is fictional or fully sanitized.
3. Write the exact prompt used to invoke `financial-data-agent-bootstrap`.
4. Generate or simulate the expected artifact outline without creating project onboarding files.
5. Review whether the generated outline contains the expected data contract, source contract, validation, task package, execution report, and handoff sections.
6. Check all output for leakage of real project facts or reconstructable business details.
7. Record usability observations and boundary observations.
8. Decide whether the skill core appears sufficient, or whether a separate F2a/F2b package should be proposed.

The dry-run should remain document evidence only. It should not create real project entrypoints, connect data sources, run provider tools, inspect raw workbooks, inspect mailboxes, or validate real data.

## 10. Expected Dogfood Report Structure

The future dogfood report should include:

- scenario used;
- prompt used to invoke the skill;
- generated artifact outline;
- boundary observations;
- usability observations;
- leakage check;
- whether skill core needs change;
- whether F2a/F2b follow-up is recommended;
- final decision: `PASS`, `PASS_WITH_WARN`, `NEEDS_FOLLOWUP`, or `STOPPED`.

The report should separate observed evidence from recommendations. If the implementer infers that a skill improvement is needed, the report must name the fictional evidence that supports the inference.

## 11. Skill Change Decision Rules

F2 implementation must not modify the skill directly.

Future F2 may propose a follow-up only if one or more of the following is observed with fictional or fully sanitized inputs:

- invocation is ambiguous even with fictional inputs;
- output structure is consistently missing required contract, validation, or handoff sections;
- safety boundary is unclear or too weak;
- templates or references are insufficient for reusable, non-project-specific use.

Any future skill change must become a separate F2a or F2b task package with its own scope, branch, validation plan, and acceptance criteria.

## 12. Stop Conditions

The future field-test must stop and report if:

- it requires real business data;
- it requires real paths or schema names;
- it requires project-specific business rules;
- it requires modifying skill core to finish the dry-run;
- it starts becoming real project onboarding;
- it attempts to update adapters, indexes, or discovery surfaces;
- it requires tools, tests, templates, or references changes not authorized by a separate package;
- it would expose or reconstruct real clients, funds, products, counterparties, credentials, mailbox rules, database details, or private operational processes.

## 13. Validation Requirements

For this package-only round, run:

```powershell
git diff --check
git status --short --branch
```

If repository standard validations are cheap and relevant, also run:

```powershell
python tests/test_skill_structure.py
```

Do not run tool or adapter regeneration unless this package unexpectedly changes skill surfaces, which it should not.

Future F2 implementation should validate only the docs it creates and should not run adapter/index regeneration unless separately authorized.

## 14. Final Report Requirements

This package-only round final report must include:

- branch;
- baseline HEAD before edit;
- final HEAD or commit;
- changed files;
- package summary;
- validation results;
- confirmed not modified list;
- deviations from expected scope;
- recommended next step.

The final report must explicitly confirm:

- no skill core modified;
- no adapters or indexes modified;
- no tools, tests, templates, or references modified;
- no real business project files modified;
- no real financial data, paths, product names, database details, mailbox rules, credentials, clients, brokers, custodians, or fund names introduced.

Recommended commit message:

```text
docs(skill): add financial data agent bootstrap F2 field-test package
```

If a commit hook rejects that scope, use:

```text
docs: add financial data agent bootstrap F2 field-test package
```
