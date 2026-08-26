# Stale Router Reconciliation V1

## 设计定位

本文是 `AI_LEVEL_CONFIG_BACK_REFERENCE_V1` 冻结契约下**唯一**被授权的 machine-level stale router 协调（reconciliation）程序。它只覆盖一个已精确识别的历史状态：未合并候选 `codex/ai-level-universal-routing-v1` 时代（base `9231e5f`，即 `240f74d` locator 中立化之前）由旧版 `configure` 写入当前机器的完整输出集。

它不是通用迁移框架，不是版本注册表，也不是 `--force` 覆盖通道。除此之外的任何 stale / unknown 机器状态都不在本文范围内，继续保持 fail closed。

## 已知 stale 形态（exact known stale shape）

旧版 `configure` 在机器上恰好写入两个文件，内容由生成器决定、不含机器间差异（router 文本不含任何绝对路径）：

| # | 路径 | 字节数 | SHA-256（原始字节，小写 hex） | 角色 |
| --- | --- | --- | --- | --- |
| 1 | `$CODEX_HOME\skills\ai-skill-hub-router\SKILL.md` | 1171 | `80272ffa8e0bf699ffc9ee2fb39bf8246089d530161a21c26827307e939979aa` | stale router adapter（指向旧 Codex-bound locator） |
| 2 | `$CODEX_HOME\ai-skill-hub\locator.json` | 113 | `ac5665bfb5dd3899bf622d56f03c315f218ad34770d552ba5617efec70369c90` | legacy Codex-bound locator（schema 未变，位置已被 neutral locator 取代） |

- 两个文件均为 UTF-8、仅 LF 换行、无 CR。
- 识别标准是**原始字节的 SHA-256 精确相等**加字节数相等；不是文本相似度，不是 frontmatter 匹配。
- 当前冻结契约明确：旧 `$CODEX_HOME\ai-skill-hub\locator.json` 位置不携带任何向后兼容义务；现行 router 与 resolver 均不读取该路径。

## 前提

- 仓库基线为已接受的 frozen 实现（`240f74d` 或其后继），`tools/ai_skill_hub_resolver.py` 为当前冻结版本。
- 直接运行 `configure` 已确认阻断形态为 `Decision=BLOCKED_ROUTER_CONFLICT`、`Mutation=NONE`（exit 2），且 `managed_targets` 报告中 `codex_adapter` 为冲突来源。
- 未设置 `CODEX_HOME` 环境变量时，`$CODEX_HOME` 即当前用户 profile 下的 `.codex`。

## 只读识别（第 1 步，不写任何内容）

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath "$env:USERPROFILE\.codex\skills\ai-skill-hub-router\SKILL.md").Hash.ToLowerInvariant()
(Get-Item -LiteralPath "$env:USERPROFILE\.codex\skills\ai-skill-hub-router\SKILL.md").Length

(Get-FileHash -Algorithm SHA256 -LiteralPath "$env:USERPROFILE\.codex\ai-skill-hub\locator.json").Hash.ToLowerInvariant()
(Get-Item -LiteralPath "$env:USERPROFILE\.codex\ai-skill-hub\locator.json").Length
```

判定：

- router adapter：hash 必须为 `80272ffa8e0bf699ffc9ee2fb39bf8246089d530161a21c26827307e939979aa` 且长度为 `1171`。
- legacy locator：hash 必须为 `ac5665bfb5dd3899bf622d56f03c315f218ad34770d552ba5617efec70369c90` 且长度为 `113`。
- 任何一个不匹配、路径下存在额外对象、或对象是 link / reparse point：**STOP**。不删除、不修改、不继续，把实际状态回报给 Hub 维护侧重新评估。未知内容永远 fail closed。

## 受控协调（第 2 步，唯一被授权的 mutation）

仅当第 1 步全部精确匹配时，维护者删除且只删除这两个已验证文件：

```powershell
Remove-Item -LiteralPath "$env:USERPROFILE\.codex\skills\ai-skill-hub-router\SKILL.md"
Remove-Item -LiteralPath "$env:USERPROFILE\.codex\ai-skill-hub\locator.json"
```

删除后允许移除因此为空的 `$env:USERPROFILE\.codex\ai-skill-hub` 目录；仅当该目录确实只剩这一个文件时才允许移除目录本身。

禁止触碰：

- `$CODEX_HOME\skills\.system\**`（永久排除区）
- Bundle V1 的 `workflow-bootstrap`、`chatgpt-handoff-pilot`、`_protocol` 及其 ownership manifest
- 任何其他已存在的 skill、adapter、配置或目录

## 冻结 configure（第 3 步）

```powershell
<python> .\tools\ai_skill_hub_resolver.py configure --hub-root 'D:\path\to\ai-skill-hub'
```

预期：`Decision=PASS_HUB_LOCATOR_CONFIGURED`、`Mutation=PERFORMED`，建立：

- `~\.ai-skill-hub\locator.json`
- `$CODEX_HOME\skills\ai-skill-hub-router\SKILL.md`（当前冻结 router 文本）
- `~\.claude\skills\ai-skill-hub-router\SKILL.md`
- `~\.agents\skills\ai-skill-hub-router\SKILL.md`

不允许绕过：不得在 configure 之外手工创建或改写这四个 managed 目标。

## 验证（第 4 步，全部只读）

```powershell
<python> .\tools\ai_skill_hub_resolver.py configure --hub-root 'D:\path\to\ai-skill-hub'   # 复跑：NO_CHANGE_HUB_LOCATOR_CURRENT, Mutation=NONE
<python> .\tools\ai_skill_hub_resolver.py resolve project-takeover                        # RESOLVED
<python> .\tools\ai_skill_hub_resolver.py smoke --required-skill workflow-bootstrap --required-skill project-takeover
<python> .\tools\ai_skill_hub_resolver.py doctor --required-skill documentation-governance
```

全部 PASS 且复跑 idempotent，协调完成。

## Fail-closed 边界

- 本程序的唯一 transition 是「已验证 stale 文件 → 删除 → frozen configure 重建」。除此之外没有任何被授权的改写路径。
- `configure` 的 frozen 语义不变：任何未知或冲突内容仍然整体 `Mutation=NONE` 阻断；本文不新增 `--force`、`--adopt`、版本协商或自动升级。
- 将来若出现其他历史形态，必须各自单独识别并单独授权；不得把本文的 hash 集合推广成通用白名单。

## 不做什么

- 不实现 generic migration framework / version registry / rollback subsystem
- 不做 arbitrary legacy adoption，不做 Consumer-specific routing hack
- 不复制 canonical Skill payload，不把 User Bundle 扩成 Hub 镜像
- 不修改 resolver / router 代码与 frozen 契约文本
- 不扫描、不清理 `$CODEX_HOME` 下与本程序无关的任何对象
