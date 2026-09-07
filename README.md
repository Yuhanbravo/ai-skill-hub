# ai-skill-hub

这是当前机器上的本地 `ai-skill-hub` 仓库，也是一个面向多代理协作的 skill platform，用来集中维护、测试和分发各类 AI skills。

它可以理解为 AI Capability OS 的 skill layer：以 `skills/` 作为 canonical source，通过 adapter、index、tools 和 automation 为不同 AI 入口提供统一的技能发现与分发能力。

## Documentation Entry Points

For skill selection and source-surface boundaries, see `docs/SKILL_CATALOG.md`.
For reusable templates, snippets, prompts, examples, and historical candidates, see `docs/TEMPLATE_REGISTRY.md`.

## Legacy Alias

- canonical name: `ai-skill-hub`
- legacy name: `codex-skill-hub`
- 消费者侧目录如 `.codex/`、`.codex/skills/`、`.codex/skill-config/` 继续作为兼容入口保留，不因本次仓库内部重命名而强制调整。

## 当前包含的 Skills

- `chatgpt-handoff-pilot`
- `documentation-governance`
- `file-structure-check`
- `financial-data-project-migration`
- `project-takeover`
- `skill-governance`
- `system-handoff`
- `system-status-update`
- `system-takeover`
- `update-project-status`
- `workflow-bootstrap`

## 仓库结构（Repository Layout）

- `skills/`：各个 skill 的源码（source）
- `.agents/skills/`：通用 AI 入口层（thin adapter layer）
- `.github/skills/`：GitHub Copilot 兼容入口层（fallback adapter layer）
- `tests/`：仓库级测试区域（repository-level test area）
- `examples/`：仓库级示例（repository-level examples）
- `tools/`：辅助脚本（utility scripts），用于同步、导出等操作
- `SKILLS_INDEX.md`：跨 AI 通用 skill 索引
- `AI_USAGE.md`：跨 AI 使用说明

这个仓库最初是从业务项目中的 `.codex/skills` 同步副本重建出来的。这个背景仅用于解释历史来源；当前默认主名与平台定位均以 `ai-skill-hub` 为准，目标是在不直接改动业务项目的前提下，统一管理 skill 的演进。

## AI 兼容入口（Cross-AI Adapter Layer）

本仓库将 `skills/` 保持为唯一事实源，不在其他入口层复制完整 skill 内容。

- `skills/<skill>/`：canonical source，包含真实 `SKILL.md`、脚本、测试、参考资料
- `.agents/skills/<skill>/SKILL.md`：面向通用 AI 与 legacy adapter discovery 的薄入口
- `.github/skills/<skill>.md`：面向 Copilot 的兼容入口

当前仓库未使用 symlink，而是采用“adapter + index”策略：

- 通过相对路径把入口文件指向 canonical skill
- 通过 `SKILLS_INDEX.md` 提供统一索引
- 通过 `AI_USAGE.md` 说明发现与解析方式

如果某个 AI 只能看到入口层，应继续读取入口文件中给出的 canonical path，再回到 `skills/` 目录读取完整 skill 定义。

## Adapter Governance Modes

`tools/check_adapter_consistency.py` 现在显式区分两种检查口径：

- `--mode consumer`：用于普通消费项目，检查 `.codex/skills -> .agents/.github` contract
- `--mode hub`：用于当前 hub 仓库，检查 `skills/ -> .agents/.github` contract

这两个 mode 都保持 read-only，只报告 missing / orphan / wrong reference，不会自动修复或删除任何 adapter。

## Local Validation

`tools/run_local_checks.ps1` 现在是仓库默认的本地验证入口，适合在日常维护前后和提交前运行。

- `router`：只检查 routing 相关验证
- `governance`：检查 adapter / governance 相关验证
- `smoke`：运行默认本地 smoke checks
- `all`：运行更完整的本地验证集合

建议调用示例：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks router
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks governance
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks all
```

这个入口通过 `repo-python` 将 Python workload 交给 AI_Workbench 的 runtime broker；仓库本身不选择解释器，也不在 broker 失败后回退到 `python`、`py` 或 Conda。`-CondaEnvName` 与 `-UsePyLauncher` 仅暂时保留为显式报错的旧参数。该入口仍然只是本地维护入口，不是 CI 或自动修复机制。

## SkillHub Status Template

`ai-skill-hub` 本身就是一个 multi-agent skill platform 项目，它的主要演进对象不是业务功能，而是 skills、adapter layers、invocation contracts、indexes、tests 和 automation tools。

对这类仓库使用 [skills/update-project-status](skills/update-project-status) 时，建议在 `.codex/skill-config/update-project-status.json` 中设置 `template_type=skillhub`，这样状态输出会优先围绕 skill coverage、invocability、governance 和 automation 来组织。

如果目标仓库只是普通应用项目、数据项目或服务项目，则继续使用默认模板即可，不需要切换 `template_type`。

## 同步到非 Git 项目（Sync To Non-Git Project）

使用 [tools/sync_skills_to_nongit_project.ps1](tools/sync_skills_to_nongit_project.ps1) 可以把当前仓库中的 skills 同步到某个项目的 `.codex/skills` 目录。  
这个脚本默认会以“当前仓库根目录”作为 `skill hub` 源路径（source path），因此通常只需要传入目标项目路径（`ProjectPath`）。

```powershell
pwsh -File .\tools\sync_skills_to_nongit_project.ps1 `
  -ProjectPath D:\dev\some-project
```

```powershell
pwsh -File .\tools\sync_skills_to_nongit_project.ps1 `
  -ProjectPath D:\dev\some-project `
  -SkillName file-structure-check `
  -DryRun
```

```powershell
pwsh -File .\tools\sync_skills_to_nongit_project.ps1 `
  -ProjectPath D:\dev\some-project `
  -Targets codex
```

- 不传 `-SkillName`：同步全部 skills
- 传入 `-SkillName`：只同步单个 skill
- 加上 `-DryRun`：只预览 `robocopy` 结果，不实际写入
- 不传 `-Targets`：默认同步 `codex + agents + github`
- 传入 `-Targets codex`：只下发 `.codex/skills` 与版本文件，不写 adapter layer
- 传入 `-Targets codex,agents,github`：显式指定完整 rollout 目标；adapter 仍指向项目内 `.codex/skills`

## 导出仓库 Bundle（Export Bundle）

使用 [tools/export_bundle.ps1](tools/export_bundle.ps1) 可以把当前仓库导出为 `.bundle` 文件，适合做离线备份（offline backup）或跨机器分发。
