---
name: financial-data-agent-bootstrap
description: "Use when bootstrapping agent rules, contracts, validation, task packages, reports, and handoff boundaries for financial data engineering or operations projects."
metadata:
   triggers:
      - bootstrap a financial data agent project
      - create financial data project AGENTS template
      - define data contract and source contract
      - prepare financial data task package
      - enforce read-only and production-write boundaries
   side_effects:
      - read_only
      - write_files
---
# Financial Data Agent Bootstrap

`financial-data-agent-bootstrap` 是面向金融数据工程、运营数据治理、估值/NAV、衍生品、邮箱归档、Oracle 数据服务等项目的 agent bootstrap skill。它用于帮助项目建立薄入口、数据契约、数据源契约、验证清单、任务包、执行回执和 handoff/context 模板。

它不是投资建议 skill，不是交易策略 skill，不是 alpha research skill，不是 provider-specific API 手册，也不是某一个真实业务项目的规则集合。

## Purpose

本 skill 的目标是把金融数据项目里容易混在一起的内容拆开：

- 项目级入口保持 thin / reference-first；
- 项目事实进入项目 docs；
- 本轮授权进入 task package；
- 数据口径进入 data contract / source contract；
- 验证证据进入 validation 和 execution report；
- 敏感事实留在受控项目环境内，不进入开源 skill-hub。

## When to use

当金融数据项目需要以下任一能力时使用：

- 初始化或审阅项目级 `AGENTS.md` / `CLAUDE.md` 薄入口；
- 建立 dataset、source、validation、handoff、task package、execution report 模板；
- 把 read-only、dry-run、production write、DDL、scheduler、full refresh、backfill 等边界写清楚；
- 为 Wind、Oracle、Excel workbook、mail archive、Web/API、CSV/Parquet 等数据源建立可复核的约束；
- 在多 agent / 旁路 / 总控回灌工作流中固定金融数据项目的安全边界。

## Project type classification

适用项目类型包括：

- `desktop automation script`
- `valuation workbook parser`
- `Wind data extraction pipeline`
- `Oracle-backed data service`
- `mail raw archive pipeline`
- `analysis/reporting service`
- `agent skill hub / workflow governance project`
- 其他金融数据处理/分析脚本或服务

使用前应先判断项目是否包含生产写入、真实敏感数据、外部系统副作用、批处理调度、人工桌面操作或强 provider coupling。风险越高，默认越应停留在 Review Mode 或 Scaffold Mode。

## Operating Modes

### Review Mode

只读取项目文档、任务包、目录结构和脱敏样例，评估现有 agent 边界、数据契约、source contract、validation 和 handoff 是否足够。默认不写文件，不读取真实金融数据，不连接外部系统。

### Scaffold Mode

在 task package 明确授权的路径内生成项目级薄入口和模板草案。输出应使用 placeholder，不写真实账号、DSN、token、cookie、URL、产品映射、客户映射、raw workbook 路径或邮箱附件名。

### Align Mode

把既有项目文档、task package、data/source contract 和 validation 清单对齐到同一组字段与边界。只做结构和引用收敛，不扩写 provider-specific 手册，不把项目私有规则复制进 skill。

### Enforce Mode

在 bounded execution 中检查本轮操作是否遵守 read-only/write authorization、敏感信息、验证证据、manifest/audit trail 和 out-of-scope 边界。发现未授权 production write、DDL、scheduler change、full refresh、backfill 或外部副作用时必须停止。

## Fixed Safety Rules

- Default to read-only。
- 未经 task package 明确授权，不得进行 production write。
- 未经明确授权，不得进行 DDL、scheduler change、full refresh、backfill 或任何外部副作用。
- 不提交 raw valuation workbooks。
- 不提交 raw mail attachments。
- 不提交 credentials / DSNs / tokens / cookies。
- 不提交 private product registry exports。
- 不提交完整敏感 customer/product mapping tables。
- 生成物默认进入 ignored output 目录，除非 task package 明确授权写入源码树。
- 优先 dry-run 后 write。
- 数据产物应优先保留 manifest / audit trail。
- 报告证据优先使用 counts、schema summary、hash、manifest path、redacted sample、validation summary。
- 示例必须虚构、脱敏或 placeholder 化。
- 不把 AMS_Data、Pricing_sheet、Derivative_Data 或任何业务项目的真实路径、真实字段、真实数据或真实口径写入本 skill。

## Project-fill fields

项目接入时由维护者或 task package 填写，agent 不应自行定稿：

- project name / chain name
- business purpose
- data domain
- dataset names
- source systems
- target systems
- runtime environment
- owner / reviewer / approver
- product universe
- date semantics
- sample data policy
- redaction policy
- output policy
- ignored output directory
- validation baseline
- write authorization policy
- production side-effect policy
- manifest / audit trail policy
- handoff and control-thread policy

## Expected Outputs

本 skill 可产出以下文档草案或检查结果：

- 项目级薄 `AGENTS.md`
- 可选薄 `CLAUDE.md`
- `data_contract`
- `source_contract`
- `validation`
- `task_package`
- `execution_report`
- `handoff/context`
- read-only review notes
- maintainer confirmation checklist

## Human vs agent responsibilities

Human / maintainer 负责：

- 确认业务目的、数据口径、source ownership、target ownership；
- 确认是否允许真实数据读取、production write、DDL、scheduler、full refresh、backfill；
- 确认敏感字段、脱敏策略、样本数据策略和输出归档策略；
- 审核任何会影响生产数据、客户输出、估值/NAV、衍生品计算或审计链路的变更。

Agent 负责：

- 按 task package 读取授权材料；
- 结构化项目事实与待确认项；
- 草拟薄入口、contract、validation、task package、execution report、handoff；
- 优先 dry-run；
- 执行明确授权的验证；
- 输出 execution report，并列明未做事项、风险、假设和下一步。

## Sensitive Information Boundary

开源 skill-hub、模板、examples 和 references 不得包含：

- 真实数据库连接、真实账号、真实 URL、真实 DSN；
- token、cookie、private key、session 信息；
- 真实产品映射、客户映射、估值 workbook 路径、邮箱附件名称；
- raw valuation workbook、raw mail attachment、private product registry export；
- 完整敏感 mapping table 或可还原客户/产品身份的数据样本。

需要证据时，优先使用 count、schema summary、hash、manifest path、redacted sample、validation summary，而不是复制原始数据。

## Recommended Workflow

1. 读取项目 `AGENTS.md`、项目 docs、task package 和本 skill。
2. 复述本轮 scope、allowed changes、forbidden changes、data scope、write authorization、validation plan。
3. 判断使用模式：Review / Scaffold / Align / Enforce。
4. 建立或检查 data contract、source contract、validation 清单。
5. 先 dry-run 或生成草案，再由 maintainer 确认关键事实。
6. 只有 task package 明确授权时才执行写入或外部副作用。
7. 输出 execution report，记录验证结果、敏感信息检查、out-of-scope confirmation 和下一步。

## Stop Conditions

遇到以下情况必须停止并报告：

- task package 未明确授权生产写入、DDL、scheduler change、full refresh、backfill 或外部副作用；
- 需要真实金融数据、raw workbook、raw attachment、credentials 或 DSN 才能继续；
- 发现未脱敏客户/产品映射或 private registry export；
- 当前工作区存在未确认改动，且本轮可能覆盖用户工作；
- 项目事实缺失会影响数据口径、估值/NAV、衍生品、客户输出或审计判断；
- 验证结果与 task package 的 acceptance criteria 冲突；
- requested change 会把薄入口扩写成第二规则库。

## Validation Expectations

按项目风险选择验证深度，至少考虑：

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

如果本轮只生成模板，也应执行 path/scope 检查和 `git diff --check`。

## Relationship To Templates / References / Examples

- `templates/` 是可复制到业务项目后由人补充事实的起点，不包含真实敏感信息。
- `references/` 记录本 skill 吸收的模式和明确不复制的内容。
- `examples/` 只说明非敏感使用方式，不提供真实路径、真实产品名、真实数据库、真实邮箱规则或真实数据样本。
- `chatgpt-handoff-pilot` 继续拥有通用 task package、bounded execution、execution report 协议。
- `workflow-bootstrap` 继续拥有 role chain 与 thin entrypoint 原则。
- `financial-data-project-migration` 负责迁移 readiness 与结构建议；本 skill 负责 bootstrap、contracts、templates 和安全边界。
