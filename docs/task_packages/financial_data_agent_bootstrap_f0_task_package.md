# 任务包：financial-data-agent-bootstrap F0

## 1. 任务背景

`ai-skill-hub` 需要新增一套面向金融数据处理/分析项目的 `financial-data-agent-bootstrap` skill。该 skill 面向金融数据工程、运营数据治理、估值/NAV、衍生品、邮箱归档、Oracle 数据服务等项目，帮助项目初始化 agent 规则、项目级薄 `AGENTS.md`、数据契约、数据源契约、验证清单、task package、execution report、handoff/context 模板，以及敏感数据和生产写入边界。

本 F0 task package 只授权实现 docs/templates-only skill 骨架，不授权接入真实业务项目，不授权读取或处理真实金融数据，不授权创建 adapter 或 CLI。

## 2. 任务目标

F0 的目标是新增 canonical skill 初版骨架：

- 建立 `skills/financial-data-agent-bootstrap/`。
- 编写 `SKILL.md`，说明何时使用、适用项目类型、固定安全规则、项目可变字段、输出文档类型、人与 agent 分工、敏感信息边界和四种使用模式。
- 新增 templates、references、examples 的最小文档集合。
- 保持 `SKILL.md` 为 canonical source，templates 为可复制起点，references 为模式说明，examples 只放非敏感说明。
- 不修改运行逻辑，不创建 adapter，不更新 sync / adapter 工具。

## 3. 推荐分支名

推荐分支名：

```text
feat/financial-data-agent-bootstrap-f0
```

## 4. 允许修改的文件范围

F0 仅允许新增或修改：

```text
skills/financial-data-agent-bootstrap/**
```

如仓库维护者要求同步索引，可在单独 F1 task package 中处理；F0 默认不更新 `.agents/skills/`、`.github/skills/`、`skills_index.json`、`SKILLS_INDEX.md` 或工具脚本。

## 5. 禁止修改的内容

F0 明确禁止：

- 修改 AMS_Data、Pricing_sheet、Derivative_Data 或任何业务项目。
- 生成真实业务项目的 `AGENTS.md`。
- 读取、复制、摘要真实金融数据。
- 写入真实数据库、邮箱、Excel、Wind、Oracle。
- 包含真实数据库连接、真实账号、真实 URL、真实产品映射、真实估值表路径。
- 实现 initializer CLI。
- 修改 sync / adapter 工具。
- 创建 `.agents/skills/financial-data-agent-bootstrap*` 或 `.github/skills/financial-data-agent-bootstrap.md`。
- 修改 `skills_index.json`、`SKILLS_INDEX.md` 或索引生成逻辑。
- push、merge、rewrite history。

## 6. 预期新增目录结构

F0 预期新增：

```text
skills/financial-data-agent-bootstrap/
  SKILL.md
  templates/
    AGENTS.template.md
    CLAUDE.template.md
    data_contract.template.md
    source_contract.template.md
    validation.template.md
    task_package.template.md
    execution_report.template.md
    handoff.template.md
  references/
    pattern_notes.md
  examples/
    README.md
```

## 7. 各文件内容要求

### `SKILL.md`

必须包含：

- 何时使用：金融数据项目需要 agent bootstrap、规则初始化、数据契约、source contract、validation、handoff/task package/execution report 模板时。
- 适用项目类型：
  - `desktop automation script`
  - `valuation workbook parser`
  - `Wind data extraction pipeline`
  - `Oracle-backed data service`
  - `mail raw archive pipeline`
  - `analysis/reporting service`
  - `agent skill hub / workflow governance project`
  - 其他金融数据处理/分析脚本
- 固定安全规则。
- 项目可变字段：项目名、数据域、数据源、环境、owner、样本数据策略、output policy、validation baseline、write authorization policy。
- 输出文档类型：薄 `AGENTS.md`、可选 `CLAUDE.md`、`data_contract`、`source_contract`、`validation`、`task_package`、`execution_report`、`handoff/context`。
- 人与 agent 分工：人确认关键事实、授权写入、确认敏感边界；agent 负责结构化、草拟、dry-run、验证和 execution report。
- 敏感信息边界：开源 skill-hub 不写真实账号、DSN、token、cookie、URL、产品映射、客户映射、raw workbook、raw attachment。
- 使用模式：`Review Mode`、`Scaffold Mode`、`Align Mode`、`Enforce Mode`。

### `templates/AGENTS.template.md`

应是项目级薄入口模板，只回指项目 docs、task package 和 canonical skill，不复制 provider-specific 手册。

### `templates/CLAUDE.template.md`

应是可选兼容入口，保持薄层，回指 `AGENTS.md` 和 canonical skill。

### `templates/data_contract.template.md`

应覆盖 dataset identity、schema、primary key、date field、product universe、units、null policy、sensitive fields、output artifact、owner confirmation。

### `templates/source_contract.template.md`

应覆盖 source identity、identifier、timestamp、timezone、pagination、units、freshness、known provider pitfalls、retry/failure policy、source-target reconciliation、credential boundary。

### `templates/validation.template.md`

应覆盖金融数据验证清单，包括 row count、primary key uniqueness、date min/max、product universe coverage、required field null check、illegal value check、source-target reconciliation、idempotency、dry-run vs real-run delta、manifest completeness、sensitive output check、focused tests、`git diff --check`。

### `templates/task_package.template.md`

应在通用 task package 基础上增加 financial-data boundary 字段：read-only/write authorization、data source scope、production side effects、sample/redaction policy、manifest/audit trail、validation plan。

### `templates/execution_report.template.md`

应要求报告实际改动、未做事项、validation results、counts/schema/hash/manifest/redacted sample 等证据、敏感信息检查、生产写入确认、风险和下一步。

### `templates/handoff.template.md`

应覆盖当前状态、数据边界、环境边界、关键事实确认状态、open questions、下一轮推荐 task package。

### `references/pattern_notes.md`

应说明参考模式如何被吸收但不照搬：`AGENTS.md` 官方模式、Codex 分层规则、金融数据分析 workflow、行情/API rules、SDK 工程分层、Agent Skills 模式、AMS_Data / Pricing_sheet / Derivative_Data 实践。

### `examples/README.md`

只放非敏感示例说明，可列虚构项目类型和使用模式，不放真实路径、真实 URL、真实表名、真实产品映射或 raw data。

## 8. F0 skill 将来必须包含的固定安全规则

F0 实施时必须把以下规则写入 canonical skill 或对应模板：

- default to read-only。
- 未经 task package 明确授权，不得进行 production write。
- 未经明确授权，不得进行 DDL、scheduler change、full refresh、backfill、外部副作用。
- 不提交 raw valuation workbooks。
- 不提交 raw mail attachments。
- 不提交 credentials / DSNs / tokens / cookies。
- 不提交 private product registry exports。
- 不提交完整敏感 customer/product mapping tables。
- 生成物默认进入 ignored output 目录。
- 优先 dry-run 后 write。
- 需要 manifest / audit trail 的数据产物应保留可复核证据。
- 报告证据优先使用 counts、schema summary、hash、manifest path、redacted sample、validation summary。

## 9. Implementation plan

1. 读取 `AGENTS.md`、`skills/workflow-bootstrap/SKILL.md`、`skills/chatgpt-handoff-pilot/SKILL.md` 和本 task package。
2. 检查当前 `skills/`、`.agents/skills/`、`.github/skills/`、`tools/` 与既有 skill 风格。
3. 确认 `skills/financial-data-agent-bootstrap/` 不存在；若已存在，停止并报告冲突。
4. 创建 F0 目录结构。
5. 编写 `SKILL.md`，保持 canonical、执行导向、中文为主、保留必要英文术语。
6. 编写 templates，保持可复制但不含真实敏感信息。
7. 编写 `references/pattern_notes.md`，说明模式吸收与边界。
8. 编写 `examples/README.md`，只使用虚构、脱敏、非业务事实。
9. 运行 validation plan 中的检查。
10. 输出 execution report，明确改了什么、没改什么、验证结果和下一步。

## 10. Validation plan

至少运行：

```bash
git status --short --untracked-files=all
git diff --check
```

如仓库有最小相关检查，可再运行：

```bash
python tools/check_adapter_consistency.py
```

但 F0 默认不创建 adapter；若 adapter consistency 因新增 canonical skill 缺少 adapter 而失败，应记录为预期 F1 事项，而不是在 F0 越界补 adapter。

## 11. Sensitive data / security constraints

F0 输出必须满足：

- 不包含真实数据库连接、真实账号、真实 URL、真实路径、真实产品映射、真实客户映射、真实估值 workbook 路径、真实邮箱附件名称。
- 不包含 raw valuation workbooks、raw mail attachments、private product registry exports 或完整敏感 mapping table。
- 所有示例必须虚构、脱敏或以 placeholder 表达。
- 若需要描述 AMS_Data、Pricing_sheet、Derivative_Data，只能作为未来试点方向，不写真实数据、真实路径、真实字段或真实业务口径。
- 所有写入行为必须限定在 F0 授权文件范围内。

## 12. Acceptance criteria

F0 验收标准：

- `skills/financial-data-agent-bootstrap/` 按预期结构创建。
- `SKILL.md` 明确 canonical source、适用场景、安全规则、项目可变字段、输出文档类型、人与 agent 分工、四种使用模式。
- 所有 templates 存在且字段可执行、可复核、不过度绑定单一项目。
- `source_contract` 与 `data_contract` 明确 identifier、timestamp、pagination、单位、schema、primary key、敏感字段边界。
- `validation.template.md` 包含完整金融数据验证清单。
- `task_package.template.md` 和 `execution_report.template.md` 支持 read-only/write boundary、manifest/audit trail、validation evidence。
- 未创建 adapter、未更新索引、未实现 CLI、未接入真实项目。
- `git diff --check` 通过。
- execution report 确认不含真实敏感信息。

## 13. Recommended commit message

```text
docs: add financial data agent bootstrap F0 package
```

若 F0 实施创建 skill 骨架，可使用：

```text
feat: add financial data agent bootstrap skill skeleton
```

## 14. Open questions

当前无阻塞问题。以下问题不阻塞 F0，建议留到 F1/F2：

- F1 是否立即创建 `.agents/skills/` 与 `.github/skills/` adapter。
- 新 skill 是否需要进入 `skills_index.json` 的自动生成流程。
- F2 是否需要 initializer CLI，还是长期保持 templates-only。
- F3 首个试点项目应选择 AMS_Data、Derivative_Data、Pricing_sheet，还是一个完全脱敏的 synthetic sample。
