# Pattern Notes

本文记录 `financial-data-agent-bootstrap` 吸收的可复用模式。它不复制外部项目内容、provider manuals、私有项目事实、credentials、raw data 或业务规则。

## AGENTS.md Official Pattern

- Useful pattern：根入口应提供操作指引、required reading、scope boundaries 和 conflict resolution。
- How this skill adapts it：项目 `AGENTS.md` 保持 thin，回指 project docs、task packages、contracts、validation 和 canonical skill。
- What is intentionally not copied：完整 provider manuals、项目专属业务规则、真实路径、真实账号、真实产品名或 raw data examples。

## Codex AGENTS.md Hierarchy Pattern

- Useful pattern：实施前应读取 nested instructions 与 task-local guidance，距离任务更近的指引优先。
- How this skill adapts it：金融数据项目根入口保持 thin，dataset/source/runtime facts 进入 project docs 和 task packages。
- What is intentionally not copied：skill 内不建立第二套本地规则层级，也不覆盖维护者确认的 task boundaries。

## xalpha-like Financial Data Analysis Pattern

- Useful pattern：金融数据分析 workflow 需要清晰的 product identity、date semantics、units、validation 和 reproducible evidence。
- How this skill adapts it：data contract 要求 product universe、primary key、date semantics、units、null policy、duplicate handling 和 reconciliation。
- What is intentionally not copied：investment advice、strategy logic、alpha research、live market data、provider-specific implementation details 或真实金融输出。

## Massive-like Financial API Rules Pattern

- Useful pattern：API-driven pipelines 需要 identifier rules、batching、rate limits、pagination、freshness、retry 和 failure evidence。
- How this skill adapts it：source contract 为 Web/API、Wind、Oracle、Excel、mail archive 和 local file 提供这些约束的 placeholder。
- What is intentionally not copied：真实 API keys、endpoint URLs、account details、proprietary schemas 或 provider-specific manuals。

## Luno-like Engineering / SDK Pattern

- Useful pattern：SDK-style projects 会把 client boundaries、credentials、error handling、versioning、tests 与 business logic 分开。
- How this skill adapts it：本 skill 要求项目把 source identity、credential boundary、retry/failure evidence、validation 与 task execution 分开表达。
- What is intentionally not copied：具体 SDK code、production client configuration、account IDs 或 network behavior assumptions。

## Agent Skills Pattern

- Useful pattern：skill 应说明 when to use、outputs、refusal boundary，以及 templates/references 与 canonical guidance 的关系。
- How this skill adapts it：`SKILL.md` 是 canonical source；templates 是可复制起点；references 解释模式；examples 保持非敏感。
- What is intentionally not copied：adapters、indexes、CLI initializers、generated project files 或 F0 scope 外的 discoverability surface。

## User Project Practice Pattern: AMS_Data

- Useful pattern：运营数据项目通常需要严格 source ownership、validation evidence，以及 control / side-track 之间的 handoff。
- How this skill adapts it：task package 和 execution report 要求 allowed changes、forbidden changes、data evidence、sensitive checks 和 next-step handoff。
- What is intentionally not copied：真实路径、表、credentials、customer/product mappings、workbook names、business logic 或 data samples。

## User Project Practice Pattern: Pricing_sheet

- Useful pattern：估值 workbook 和 pricing workflows 需要 workbook boundaries、schema summaries、redacted evidence，以及明确 no-raw-workbook 规则。
- How this skill adapts it：data/source contracts 和 validation templates 要求 workbook identity placeholders、unit conventions、date semantics 和 sensitive output checks。
- What is intentionally not copied：raw valuation workbooks、formulas、真实文件 sheet names、product registries 或 valuation outputs。

## User Project Practice Pattern: Derivative_Data

- Useful pattern：衍生品数据 workflow 需要 date semantics、product universe clarity、reconciliation 和谨慎的 write authorization。
- How this skill adapts it：templates 要求 primary key、date min/max、product coverage、source-target reconciliation、idempotency 和 production side-effect confirmation。
- What is intentionally not copied：真实 derivative product definitions、真实 positions、pricing models、counterparties、mapping tables 或 database details。

## Multi-Agent / Side-Track / Control-Thread Handoff Workflow

- Useful pattern：复杂项目适合使用 control thread、side tracks、frozen items、safe resume points 和 compact paste-back context。
- How this skill adapts it：`handoff.template.md` 支持 control、side-track、freeze 和 resume 状态，并记录 current boundary、safe resume point、known constraints 和 next action。
- What is intentionally not copied：private thread content、真实 project secrets、live operational state，或没有 task package 的开放式继续授权。
