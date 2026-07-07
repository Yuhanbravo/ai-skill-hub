# AGENTS.md

## Project Purpose

`<project-name>` 是用于 `<business-purpose>` 的金融数据项目。

本文件是项目级薄入口，保持 reference-first。它不是完整项目规则库。

## Required Reading

实施前必须读取：

1. `<project-docs-path>`
2. `<data-contract-path>`
3. `<source-contract-path>`
4. `<validation-plan-path>`
5. `<current-task-package-path>`
6. `skills/financial-data-agent-bootstrap/SKILL.md`

如有冲突，以当前 task package 和项目维护者确认过的项目 docs 为准。

## Hard Boundaries

- Default to read-only。
- 未经 task package 明确授权，不得 production write。
- 未经明确授权，不得执行 DDL、scheduler change、full refresh、backfill、email send、external upload 或其他外部副作用。
- 未经明确授权且未给出 redaction rules，不得读取、复制、摘要或提交 raw sensitive financial data。
- 不得提交 credentials、DSNs、tokens、cookies、raw valuation workbooks、raw mail attachments、private registry exports 或完整敏感 mapping tables。

## Standard Workflow

1. 读取 required docs 和 task package。
2. 复述 allowed changes、forbidden changes、data scope、write authorization 和 validation plan。
3. 优先 dry-run 后 write。
4. 除非 task package 授权其他路径，生成物默认进入 `<ignored-output-dir>`。
5. 数据产物保留 manifest / audit trail evidence。
6. 报告 validation results 和 out-of-scope confirmations。

## Financial Data Validation

按项目 validation plan 覆盖：

- row count
- primary key uniqueness
- date min/max
- product universe coverage
- required field null check
- illegal value check
- source-target reconciliation
- idempotency
- dry-run vs real-run delta
- manifest completeness
- sensitive output check
- focused tests
- `git diff --check`

## Sensitive Data Rules

报告证据优先使用 counts、schema summary、hashes、manifest paths、redacted samples 和 validation summaries。不要在报告中粘贴 raw customer、product、valuation、position、mail、credential 或 mapping data。

## Git / Report Requirements

- 保持在 task package 指定的 task branch。
- 只修改授权路径。
- 运行 task package 指定的 validation commands。
- 输出 execution report，包含 changed files、validation results、sensitive information check、known issues 和 next step。

## Conflict Resolution

如果本文件与 canonical skill、project docs 或 task package 冲突，停止并报告冲突。不要把本文件扩写成第二套本地规则库。
