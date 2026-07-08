# financial-data-agent-bootstrap Roadmap v0

## 1. 背景与目标

`financial-data-agent-bootstrap` 规划为一套面向金融数据处理/分析项目的 agent bootstrap skill。它的目标不是提供投资建议、交易策略、alpha research 或量化策略开发能力，而是帮助金融数据工程、运营数据治理、估值/NAV、衍生品、邮箱归档、Oracle 数据服务等项目，以可复核、低副作用的方式初始化 agent 协作规则与执行边界。

本 roadmap 只定义方向、分期和边界，不实施 skill，不创建 `skills/financial-data-agent-bootstrap/`，不修改现有运行逻辑。

## 2. 为什么要做这个 skill

金融数据项目常见问题不是“缺少一个更聪明的 agent”，而是缺少可共享的执行边界：

- 根 `AGENTS.md` 容易膨胀为项目规则大全，导致维护困难。
- 项目事实、数据契约、数据源坑点、验证清单和本轮授权经常混在一起。
- agent 容易把 read-only 分析误解为可写生产执行。
- 不同项目的 Wind、Oracle、Excel workbook、mail archive、NAV、衍生品数据边界容易被混淆。
- execution report 中缺少 counts、schema summary、manifest、hash、redacted sample 等可复核证据。

该 skill 预期提供一套可复用的 bootstrap 方法，使项目侧保持薄入口，具体事实进入项目 docs，本轮授权进入 task package，执行回执进入 execution report。

## 3. 它解决什么问题

该 skill 预期解决：

1. agent 规则初始化：帮助项目生成轻量、reference-first 的 `AGENTS.md` 草案。
2. 数据契约：定义 dataset、schema、primary key、date coverage、product universe、output artifact 的最小字段。
3. 数据源契约：把 identifier、timestamp、pagination、单位、接口坑点、fallback、rate limit、source freshness 等写入 `source_contract`，而不是塞进根入口。
4. 验证清单：把 row count、primary key uniqueness、date min/max、source-target reconciliation、manifest completeness 等变成执行前后可复核检查。
5. 任务交接：提供金融数据项目适用的 `task package`、`execution report`、`handoff/context` 模板。
6. 安全边界：默认 read-only，未经 task package 明确授权不做 production write、DDL、scheduler change、full refresh、backfill 或外部副作用。
7. 多 agent 协作：支持多 agent / 多旁路 / 总控回灌的上下文管理，强调人审关键事实、AI 在边界内结构化和执行。

## 4. 它不解决什么问题

该 skill 不应解决：

- 投资建议、交易策略、alpha research 或量化策略开发。
- provider-specific API 手册的完整搬运。
- 真实金融数据抽取、复制、摘要或发布。
- 生产数据库、邮箱、Excel、Wind、Oracle 的真实写入或下载。
- 单一项目的全部业务规则固化。
- 自动替代业务 owner、数据 owner、合规 reviewer 的事实确认。
- initializer CLI、adapter sync、manifest registry 等工具实现；这些最多在后续阶段单独规划。

## 5. 与现有 `ai-skill-hub` 架构的关系

本 skill 应沿用现有 hub 的分层原则：

- `skills/<skill>/SKILL.md` 是 canonical workflow knowledge。
- `.agents/skills/` 与 `.github/skills/` 只作为 adapter / compatibility entry，不复制 canonical 内容。
- `templates/` 放可复用模板；`references/` 放模式说明；`examples/` 放非敏感示例。
- `chatgpt-handoff-pilot` 继续拥有 task package、bounded execution、execution report 的通用协议；本 skill 只提供金融数据项目的模板字段和安全约束扩展。
- `workflow-bootstrap` 继续拥有 role chain 与薄入口原则；本 skill 只把这些原则转译到金融数据项目。
- `financial-data-project-migration` 关注迁移 readiness、耦合分类和保守结构建议；本 skill 关注 agent bootstrap、项目规则初始化和金融数据执行边界。

## 6. Canonical source 与 adapter 边界

推荐边界：

- Canonical source：`skills/financial-data-agent-bootstrap/SKILL.md`。
- Canonical templates：`skills/financial-data-agent-bootstrap/templates/`。
- Canonical references：`skills/financial-data-agent-bootstrap/references/`。
- Adapter：`.agents/skills/financial-data-agent-bootstrap.md`、`.agents/skills/financial-data-agent-bootstrap/SKILL.md`、`.github/skills/financial-data-agent-bootstrap.md`。

Adapter 必须保持薄层，只说明 name、description、canonical path、suggested use，不得复制固定安全规则、模板全文、数据契约细节或 provider-specific 指南。

## 7. 适用项目类型

该 skill 将来应支持以下类型：

- `desktop automation script`
- `valuation workbook parser`
- `Wind data extraction pipeline`
- `Oracle-backed data service`
- `mail raw archive pipeline`
- `analysis/reporting service`
- `agent skill hub / workflow governance project`
- 其他金融数据处理/分析脚本

## 8. 推荐分期

### F0：docs/templates-only skill

目标：规划并实施一个只包含 `SKILL.md`、templates、references、examples 的 canonical skill 骨架。

交付物：

- `skills/financial-data-agent-bootstrap/SKILL.md`
- `templates/AGENTS.template.md`
- `templates/CLAUDE.template.md`
- `templates/data_contract.template.md`
- `templates/source_contract.template.md`
- `templates/validation.template.md`
- `templates/task_package.template.md`
- `templates/execution_report.template.md`
- `templates/handoff.template.md`
- `references/pattern_notes.md`
- `examples/README.md`

Out-of-scope：不创建 adapter，不更新 index，不实现 CLI，不接入真实项目，不放入真实敏感信息。

### F1：adapter/index review

目标：在 F0 通过审阅后，补齐 discoverability 与 adapter surface。

交付物：

- `.agents/skills/financial-data-agent-bootstrap.md`
- `.agents/skills/financial-data-agent-bootstrap/SKILL.md`
- `.github/skills/financial-data-agent-bootstrap.md`
- 必要时更新 `skills_index.json`、`SKILLS_INDEX.md` 或现有索引文件
- adapter consistency / inventory 检查结果

Out-of-scope：不改变 F0 canonical 模板语义，不加入项目私有事实，不实现 CLI。

### F2：可选 dry-run initializer CLI

目标：评估是否需要一个只生成本地草案的 dry-run initializer CLI。

交付物候选：

- CLI 设计备忘录
- dry-run 输出目录约定
- overwrite policy
- ignored output 策略
- 最小测试与 `--dry-run` 验证

Out-of-scope：默认不写入生产项目根目录，不自动覆盖既有 `AGENTS.md` / `CLAUDE.md`，不读取真实金融数据，不连接真实外部系统。

### F3：项目接入试点

目标：选择非敏感或脱敏项目做 Review Mode / Scaffold Mode / Align Mode / Enforce Mode 试点，例如 AMS_Data、Derivative_Data、Pricing_sheet。

交付物候选：

- 项目级 task package
- read-only review report
- 脱敏 sample contract
- execution report
- 需要人工确认的事实清单

Out-of-scope：本 roadmap 不授权修改上述业务项目，不授权读取、复制或摘要真实业务数据，不授权生产写入。

## 9. 风险与缓解

| 风险 | 表现 | 缓解原则 |
| --- | --- | --- |
| 文档过厚 | 根 `AGENTS.md` 或 `SKILL.md` 变成规则大全 | 根入口保持薄；项目事实放项目 docs；模板只保留最小字段 |
| 规则重复 | skill、adapter、项目 docs 互相复制 | canonical source 在 `skills/`；adapter 只回指；task package 只授权本轮 |
| 真实敏感信息泄露 | workbook、mail attachment、credentials、DSN、产品映射进入仓库 | 开源 skill-hub 只放脱敏模板与模式；真实事实留在私有项目并 redacted |
| agent 误写生产环境 | read-only 任务触发 DDL、scheduler、full refresh、backfill | default to read-only；生产写入必须由 task package 明确授权 |
| 不同项目边界混淆 | AMS_Data / Pricing_sheet / Derivative_Data 规则互相污染 | 项目事实只写项目 docs；skill 只写可复用方法 |
| provider-specific 规则膨胀 | Wind/Oracle/API 手册被塞进根入口 | 细节进入 `source_contract` 或项目私有 references |

## 10. 推荐原则

- 根 `AGENTS.md` 应薄。
- 项目事实放项目 docs。
- 可复用方法放 skill。
- 本轮授权放 task package。
- 执行结果放 execution report。
- 敏感事实不进入开源 skill-hub。
- 默认 read-only；先 dry-run 后 write。
- 证据优先使用 counts、schema summary、hash、manifest path、redacted sample、validation summary。

## 11. 推荐下一步

下一步应按 F0 task package 实施 canonical skill 骨架，但仍不得接入真实项目、不得创建 adapter、不得实现 CLI。F0 完成并通过审阅后，再进入 F1 adapter/index review。
