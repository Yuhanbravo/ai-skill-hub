# Validation Plan

## Scope

- Project：`<project-name>`
- Dataset / source：`<dataset-or-source-name>`
- Task package：`<task-package-path>`
- Mode：`<dry-run/real-run/read-only-review>`
- Write authorization：`<not-authorized/authorized-with-boundary>`

## Required Checks

| Check | Method | Expected Result | Evidence | Status |
| --- | --- | --- | --- | --- |
| Row count | `<count-method>` | `<expected-range>` | `<count-summary>` | `<pending/pass/fail>` |
| Primary key uniqueness | `<key-list>` | `0 duplicates unless authorized` | `<duplicate-count>` | `<pending/pass/fail>` |
| Date min/max | `<date-field>` | `<expected-range>` | `<min-max-summary>` | `<pending/pass/fail>` |
| Product universe coverage | `<coverage-method>` | `<expected-coverage>` | `<coverage-summary>` | `<pending/pass/fail>` |
| Required field null check | `<field-list>` | `0 unexpected nulls` | `<null-summary>` | `<pending/pass/fail>` |
| Illegal value check | `<range/list/sign/date-order>` | `0 illegal values` | `<illegal-value-summary>` | `<pending/pass/fail>` |
| Source-target reconciliation | `<method>` | `<tolerance>` | `<reconciliation-summary>` | `<pending/pass/fail>` |
| Idempotency | `<rerun-or-hash-method>` | `<same-result-or-no-duplicate-write>` | `<idempotency-summary>` | `<pending/pass/fail>` |
| Dry-run vs real-run delta | `<delta-method>` | `<authorized-delta-only>` | `<delta-summary>` | `<pending/pass/fail/not-applicable>` |
| Manifest completeness | `<manifest-method>` | `<required-fields-present>` | `<manifest-path-or-summary>` | `<pending/pass/fail>` |
| Sensitive output check | `<scan-or-review-method>` | `no raw sensitive data` | `<redaction-summary>` | `<pending/pass/fail>` |
| Focused tests | `<test-command>` | `pass` | `<test-output-summary>` | `<pending/pass/fail>` |
| Git whitespace check | `git diff --check` | `pass` | `<command-output-summary>` | `<pending/pass/fail>` |

## Evidence Policy

报告中允许使用的证据：

- counts
- schema summary
- hash
- manifest path
- redacted sample
- validation summary
- error summary

不得粘贴 raw valuation workbooks、raw mail attachments、credentials、DSNs、tokens、cookies、private registry exports 或完整敏感 customer/product mapping tables。

## Failure Handling

- Blocking failure：`<stop-condition>`
- Non-blocking warning：`<warning-condition>`
- Required human review：`<review-condition>`
- Quarantine / ignored output policy：`<output-policy>`

## Approval

- Validation owner：`<owner>`
- Data owner confirmation：`<pending/confirmed/not-required>`
- Production write confirmation：`<not-authorized/authorized-by-task-package>`
