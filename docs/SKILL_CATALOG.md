# Skill Catalog

## Status / Source Notice
- 本文档是 **index**，用于集中发现与路由，不是 canonical skill 内容承载面。
- Canonical content 仅位于 `skills/<skill>/`。
- 本文档不得复制完整 `SKILL.md` 正文；仅保留 “when to use” 级别摘要。

## How to use this catalog
1. 先根据 `intended use case` 与 `side-effect level` 初筛。
2. 再看 `related skills` 避免误用相邻能力。
3. 最后跳转到 `skill path` 下的 `SKILL.md` 阅读 canonical 规则后执行。

## Source-surface boundary reminder
- `skills/`：唯一 canonical source。
- `.agents/skills/`、`.github/skills/`：adapter / fallback discovery only。
- `docs/bridge/`：bridge mirror / reference only。
- `tasks/`：historical execution evidence，不自动晋升 canonical。
- `docs/HANDOFF.md`、`docs/status/`：state snapshots，不是模板入口。

## Skill Index

| skill path | short purpose | owner / category | canonical status | intended use case | related skills | side-effect level |
|---|---|---|---|---|---|---|
| `skills/chatgpt-handoff-pilot/` | 标准化 task package / bounded execution / execution report 交接壳层 | governance / handoff protocol | canonical | 需要跨角色交接并要求边界明确与可回执时 | `skills/workflow-bootstrap/`, `skills/update-project-status/`, `skills/system-handoff/` | documentation-only |
| `skills/codex-project-workflow/` | 为单个仓库任务提供 Task Card、明确边界、preflight、验证与简洁回执 | workflow / bounded repository execution | canonical | 需要在项目本地规则下执行边界明确的实现、审阅或收尾任务时 | `skills/chatgpt-handoff-pilot/`, `skills/workflow-bootstrap/` | code / configuration / documentation |
| `skills/documentation-governance/` | 文档治理审计与重复/边界诊断 | governance / documentation | canonical | 需要文档结构治理、重复检测、SSOT 边界检查时 | `skills/skill-governance/`, `skills/file-structure-check/` | documentation-only |
| `skills/file-structure-check/` | 目录结构一致性检查与缺失/错放识别 | governance / structure audit | canonical | 需要快速识别目录偏移、漏文件、错层级放置时 | `skills/documentation-governance/`, `skills/project-takeover/` | read-only |
| `skills/financial-data-agent-bootstrap/` | 为金融数据工程或运营项目建立 agent 规则、契约、验证与交接边界 | domain bootstrap | canonical | 需要为 financial-data 项目建立受控的 agent 协作与数据安全基础时 | `skills/financial-data-project-migration/`, `skills/chatgpt-handoff-pilot/` | documentation-only |
| `skills/financial-data-project-migration/` | 金融数据项目迁移评估与保守迁移建议 | domain migration | canonical | 面向 financial-data 项目的迁移评估与落地边界规划 | `skills/project-takeover/`, `skills/system-takeover/` | documentation-only |
| `skills/project-takeover/` | 单项目接管、现状盘点与 onboarding 输出 | takeover / project scope | canonical | 接手一个具体仓库并输出可执行接管包时 | `skills/system-takeover/`, `skills/workflow-bootstrap/` | documentation-only |
| `skills/skill-governance/` | 单个 skill 的评分、诊断、受控重构建议 | governance / skill quality | canonical | 需要评估某个 skill 质量并给出治理动作时 | `skills/documentation-governance/`, `skills/update-project-status/` | documentation-only |
| `skills/system-handoff/` | system 级 handoff 文档更新与 section-aware merge | governance / handoff maintenance | canonical | 需要更新 system handoff 且保持章节增量合并时 | `skills/chatgpt-handoff-pilot/`, `skills/system-status-update/` | status / handoff update |
| `skills/system-status-update/` | system 状态文档更新与层级化状态输出 | governance / status | canonical | 需要刷新系统状态快照与阶段结论时 | `skills/update-project-status/`, `skills/system-handoff/` | status / handoff update |
| `skills/system-takeover/` | 跨能力域系统接管与全局治理评估 | takeover / system scope | canonical | 需要跨多个 capability hub 做系统级接管分析时 | `skills/project-takeover/`, `skills/workflow-bootstrap/` | documentation-only |
| `skills/update-project-status/` | 基于 Git/执行证据的项目状态刷新与周报归纳 | governance / status operations | canonical | 需要周期性更新项目状态、周报、handoff-ready 摘要时 | `skills/system-status-update/`, `skills/chatgpt-handoff-pilot/` | status / handoff update |
| `skills/workflow-bootstrap/` | 定义默认 role chain、薄入口与 runtime pack 映射壳层 | workflow / orchestration | canonical | 需要先搭建协作工作流框架、或在具体实施前选择要运行的 role chain segment 时 | `skills/chatgpt-handoff-pilot/`, `skills/project-takeover/`, `skills/system-takeover/` | documentation-only |

## Boundary Notes for Similar Skills
- `project-takeover` vs `system-takeover`：前者聚焦单一 repo/project 的接管与落地；后者聚焦跨能力域、跨子系统的系统级接管，分析半径更大。
- `workflow-bootstrap` 与 handoff/status skills：`workflow-bootstrap` 定义默认协作壳层与角色链路；具体 task package / execution report 交接协议由 `chatgpt-handoff-pilot` 负责；状态刷新由 `update-project-status` / `system-status-update` 承担。
- `documentation-governance` / `skill-governance` / `update-project-status`：文档治理关注文档结构与边界；skill 治理关注单 skill 质量与演化；status 更新关注阶段事实与执行证据快照。
