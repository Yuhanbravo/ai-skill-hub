# financial-data-agent-bootstrap Examples

这些 examples 只提供非敏感使用说明。它们不包含真实路径、真实产品名、真实数据库、真实邮箱规则、credentials、raw workbooks、raw attachments、private mappings 或 raw data samples。

## Desktop Automation Script

使用 Review Mode 检查 task package 和 project docs，然后为本地脚本草拟薄 `AGENTS.md` 与 validation checklist。除非 task package 明确授权，production write 保持禁用。

## Valuation Workbook Parser

使用 Scaffold Mode 创建 `data_contract`、`source_contract` 和 `validation` 草案。证据使用 workbook metadata、schema summary、row counts、hashes 和 redacted samples，不使用 raw workbook content。

## Wind Data Extraction Pipeline

使用 Align Mode 记录 identifier rules、trading calendar assumptions、date parameters、batching、freshness checks 和 retry/failure evidence。不要写入 credentials 或 provider-specific manuals。

## Oracle-Backed Data Service

实施中使用 Enforce Mode 确认 read-only status、SQL boundary、source-target reconciliation、manifest/audit trail，并确认没有未授权 DDL、scheduler change、full refresh、backfill 或 production write。

## Mail Raw Archive Pipeline

使用 Scaffold Mode 定义 archive identity placeholders、message selection rules、attachment handling、deduplication、timestamp semantics 和 evidence policy。不得提交 raw mail attachments 或 private mail content。

## Analysis / Reporting Service

使用 Review Mode 检查 report outputs 是否具备 validation evidence、manifest completeness、sensitive output review 和清晰 handoff notes。除非明确授权，生成物放入 ignored output directories。

## Agent Skill Hub / Workflow Governance Project

使用本 skill 为另一个金融数据项目 bootstrap templates，同时保持 canonical skill guidance 与 project-local facts 分离。除非后续 task package 授权，不创建 adapters、indexes 或 initializer CLI。
