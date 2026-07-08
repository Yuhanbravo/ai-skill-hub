# financial-data-agent-bootstrap

## Purpose

`financial-data-agent-bootstrap` 是面向金融数据工程与运营类项目的 agent bootstrap skill，用于帮助项目建立薄入口、契约模板、验证边界、任务包、执行回执和 handoff/context 起点。

本 README 只是人和 agent 的快速入口，不是 canonical workflow knowledge。具体工作流、模式、边界和停手条件以 `SKILL.md` 为准。

## When to use

当项目需要为金融数据相关 agent 协作建立以下基础材料时使用：

- 项目级薄入口草案；
- data contract / source contract / validation 草案；
- task package / execution report / handoff 草案；
- read-only、dry-run、生产写入、外部副作用等安全边界说明。

本 skill 适合 bootstrap、review、align 和 enforce 类协作，不用于投资建议、交易策略、alpha research 或 provider-specific API 手册。

## Canonical files

- `SKILL.md`：canonical workflow knowledge，包含完整用途、模式、边界、停手条件和验证期望。
- `references/`：记录设计来源、模式说明和明确不应复制到 skill 中的内容边界。
- `examples/`：提供非敏感、placeholder 化的使用示例。

如 README 与 `SKILL.md` 冲突，以 `SKILL.md` 为准。

## Templates

`templates/` 提供可复制到业务项目后由维护者补充事实的起点，包括：

- `AGENTS.template.md`
- `CLAUDE.template.md`
- `data_contract.template.md`
- `source_contract.template.md`
- `validation.template.md`
- `task_package.template.md`
- `execution_report.template.md`
- `handoff.template.md`

这些模板应保持薄、通用、placeholder-first，不包含真实业务项目事实。

## Safety boundary

本 skill、README、templates、references 和 examples 不应包含真实路径、真实账号、真实 URL、真实产品映射、真实数据库信息、凭据、token、cookie、客户映射、原始 workbook、原始邮件附件或可还原敏感业务事实的数据样本。

需要证据时，应优先使用 count、schema summary、hash、manifest path、redacted sample 或 validation summary 等脱敏材料。

## Adapter and index relationship

F0.1 只补齐 skill structure 所需的 README 入口文件，不创建 adapter，不更新 index，不接入 CLI，也不改变 discoverability 或发布面。

未来如需 adapter 或 index 集成，应在单独任务中明确授权，并继续回指 `SKILL.md`，避免把 adapter、index 或 README 扩写成第二规则库。

## Next phase

下一阶段可在独立范围内评估 F1 Adapter + Index Review。该工作不属于 F0.1，本轮不提前实现 adapter、index、CLI、真实业务项目接入或模板变更。
