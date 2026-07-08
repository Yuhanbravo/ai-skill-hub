# Task Package

## Background

`<project-name>` 因 `<business-purpose>` 需要完成 `<task-summary>`。

## Objective

交付 `<specific-output>`，同时遵守金融数据安全边界与项目 contracts。

## Repository / Branch

- Repository：`<repo-name-or-location-placeholder>`
- Base branch：`<base-branch>`
- Implementation branch：`<branch-name>`
- Current HEAD：`<commit-or-pending>`

## Required Reading

1. `AGENTS.md`
2. `<project-docs-path>`
3. `<data-contract-path>`
4. `<source-contract-path>`
5. `<validation-plan-path>`
6. `skills/financial-data-agent-bootstrap/SKILL.md`

## Allowed Changes

- `<allowed-path-or-file-1>`
- `<allowed-path-or-file-2>`

## Forbidden Changes

- 未在下方明确授权的 production write。
- 未在下方明确授权的 DDL、scheduler change、full refresh、backfill、email send、external upload 或其他外部副作用。
- 提交 raw valuation workbook。
- 提交 raw mail attachment。
- 提交 credentials / DSNs / tokens / cookies。
- 提交 private product registry exports。
- 提交完整敏感 customer/product mapping tables。
- 修改 `<authorized-scope>` 之外的路径。

## Financial Data Boundary

- Read-only / write authorization：`<read-only-or-explicit-write-boundary>`
- Data source scope：`<source-scope>`
- Target system scope：`<target-scope>`
- Production side effects：`<not-authorized/or-exact-authorized-action>`
- Sample / redaction policy：`<policy>`
- Manifest / audit trail requirement：`<required/not-required + details>`
- Ignored output directory：`<ignored-output-dir>`

## Implementation Plan

1. `<step-1>`
2. `<step-2>`
3. `<step-3>`

## Validation Plan

- `<validation-command-or-check-1>`
- `<validation-command-or-check-2>`
- `git diff --check`

## Evidence Requirements

报告证据使用：

- counts
- schema summary
- hash
- manifest path
- redacted sample
- validation summary

不得报告 raw sensitive rows、raw workbook content、raw mail body、secrets 或完整 mapping tables。

## Sensitive Data Constraints

- `<constraint-1>`
- `<constraint-2>`

## Out Of Scope

- `<out-of-scope-1>`
- `<out-of-scope-2>`

## Acceptance Criteria

- `<criterion-1>`
- `<criterion-2>`
- Validation 通过或失败均需清楚报告。
- Execution report 需确认 sensitive information check 和 out-of-scope boundaries。

## Stop Conditions

- 必需项目事实缺失或互相冲突。
- 继续实施需要未授权的 production write、DDL、scheduler change、full refresh、backfill 或 external side effect。
- 继续实施需要 raw sensitive data 或 credentials。
- worktree 存在可能被覆盖的无关未提交改动。
- validation 暴露需要人工决策的数据质量问题。

## Recommended Commit Message

`<type(scope): concise summary>`

## Open Questions

- `<question-1>`
- `<question-2>`
