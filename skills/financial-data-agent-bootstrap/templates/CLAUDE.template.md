# CLAUDE.md

## Purpose

这是 `<project-name>` 的 Claude 侧薄入口。

项目运行入口以 `AGENTS.md` 为准。本模板面向默认 `AI_LEVEL_CONFIG_BACK_REFERENCE` 模式：金融数据 agent bootstrap 使用逻辑 Skill ID `financial-data-agent-bootstrap`，经用户级 router、neutral locator 和 Hub resolver 定位 canonical guidance。

已有且未迁移的 Project Runtime Pack 项目继续使用其项目 manifest、项目 router、commit pinning 与 pinned/portable 校验；不要用本模板覆盖这些入口。模式切换必须由独立迁移任务授权并留证，两种模式不得互相自动 fallback。

## Required Reading

实施前必须读取：

1. `AGENTS.md`
2. `<project-docs-path>`
3. `<current-task-package-path>`
4. Resolver 返回的 `financial-data-agent-bootstrap` canonical `SKILL.md` 及本次执行所需 supporting resources

## Boundaries

- 保持本文件 thin。
- 不要在此复制完整项目规则库。
- 不要在此复制 provider-specific manuals。
- 不要假设消费者 checkout 内存在 Hub 的 `skills/` 路径，不要写入机器 Hub 绝对路径或复制 canonical Skill payload。
- 不得写入 credentials、DSNs、tokens、cookies、真实 URL、raw workbooks、raw mail attachments、customer mappings、product mappings 或 private registry exports。
- allowed changes、forbidden changes、data scope、validation 和 execution report requirements 以 task package 为准。

## Workflow

1. 改文件前先复述 task boundary。
2. 未经明确授权，默认 read-only。
3. 优先 dry-run 后 write。
4. 数据事实以 project contracts 和 validation plans 为准。
5. 报告 changed items、not changed items、validation results、sensitive information check 和 recommended next step。
