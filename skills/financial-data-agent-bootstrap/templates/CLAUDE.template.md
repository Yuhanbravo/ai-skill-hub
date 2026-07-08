# CLAUDE.md

## Purpose

这是 `<project-name>` 的 Claude 侧薄入口。

项目运行入口以 `AGENTS.md` 为准；金融数据 agent bootstrap 的 canonical guidance 以 `skills/financial-data-agent-bootstrap/SKILL.md` 为准。

## Required Reading

实施前必须读取：

1. `AGENTS.md`
2. `<project-docs-path>`
3. `<current-task-package-path>`
4. `skills/financial-data-agent-bootstrap/SKILL.md`

## Boundaries

- 保持本文件 thin。
- 不要在此复制完整项目规则库。
- 不要在此复制 provider-specific manuals。
- 不得写入 credentials、DSNs、tokens、cookies、真实 URL、raw workbooks、raw mail attachments、customer mappings、product mappings 或 private registry exports。
- allowed changes、forbidden changes、data scope、validation 和 execution report requirements 以 task package 为准。

## Workflow

1. 改文件前先复述 task boundary。
2. 未经明确授权，默认 read-only。
3. 优先 dry-run 后 write。
4. 数据事实以 project contracts 和 validation plans 为准。
5. 报告 changed items、not changed items、validation results、sensitive information check 和 recommended next step。
