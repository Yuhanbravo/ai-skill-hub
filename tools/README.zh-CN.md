# Tools 简短中文说明

这个目录主要放一些本地 PowerShell 工具，用来做 skill hub 的导出、导入和同步。下面按“什么时候用”来快速说明，便于直接调用。

## 当前默认来源

- canonical name：`ai-skill-hub`
- 默认本地仓库路径示例：`D:\dev\ai-skill-hub`
- 项目消费侧仍保留 `.codex/`、`.codex/skills/` 等兼容入口；这里说明的是当前 hub 默认来源，不改项目消费目录结构。

## export_bundle.ps1

用途：

- 把当前 skill hub Git 仓库导出成 `.bundle` 文件。

适合什么时候用：

- 需要离线备份仓库
- 需要把仓库打包后同步到另一台机器

最短调用：

```powershell
.\tools\export_bundle.ps1
```

显式传入提交日志：

```powershell
.\tools\export_bundle.ps1 `
  -CommitMessage 'chore(bundle): export latest ai-skill-hub snapshot'
```

常用参数：

- `-RepoPath`：要导出的仓库路径
- `-OutputDir`：bundle 输出目录
- `-CommitMessage`：工作区不干净时可直接传入提交日志，避免交互输入

注意：

- 工作区不干净时，脚本会要求输入提交日志，随后自动提交并导出。
- 不传 `-RepoPath` 时，默认使用当前脚本所在仓库根目录；当前 canonical 本地路径通常为 `D:\dev\ai-skill-hub`。
- 默认会输出到 `D:\BaiduSyncdisk\Python_Lib\Git_Bundle`。
- 导出的默认 bundle 文件名已切换为 `ai-skill-hub_latest.bundle` 和 `ai-skill-hub_<date>_v1.bundle`。

## import_bundle.ps1

用途：

- 从 `.bundle` 文件恢复或更新本地 skill hub 仓库。

适合什么时候用：

- 新机器初始化 skill hub
- 用 bundle 更新已有本地仓库

最短调用：

```powershell
.\tools\import_bundle.ps1
```

显式指定 canonical 仓库与 bundle：

```powershell
.\tools\import_bundle.ps1 `
  -RepoPath 'D:\dev\ai-skill-hub' `
  -BundlePath 'D:\backup\ai-skill-hub_latest.bundle'
```

常用参数：

- `-RepoPath`：目标仓库路径
- `-BundlePath`：bundle 文件路径

注意：

- 如果目标仓库已存在，必须是干净工作区。
- 不传 `-RepoPath` 时，默认使用当前脚本所在仓库根目录；当前 canonical 本地路径通常为 `D:\dev\ai-skill-hub`。
- 默认从 `D:\BaiduSyncdisk\Python_Lib\Git_Bundle\ai-skill-hub_latest.bundle` 读取 bundle。

## sync_skill_from_project_to_hub.ps1

用途：

- 把真实项目里的单个 skill 同步回当前 hub。

适合什么时候用：

- 你在业务项目里试跑并修改了 skill
- 想把某个 skill 的改动回收进母库

最短调用：

```powershell
.\tools\sync_skill_from_project_to_hub.ps1 `
  -ProjectPath 'D:\my-project' `
  -SkillHubPath 'D:\dev\ai-skill-hub' `
  -SkillName 'chatgpt-handoff-pilot'
```

常用参数：

- `-ProjectPath`：真实项目路径
- `-SkillHubPath`：当前 hub 路径
- `-SkillName`：要同步的 skill 名称
- `-DryRun`：只预览不复制
- `-CreateIfMissing`：hub 中缺失时自动创建

注意：

- 来源固定为项目下的 `.codex\skills\<SkillName>`，该入口继续作为兼容消费入口保留。

## sync_skills_to_nongit_project.ps1

用途：

- 把 hub 中的全部或单个 skill 下发到一个非 Git 项目的 `.codex\skills`。

适合什么时候用：

- 想把最新 skill 集合推送到业务项目
- 目标项目只需要同步文件，不需要完整 Git 仓库

最短调用：

```powershell
.\tools\sync_skills_to_nongit_project.ps1 `
  -SkillHubPath 'D:\dev\ai-skill-hub' `
  -ProjectPath 'D:\my-project'
```

同步单个 skill：

```powershell
.\tools\sync_skills_to_nongit_project.ps1 `
  -SkillHubPath 'D:\dev\ai-skill-hub' `
  -ProjectPath 'D:\my-project' `
  -SkillName 'project-takeover' `
  -DryRun
```

常用参数：

- `-SkillHubPath`：hub 路径
- `-ProjectPath`：目标项目路径
- `-SkillName`：可选，只同步一个 skill
- `-DryRun`：只预览不同步

注意：

- 默认使用镜像同步思路，建议第一次先 `-DryRun`。
- 项目消费侧目录仍固定写入 `.codex\skills`，不因 hub canonical 名称切换而改名。
- 同步后会在目标项目写入一个 `_skillset_version.txt` 元数据文件。
- 全量同步时会同步 canonical skill 目录与 `_protocol/`，不会再把 `skills/` 根下的说明文件和模板文件一起下发。
- **严禁**把 `$HOME`、`$CODEX_HOME` 或 `$CODEX_HOME\skills` 作为该工具的 `-ProjectPath`。它使用项目镜像和 stale-cleanup 语义，不是用户级技能安装器。

## manage_codex_user_skills.ps1

用途：

- 从当前 `ai-skill-hub` 本地 Git checkout，把冻结的 V1 bundle 受控复制到 `$CODEX_HOME\skills`。
- V1 bundle 固定为 `workflow-bootstrap`、`chatgpt-handoff-pilot`，以及两者共同依赖的 `_protocol/skill_assessment_output.md`。

安全默认调用：

```powershell
.\tools\manage_codex_user_skills.ps1
.\tools\manage_codex_user_skills.ps1 -Action Check
.\tools\manage_codex_user_skills.ps1 -Action Plan
```

显式写操作：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Apply
.\tools\manage_codex_user_skills.ps1 -Action Uninstall
```

结构化输出：

```powershell
.\tools\manage_codex_user_skills.ps1 -Action Check -OutputFormat Json
```

冻结参数：

- `-Action`：`Check`、`Plan`、`Apply`、`Uninstall`；默认 `Check`
- `-RepositoryRoot`：可选的本地 hub checkout，主要用于移动后的 checkout 或隔离测试
- `-OutputFormat`：`Text` 或 `Json`

安全边界：

- `Check` 和 `Plan` 零写入；`Apply`/`Uninstall` 必须显式指定。
- 只管理 source descriptor 声明的完整 V1 bundle，不支持 `-Skill`、`-Force`、`-Adopt`、`-Mirror` 或部分卸载。
- ownership manifest 位于 `$CODEX_HOME\skills\.ai-skill-hub-user-skills.json`；未知对象、local modification、无效 manifest、链接/reparse point 和 stale transaction 都会 fail closed。
- staging、backup、transaction journal 和 lock 都位于同一个 `$CODEX_HOME\skills` 根下；manifest 最后写入，失败时按 journal 回滚。
- `.system` 永久排除；工具不会清理整个用户技能目录，也不会删除无关用户技能。
- 本轮仓库验证只允许使用临时 `CODEX_HOME`。真实用户安装需要独立授权；文件复制成功也不代表 Codex App/CLI 已完成技能发现验证。

完整 Windows 流程见：

- `docs/human/CODEX_USER_SKILLS_BOOTSTRAP_WINDOWS.md`

## ai_skill_hub_resolver.py

用途：

- 为首选的 `AI_LEVEL_CONFIG_BACK_REFERENCE_V1` adoption mode 提供 agent-neutral 的 machine-level Hub locator、logical Skill ID 的 canonical resolver、Required-Skills smoke 和只读 doctor。resolution core 与任何具体 Agent 无关。
- Consumer Project 只声明逻辑 Skill ID；它不保存 Hub 绝对路径、不携带 Hub submodule，也不复制 canonical Skill payload。
- V1 冻结的 supported consumers：`CODEX`、`CLAUDE_CODE`、`GITHUB_COPILOT`、`KIMI_CODE`。

一次性配置当前机器（显式写入当前用户配置，不访问远端）：

```powershell
repo-python .\tools\ai_skill_hub_resolver.py configure `
  --hub-root 'D:\path\to\ai-skill-hub'
```

该命令只创建或校验以下 machine/user-level routing state：

- `~\.ai-skill-hub\locator.json`：唯一允许保存本机 Hub checkout path 的 agent-neutral locator；
- `$CODEX_HOME\skills\ai-skill-hub-router\SKILL.md`：Codex 薄 router entry；
- `~\.claude\skills\ai-skill-hub-router\SKILL.md`：Claude Code 薄 router entry；
- `~\.agents\skills\ai-skill-hub-router\SKILL.md`：通用 Agent Skills 薄 router entry（V1 用于 GitHub Copilot 与 Kimi Code）。

三个 router byte-identical、共用同一 neutral locator，不含 canonical payload，也不内嵌 Hub 绝对路径（三类宿主消费同一 `SKILL.md` 契约，只有发现根目录不同，因此 V1 不需要 per-agent variant）。`configure` 先对 locator 与全部 adapter 目标做只读 preflight，任何未知/冲突内容即整体 `Mutation=NONE`；每个单文件写仍为 temp file + atomic replace。测试或隔离环境可覆盖默认路径：`--config-home`（或 `AI_SKILL_HUB_CONFIG_HOME`）覆盖用户 home，`--codex-home` / `--claude-home` / `--agents-home`（或 `AI_SKILL_HUB_AGENTS_HOME`）覆盖各 adapter 根目录。

它不修改 Consumer Project，也不修改 `manage_codex_user_skills.ps1` 管理的 Bundle V1 ownership manifest。Bundle V1 的两个 bootstrap/protocol Skill 和 `_protocol` 仍保持原有生命周期；router 仅是独立的 AI-level thin adapter。

若机器上残留 locator 中立化之前的旧版 router adapter 导致 `configure` 以 `BLOCKED_ROUTER_CONFLICT` 阻断，唯一被授权的协调程序见 `docs/governance/stale_router_reconciliation_v1.md`（hash 精确识别 + 维护者删除已验证文件 + 冻结 `configure` 重建）；没有 `--force` 或其他改写通道。

只读解析、smoke 和 doctor：

```powershell
repo-python .\tools\ai_skill_hub_resolver.py resolve project-takeover
repo-python .\tools\ai_skill_hub_resolver.py smoke `
  --required-skill workflow-bootstrap `
  --required-skill project-takeover
repo-python .\tools\ai_skill_hub_resolver.py doctor `
  --required-skill documentation-governance
```

resolver 的 canonical identity rule 是：Hub Git checkout 的 `skills/<skill-id>/SKILL.md` 必须存在，`skill-id` 必须是合法逻辑 ID，且 frontmatter `name` 必须与目录名完全一致；任何其他目录声称同一 `name` 也会以 ambiguity 失败。`_protocol` 是 Bundle 所需的 dependency container，不是可解析的 canonical Skill ID。`SKILLS_INDEX.md` 与 `skills_index.json` 可用于人类/metadata discovery，但不是该 fail-closed resolver 的 identity authority。

`smoke` 的每项结果只能是 `RESOLVED`、`MISSING`、`INVALID` 或 `HUB_UNAVAILABLE`，整体为 `PASS` 或 `BLOCKED`。`doctor` 在 routing 完整时返回 `ADOPT_AS_IS`，否则返回 `BLOCKED`；它不扫描或迁移 Consumer Project，因此不会凭空输出 `MIGRATION_REQUIRED`。未声明任何 required Skill 时两者都以 `INSUFFICIENT_REQUIREMENTS` fail closed；只有显式传 `--allow-empty-requirements` 表示 "zero skills is intentional" 才放行，且输出带 `zero_requirements_intentional` 标记，automation 不得把空需求集当作 migration safe。

若 resolver 输出 `HUB_GIT_SAFE_DIRECTORY_UNTRUSTED`，表示 Locator 与 Hub 目录结构已经通过检查，但运行该命令的 Windows identity 尚未将 Locator 指向的 checkout 标记为 Git `safe.directory`。这不是 Consumer Project 的内容或 canonical Skill identity 错误。维护者应在确认该精确 checkout 可信后，在该执行环境的 Git trust 配置中加入该路径（例如 `git config --global --add safe.directory D:/path/to/ai-skill-hub`），然后重跑原命令；不要使用 `safe.directory=*` 或将机器绝对路径写回 Consumer Project。resolver 保持只读，不会自动修改 Git 配置。

## generate_skill_metadata.py

用途：

- 从 canonical `skills/` 生成 `skills_index.json`，并刷新 `.agents/skills/*.md` flat summaries。

适合什么时候用：

- 你修改了某个 `SKILL.md` 的 metadata 或 Invocation
- 想重新生成机器可读索引和 flat discovery 文件

最短调用：

```powershell
repo-python .\tools\generate_skill_metadata.py
```

注意：

- 脚本始终以当前仓库根目录作为 `ROOT`，生成仓库根下的 `skills_index.json` 与 `.agents/skills/*.md`，不会改动生成物结构。

## skill_router.py

用途：

- 根据 `task_description` 自动匹配最合适的 skill，并给出置信度和原因。

最短调用：

```powershell
repo-python .\tools\skill_router.py "整理技能索引并检查文档治理"
```

## skill_pipeline.py

用途：

- 将复合任务拆成子任务，并顺序匹配多个 skill。

最短调用：

```powershell
repo-python .\tools\skill_pipeline.py "接管仓库并更新状态"
```

## run_local_checks.ps1

用途：

- 用一个统一入口运行本地仓库验证，不再靠记忆分散的测试命令。
- 这是当前仓库默认的本地验证入口，建议在日常维护前后和提交前优先使用。

最短调用：

```powershell
.\tools\run_local_checks.ps1
```

常用调用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks router
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks governance
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks smoke
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\run_local_checks.ps1 -Checks all
```

说明：

- 支持的检查分组是 `router`、`governance`、`smoke`、`all`
- 所有 Python workload 都通过 `repo-python` 交给 AI_Workbench runtime broker
- 仓库不通过 `PATH`、`py` launcher、Conda 环境名或绝对解释器路径选择 Python
- broker 无法解析或调用时 fail closed，不尝试其他解释器
- `-CondaEnvName` 与 `-UsePyLauncher` 仅暂时保留为显式 unsupported 错误，退出码为 `2`
- 输出会显式区分 environment / permission / logic 三类失败
- 这是本地维护入口，不是 CI、controller 或自动修复器

## init_project_runtime_pack.ps1

用途：

- 在一个 clean Git 项目根目录接入 ai-skill-hub runtime pack：默认以 exact-commit Git submodule 挂载 `.ai/ai-skill-hub`，并生成三个 managed-block 入口（`AGENTS.md`、`CLAUDE.md`、`.github/copilot-instructions.md`）、两个项目级 router Skill（`.agents/`、`.claude/` 下各一个 `ai-skill-hub-router/SKILL.md`）和审计 manifest `.ai/runtime-pack.json`。

最短调用：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\init_project_runtime_pack.ps1 `
  -ProjectPath 'D:\my-project'
```

常用参数：

- `-ProjectPath`：目标项目根（必须等于 `git rev-parse --show-toplevel`）
- `-HubMode`：`Submodule`（默认）或 `ExternalPath`（显式本机 opt-in，需传绝对 `-HubPath`，禁止 `-HubUrl`）
- `-HubUrl`：hub 远端 URL；Submodule 模式缺省读取本仓库 `origin`
- `-HubRef`：branch/tag/40 位 commit，默认 `main`
- `-DryRun`：只输出计划，零 repo mutation

安全边界：

- 需要 PowerShell 7.4+ 与 Git 2.40+；仅 Windows；不支持非 Git 项目。
- 首次执行要求工作区完全 clean；失败时按 journal 回滚到 exact pre-state（exit 3），回滚无法验证时保留 evidence（exit 4）。
- 无 `-Force`、无交互 merge、不创建 symlink/junction、不改全局 Git 配置、不写用户 home 或 `$CODEX_HOME`。
- 不自动 commit/push/upgrade；版本变化只返回 `BLOCKED_UPGRADE_REQUIRED`。
- 冻结设计契约见 `docs/design/project_runtime_pack_mvp_v1_design_contract.md`。

## audit_derivative_surfaces.py

用途：

- 以只读方式审计两类 derivative-surface 风险：
  - `docs/HANDOFF.md` 与 `docs/bridge/HANDOFF.md`
  - `docs/status/skill-hub-status.md` 与 `docs/bridge/status/skill-hub-status.md`
- 检查 canonical invocation examples 是否已经转移到 `skills/*/examples/invocation_examples.md`
- 报告 `tools/generate_skill_metadata.py` 是否仍依赖旧的 inline `SKILL.md` / `### Input Example` 假设

最短调用：

```powershell
repo-python .\tools\audit_derivative_surfaces.py
```

常用调用：

```powershell
repo-python .\tools\audit_derivative_surfaces.py --root .
repo-python .\tools\audit_derivative_surfaces.py --preview-lines 20
```

说明：

- 这是 read-only / non-gating audit，只做 compare / report，不做 refresh、sync 或 rewrite
- bridge semantic mirror comparison 会先剥离 bridge copy 允许存在的 preamble/header
- `docs/bridge/SKILLS_INDEX.md` 与 bridge template copies 会按 intentional bridge copy 处理并显式 `SKIP`
- 即使发现 drift，脚本也保持 report-only，不把当前仓库默认验证入口变成阻断流程

## 使用建议

- 想“备份或打包整个 hub”，用 `export_bundle.ps1`。
- 想“从 bundle 恢复或更新 hub”，用 `import_bundle.ps1`。
- 想“把项目里改好的单个 skill 回收到 hub”，用 `sync_skill_from_project_to_hub.ps1`。
- 想“把 hub 的 skill 下发到业务项目”，用 `sync_skills_to_nongit_project.ps1`。
- 想“检查或受控管理 Codex 用户级冻结 V1 bundle”，用 `manage_codex_user_skills.ps1`；不要改用项目同步工具。
- 想“显式暴露 bridge mirror drift 和 invocation-example source drift，但不做修复”，用 `audit_derivative_surfaces.py`。
- 想“快速跑本地验证并看清是环境问题还是仓库问题”，用 `run_local_checks.ps1`。
